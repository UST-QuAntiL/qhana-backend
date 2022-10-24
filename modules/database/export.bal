// Copyright 2022 University of Stuttgart
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ballerina/sql;
import ballerina/task;
import ballerina/log;
import ballerina/time;
import ballerina/file;
import ballerina/regex;
import ballerina/io;
import ballerina/os;
import ballerina/mime;

////////////////////////////////////////////////////////////////////////////////
// Types ///////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Record for exporting/importing experiment data
#
# + dataId - The database id of the data item (used for reference, changer on import)
public type ExperimentDataExport record {|
    int dataId;
    *ExperimentData;
|};

# Record for exporting/importing step data
#
# + dataId - The database id of the data item (used for reference, changer on import)
# + relationType - the type of the relation (e.g. input/output)
public type StepDataExport record {|
    int dataId;
    string relationType;
|};

# Record for exporting/importing substep data
#
# + substepNr - 1 based substep index   
# + dataId - The database id of the data item (used for reference, changer on import)n  
# + relationType - the type of the relation (e.g. input/output) 
public type SubstepDataExport record {|
    string substepNr; // TODO not really necessary - maybe remove later when import is done 
    int dataId;
    string relationType;
|};

# Base record for exporting/importing timeline substeps
#
# + substepNr - 1 based substep index  
# + parameters - the parameters which were input for this substep
# + parametersContentType - the content type of these parameters
public type TimelineSubstepExportBase record {|
    int substepNr;
    *TimelineSubstep;
    string? parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
|};

# Record for exporting/importing timeline substeps
#
# + substepDataList - list of substep data
public type TimelineSubstepExport record {|
    *TimelineSubstepExportBase;
    SubstepDataExport[] substepDataList;
|};

# Base record of a timeline step for export.
#
# + 'start - the time when the timeline step was created
# + end - the time when a result or error was recorded for the timeline step
# + status - the current status of the timeline step result
# + resultQuality - the result quality
# + resultLog - the log output that is part of the result
# + processorName - the plugin handling the computation for this step
# + processorVersion - the version of the plugin
# + processorLocation - the root URL of the plugin
# + parameters - the parameters used to invoke the plugin with
# + parametersContentType - the content type of the serialized parameters
# + notes - the text of the notes stored for this step
public type TimelineStepBaseExport record {|
    string 'start;
    string? end = ();
    string status = "PENDING";
    string resultQuality = "UNKNOWN";
    string? resultLog = ();
    string processorName;
    string? processorVersion = ();
    string? processorLocation = ();
    string? parameters; // optional for small requests
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    string? notes; // optional for small requests
    *Progress;
|};

# Record for exporting/importing timeline steps with step data and substeps
#
# + sequence - the sequence number of the step in the experiment
# + stepDataList - list of step data  
# + timelineSubsteps - list of associated timeline substeps 
public type TimelineStepExport record {|
    int sequence; // TODO: not sure what this is used for
    *TimelineStepBaseExport; // TODO: not sure if this will work due to time:Utc for start and end
    StepDataExport[] stepDataList;
    TimelineSubstepExport[] timelineSubsteps;
|};

# Record for exporting/importing a complete experiment
#
# + experiment - info about experiment
# + timelineSteps - timeline steps including substeps and step/substep data
# + experimentDataList - list of experiment data (reference to files in zip)
public type ExperimentCompleteExport record {|
    Experiment experiment;
    TimelineStepExport[] timelineSteps;
    ExperimentDataExport[] experimentDataList;
|};

////////////////////////////////////////////////////////////////////////////////
// Helper functions  ///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public isolated transactional function castToTimelineStepExport(TimelineStepFull step) returns TimelineStepExport|error {
    var end = step.end;
    return {
        sequence: step.sequence,
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        resultQuality: step.resultQuality,
        resultLog: step.resultLog,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parameters: step?.parameters, // TODO: on import don't set when nill
        parametersContentType: step.parametersContentType,
        notes: step?.notes, // TODO: on import don't set when nill
        progressStart: step.progressStart,
        progressTarget: step.progressTarget,
        progressValue: step.progressValue,
        progressUnit: step.progressUnit,
        stepDataList: [],
        timelineSubsteps: []
    };
}

# Get the list of (complete) timeline steps from the database for export.
#
# + experimentId - The experiment id
# + return - The list of timpline steps or the encountered error
public isolated transactional function getTimelineStepListExport(int experimentId) returns TimelineStepFull[]|error {
    sql:ParameterizedQuery startEndString = ` cast(start as TEXT) AS start, cast(end as TEXT) AS end, `;
    if configuredDBType != "sqlite" {
        startEndString = `DATE_FORMAT(start, '%Y-%m-%dT%H:%i:%S') AS start, DATE_FORMAT(end, '%Y-%m-%dT%H:%i:%S') AS end,  `;
    }
    stream<TimelineStepSQL, sql:Error?> timelineSteps;
    timelineSteps = experimentDB->query(sql:queryConcat(
        `SELECT stepId, experimentId, sequence, `, startEndString, ` status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart AS progressStart, pTarget AS progressTarget, pValue AS progressValue, pUnit AS progressUnit
                     FROM TimelineStep WHERE experimentId=${experimentId};`
    ));

    (TimelineStepSQL|TimelineStepFull)[]|error|() tempList = from var step in timelineSteps
        select step;

    check timelineSteps.close();

    TimelineStepFull[] stepList = [];
    if tempList is error {
        return tempList;
    } else if tempList is () {
        return [];
    } else {
        // convert timestamps to correct utc type if timestamps come from sqlite
        foreach var step in tempList {
            TimelineStepFull stepFull = check castToTimelineStepFull(step);
            stepList.push(stepFull);
        }
    }
    return stepList;
}

public isolated transactional function getTimelineStepDataList(int stepId) returns StepDataExport[]|error {
    stream<StepDataExport, sql:Error?> stepDataResult = experimentDB->query(`SELECT dataId, relationType FROM StepData WHERE stepId = ${stepId};`);
    StepDataExport[]|error|() stepDataList = from var stepData in stepDataResult
        select stepData;
    if stepDataList is error {
        return error(string `[stepId ${stepId}] Could not retrieve step data for export.`);
    } else if stepDataList is () {
        return [];
    } else {
        return stepDataList;
    }
}

public isolated transactional function getTimelineSubstepDataList(int stepId, int substepNr) returns SubstepDataExport[]|error {
    stream<SubstepDataExport, sql:Error?> substepDataResult = experimentDB->query(`SELECT substepNr, dataId, relationType FROM SubstepData WHERE stepId = ${stepId} AND substepNr = ${substepNr};`);
    SubstepDataExport[]|error|() substepDataList = from var substepData in substepDataResult
        select substepData;
    if substepDataList is error {
        return error(string `[stepId ${stepId}, substepNr ${substepNr}] Could not retrieve substep data for export.`);
    } else if substepDataList is () {
        return [];
    } else {
        return substepDataList;
    }
}

public isolated transactional function getTimelineSubstepsBaseExport(int stepId) returns TimelineSubstepExportBase[]|error {
    stream<TimelineSubstepExportBase, sql:Error?> substepsResult = experimentDB->query(
        `SELECT substepNr, substepId, href, hrefUi, cleared, parameters, parametersContentType FROM TimelineSubstep WHERE stepId=${stepId} ORDER BY substepNr ASC;`
    );
    TimelineSubstepExportBase[]|error|() substepsBase = from var substep in substepsResult
        select substep;
    if substepsBase is error {
        return substepsBase;
    } else if substepsBase is () {
        return [];
    } else {
        return substepsBase;
    }
}

public isolated transactional function getTimelineSubstepsExport(int stepId) returns TimelineSubstepExport[]|error {
    TimelineSubstepExport[] substepsExport = [];
    TimelineSubstepExportBase[] substepsBase = check getTimelineSubstepsBaseExport(stepId);
    foreach var substep in substepsBase {
        SubstepDataExport[] substepDataList = check getTimelineSubstepDataList(stepId, substep.substepNr);
        TimelineSubstepExport substepExport = {
            substepNr: substep.substepNr,
            substepId: substep.substepId,
            href: substep.href,
            hrefUi: substep.hrefUi,
            cleared: substep.cleared,
            parameters: substep.parameters,
            parametersContentType: substep.parametersContentType,
            substepDataList: substepDataList
        };
        substepsExport.push(substepExport);
    }
    return substepsExport;
}

public isolated transactional function getExperimentDataExport(int experimentId, int dataId) returns ExperimentDataExport|error {
    stream<ExperimentDataExport, sql:Error?> experimentDataResult = experimentDB->query(
        `SELECT dataId, name, version, location, type, contentType FROM ExperimentData WHERE dataId=${dataId} AND experimentId=${experimentId};`
    );
    var experimentData = experimentDataResult.next();
    check experimentDataResult.close();
    if experimentData is error {
        return experimentData;
    }
    if experimentData is record {ExperimentDataExport value;} {
        return experimentData.value;
    } else {
        // should never happen based on the sql query
        return error(string `[experimentId ${experimentId}, dataId ${dataId}] Could not retrieve experiment data for export from database.`);
    }
}

public isolated transactional function getExperimentDBExport(int experimentId) returns ExperimentCompleteExport|error {
    TimelineStepExport[] timelineSteps = [];
    ExperimentDataExport[] experimentDataList = [];
    ExperimentFull experiment = check getExperiment(experimentId);
    int[] dataIdList = [];

    // iterate over timeline steps
    TimelineStepFull[] timelineStepListDb = check getTimelineStepListExport(experimentId);
    foreach TimelineStepFull timelineStepDb in timelineStepListDb {
        TimelineStepExport timelineStepExport = check castToTimelineStepExport(timelineStepDb);
        // retrieve associated step data
        timelineStepExport.stepDataList = check getTimelineStepDataList(timelineStepDb.stepId);
        foreach var stepData in timelineStepExport.stepDataList {
            dataIdList.push(stepData.dataId);
        }
        // retrieve associated substeps with their substep data
        timelineStepExport.timelineSubsteps = check getTimelineSubstepsExport(timelineStepDb.stepId);
        timelineSteps.push(timelineStepExport);
        foreach var substep in timelineStepExport.timelineSubsteps {
            foreach var substepData in substep.substepDataList {
                dataIdList.push(substepData.dataId);
            }
        }
    }

    // ignore duplicates in dataIdList and create experiment data list
    int[] sortedDataIdList = dataIdList.sort();
    int tmp = -1;
    foreach int dataId in sortedDataIdList {
        if dataId != tmp {
            tmp = dataId;
            ExperimentDataExport experimentData = check getExperimentDataExport(experimentId, dataId);
            experimentDataList.push(experimentData);
        }
    }

    return {
        experiment: {name: experiment.name, description: experiment.description},
        timelineSteps: timelineSteps,
        experimentDataList: experimentDataList
    };
}

////////////////////////////////////////////////////////////////////////////////
// Export main functionality ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Prepare zip file for export of an experiment.
#
# + experimentId - experiment id of the new (cloned) experiment
# + config - export configuration // TODO
# + os - os type to determine appropriate exec command
# + return - record with details about created zip files or error
public isolated transactional function exportExperiment(int experimentId, string? config, string os) returns ExperimentExportZip|error {

    // TODO: config

    ExperimentCompleteExport experimentComplete = check getExperimentDBExport(experimentId);
    // data files
    string[] dataFileLocations = [];
    ExperimentDataExport[] experimentDataList = experimentComplete.experimentDataList;
    foreach var experimentData in experimentDataList {
        string location = experimentData.location;

        // remove path from file location
        int? index = location.lastIndexOf("/");
        if index is () {
            index = location.lastIndexOf("\\");
        }
        if index is () {
            return error("Unable to determine relative file location.");
        } else {
            experimentData.location = location.substring(index + 1, location.length()); // only file name
            dataFileLocations.push(check file:joinPath(
                "experimentData",
                experimentId.toString(),
                experimentData.location
            ));
        }
    }

    // string tmpDir = check file:createTempDir();
    var exists = file:test("tmp", file:EXISTS);
    if exists !is error && !exists {
        check file:createDir("tmp");
    }
    json experimentCompleteJson = experimentComplete;
    string jsonFile = "experiment.json";
    var jsonPath = check file:joinPath("tmp", jsonFile);
    exists = file:test(jsonPath, file:EXISTS);
    if exists !is error && exists {
        check file:remove(jsonPath);
    }
    log:printDebug("Write " + jsonPath + " ...");
    check io:fileWriteJson(jsonPath, experimentCompleteJson);

    // create zip-  add all files (experiment file(s) + data files) to ZIP
    string zipFileName = regex:replaceAll(experimentComplete.experiment.name, "\\s+", "-") + ".zip";
    var zipPath = check file:joinPath("tmp", zipFileName);
    log:printDebug("Create zip " + zipPath + " ...");

    // add experiment.json
    os:Process result;
    if os == "linux" {
        result = check os:exec({value: "zip", arguments: ["-j", zipPath, jsonPath]});
    } else if os == "windows" {
        result = check os:exec({value: "powershell", arguments: ["Compress-Archive", "-Update", jsonPath, zipPath]});
    } else {
        return error("Unsupported operating system! At the moment, we support 'linux' and 'windows' for importing/exporting experiments. Please make sure to properly specify the os env var or config entry.");
    }
    _ = check result.waitForExit();

    // add experiment data files
    foreach string dataFile in dataFileLocations {
        log:printDebug("Add file to zip... " + dataFile);
        if os == "linux" {
            result = check os:exec({value: "zip", arguments: ["-j", zipPath, dataFile]});
        } else if os == "windows" {
            result = check os:exec({value: "powershell", arguments: ["Compress-Archive", "-Update", dataFile, zipPath]});
        } else {
            return error("Unsupported operating system! At the moment, we support 'linux' and 'windows' for importing/exporting experiments. Please make sure to properly specify the os env var or config entry.");
        }
        _ = check result.waitForExit();
    }

    ExperimentExportZip exportResult = {name: zipFileName, location: zipPath};
    return exportResult;
}

# Create and start a long running background task for experiment export and a corresponding db entry.
#
# + experimentId - experiment id
# + config - export configuration // TODO
# + os - os type to determine appropriate exec command
# + return - id of export job db entry
public isolated transactional function createExportJob(int experimentId, string? config, string os) returns int|error {
    // create experiment export db entry
    sql:ParameterizedQuery currentTime = ` strftime('%Y-%m-%dT%H:%M:%S', 'now') `;
    if configuredDBType != "sqlite" {
        currentTime = ` DATE_FORMAT(UTC_TIMESTAMP(), '%Y-%m-%dT%H:%i:%S') `;
    }
    var insertResult = check experimentDB->execute(sql:queryConcat(`INSERT INTO ExperimentExport (experimentId, name, location, creationTime) VALUES (${experimentId}, "", "", `, currentTime, `)`));

    var exportId = insertResult.lastInsertId;
    if exportId == () || exportId is string {
        fail error("Expected the expert Id back!");
    }
    int intExportId = check exportId.ensureType();
    // TODO: maybe generate a secure importId instead of using autoincremented ints

    // start long-running export task 
    _ = check task:scheduleOneTimeJob(new exportJob(intExportId, experimentId, config, os), time:utcToCivil(time:utcNow()));

    return intExportId;
}

# Retrieve result for export job.
#
# + experimentId - experiment id 
# + exportId - id of export db entry
# + return - id of export job db entry
public isolated transactional function getExportResult(int experimentId, int exportId) returns ExperimentExportResult|error {
    stream<ExperimentExportResult, sql:Error?> result = experimentDB->query(`SELECT status, name, location FROM ExperimentExport WHERE experimentId=${experimentId} AND exportId=${exportId};`);

    var experimentExport = result.next();
    check result.close();

    if !(experimentExport is sql:Error) && (experimentExport != ()) {
        return experimentExport.value;
    }

    return error(string `Experiment export entry with id ${exportId} was not found!`);
}

////////////////////////////////////////////////////////////////////////////////
// Export task /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# A background job that prepares an experiment for export. Corresponding db entry is updated on success or failure.
public class exportJob {

    *task:Job;
    int exportId;
    int experimentId;
    string? exportConfig;
    string configuredOS;

    public isolated function execute() {
        transaction {
            ExperimentExportZip experimentZip;
            experimentZip = check exportExperiment(self.experimentId, self.exportConfig, self.configuredOS);

            _ = check experimentDB->execute(
                `UPDATE ExperimentExport 
                    SET status="SUCCESS", name=${experimentZip.name}, location=${experimentZip.location}
                WHERE experimentId = ${self.experimentId} AND exportId = ${self.exportId};`
            );

            check commit;
        } on fail error err {
            var res = experimentDB->execute(
                `UPDATE ExperimentExport 
                    SET status="FAILURE"
                WHERE experimentId = ${self.experimentId} AND exportId = ${self.exportId};`
            );
            if res is error {
                log:printError("Exporting experiment unsuccessful. Updating ExperimentExport unsuccessful! Failure will not be seen from the outside.", 'error = err, stackTrace = err.stackTrace());
            }
            log:printError("Exporting experiment unsuccessful.", 'error = err, stackTrace = err.stackTrace());
        }
    }

    isolated function init(int exportId, int experimentId, string? exportConfig, string configuredOS) {
        self.exportId = exportId;
        self.experimentId = experimentId;
        self.exportConfig = exportConfig;
        self.configuredOS = configuredOS;
    }
}

