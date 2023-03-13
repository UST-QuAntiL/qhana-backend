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

# Record for configuring experiment export 
#
# + restriction - config type, can have values "ALL" for all data (default), "LOGS" for only steps/substeps with params, "DATA" for only data files, "STEPS" for specific steps with associated data files
# + allDataVersions - all versions if value >= 0, else only newest version (only for restriction "DATA")
# + stepList - list of step sequence numbers, only needed for restriction "STEPS"
public type ExperimentExportConfig record {|
    string restriction = "ALL";
    int allDataVersions = 1;
    int[] stepList = [];
|};

# Record for exporting/importing experiment data
#
# + dataId - The database id of the data item (used for reference, changer on import)
public type ExperimentDataExport record {|
    int dataId;
    *ExperimentData;
|};

# Experiment export record for exporting experiments as a zip.
#
# + name - the (file-)name of the experiment zip
# + location - the path where the data is stored
public type ExperimentExportZip record {|
    string name;
    string location;
|};

# Experiment export result record for exporting experiments as a zip.
#
# + status - status of export
# + name - the (file-)name of the experiment zip
# + location - the path where the data is stored
public type ExperimentExportResult record {|
    string status;
    string name;
    string location;
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
    string substepNr;
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
# + parameters - the parameters which were input for this substep
# + parametersContentType - the content type of these parameters
# + substepDataList - list of substep data
public type TimelineSubstepExport record {|
    *TimelineSubstep;
    string? parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
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
# + stepDataList - list of step data  
# + timelineSubsteps - list of associated timeline substeps 
public type TimelineStepExport record {|
    *TimelineStepBaseExport;
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

# Api response for an experiment export.
#
# + exportId - The database id of the export entry
# + experimentId - The experiment id
# + status - The export status
# + name - The file name
public type ExportStatus record {|
    int exportId;
    int experimentId;
    string status;
    string name;
|};

////////////////////////////////////////////////////////////////////////////////
// Helper functions  ///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public isolated transactional function castToTimelineStepExport(TimelineStepFull step) returns TimelineStepExport|error {
    var end = step.end;
    return {
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        resultQuality: step.resultQuality,
        resultLog: step.resultLog,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parameters: step?.parameters,
        parametersContentType: step.parametersContentType,
        notes: step?.notes,
        progressStart: step.progressStart,
        progressTarget: step.progressTarget,
        progressValue: step.progressValue,
        progressUnit: step.progressUnit,
        stepDataList: [],
        timelineSubsteps: []
    };
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

public isolated transactional function getTimelineSubstepsExport(int stepId, ExperimentExportConfig config) returns TimelineSubstepExport[]|error {
    TimelineSubstepExport[] substepsExport = [];
    TimelineSubstepExportBase[] substepsBase = check getTimelineSubstepsBaseExport(stepId);
    foreach var substep in substepsBase {
        SubstepDataExport[] substepDataList = [];
        if config.restriction != "LOGS" {
            substepDataList = check getTimelineSubstepDataList(stepId, substep.substepNr);
        } // else don't need data
        TimelineSubstepExport substepExport = {
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

public isolated transactional function getTimelineStepLimit(int experimentId) returns int|error {
    // check if < 10000 steps
    int count = check experimentDB->queryRow(sql:queryConcat(
        `SELECT count(*) FROM TimelineStep `,
        timelineStepListFilter(experimentId, (), (), (), ()), `;`
    ));
    if count > 10000 {
        log:printError(string `Exceeded limit for TimelineSteps. Limit is set to 10000. Found ${count} steps. Only return 10000 steps.`);
        count = 10000;
    }
    return count;

}

# Removes duplicates and creates experiment data list for list of data ids. 
#
# + dataIdList - List of data ids 
# + experimentId - Experiment id
# + return - Return list of experiment data export 
public isolated transactional function mapToExportDataList(int[] dataIdList, int experimentId) returns ExperimentDataExport[]|error {
    ExperimentDataExport[] experimentDataList = [];
    if dataIdList.length() > 0 {
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
    }
    return experimentDataList;
}

public isolated transactional function getExportDataList(int experimentId, ExperimentExportConfig config, int[] dataIdList) returns ExperimentDataExport[]|error {
    ExperimentDataExport[] experimentDataList;
    if config.restriction == "DATA" {
        // only need data files
        boolean allVersions = config.allDataVersions < 0 ? false : true;
        ExperimentDataFull[] dataList = check getDataList(experimentId, (), all = allVersions);
        experimentDataList = from var {dataId, name, 'version, location, 'type, contentType} in dataList
            select {dataId, name, 'version, location, 'type, contentType};
    } else {
        experimentDataList = check mapToExportDataList(dataIdList, experimentId);
        if dataIdList.length() > 0 {
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
        } // else don't need data
    }
    return experimentDataList;
}

public isolated transactional function getExperimentDBExport(ExperimentFull experiment, ExperimentExportConfig config) returns ExperimentCompleteExport|error {
    TimelineStepExport[] timelineSteps = [];
    ExperimentDataExport[] experimentDataList = [];
    int[] dataIdList = [];

    if config.restriction != "DATA" {
        // iterate over timeline steps
        TimelineStepFull[] timelineStepListDb = check getTimelineStepList(experiment.experimentId, (), (), (), (), allAttributes = true, 'limit = check getTimelineStepLimit(experiment.experimentId));

        int[] stepList = [];
        if config.restriction == "STEPS" {
            stepList = config.stepList.sort();
        }
        int counter = 0;
        foreach TimelineStepFull timelineStepDb in timelineStepListDb {
            if config.restriction == "STEPS" {
                // filter steps with stepList 
                if timelineStepDb.sequence == stepList[counter] {
                    counter += 1;
                } else {
                    continue;
                }
            }

            TimelineStepExport timelineStepExport = check castToTimelineStepExport(timelineStepDb);
            if config.restriction == "LOGS" {
                // don't need data for restriction "LOGS"
                timelineStepExport.stepDataList = [];
            } else {
                // retrieve associated step data
                timelineStepExport.stepDataList = check getTimelineStepDataList(timelineStepDb.stepId);
                foreach var stepData in timelineStepExport.stepDataList {
                    dataIdList.push(stepData.dataId);
                }
            }
            // retrieve associated substeps with their substep data
            timelineStepExport.timelineSubsteps = check getTimelineSubstepsExport(timelineStepDb.stepId, config);
            timelineSteps.push(timelineStepExport);
            if config.restriction != "LOGS" {
                // retrieve associated substep data
                foreach var substep in timelineStepExport.timelineSubsteps {
                    foreach var substepData in substep.substepDataList {
                        dataIdList.push(substepData.dataId);
                    }
                }
            } // else don't need data
        }
    }

    experimentDataList = check getExportDataList(experiment.experimentId, config, dataIdList);

    return {
        experiment: {name: experiment.name, description: experiment.description, templateId: experiment?.templateId},
        timelineSteps: timelineSteps,
        experimentDataList: experimentDataList
    };
}

////////////////////////////////////////////////////////////////////////////////
// Export main functionality ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Prepare zip file for export of an experiment.
#
# + experiment - experiment
# + exportId - export id
# + config - export configuration
# + os - os type to determine appropriate exec command
# + storageLocation - storage location
# + return - record with details about created zip files or error
public isolated transactional function exportExperiment(ExperimentFull experiment, int exportId, ExperimentExportConfig config, string os, string storageLocation) returns ExperimentExportZip|error {

    ExperimentCompleteExport experimentComplete = check getExperimentDBExport(experiment, config);
    // data files
    string[] dataFileLocations = [];
    ExperimentDataExport[] experimentDataList = experimentComplete.experimentDataList;
    foreach var experimentData in experimentDataList {
        string location = experimentData.location;
        experimentData.location = check extractFilename(location); // only file name
        var path = check file:joinPath(storageLocation, experiment.experimentId.toString(), experimentData.location);
        var abspath = check file:getAbsolutePath(path);
        log:printDebug("Add file " + abspath + "...");
        dataFileLocations.push(abspath);
    }

    var tmpDirBase = getTmpDir(os);
    var tmpDir = check file:joinPath(tmpDirBase, "export-" + exportId.toString());
    tmpDir = check ensureDirExists(tmpDir);
    json experimentCompleteJson = experimentComplete;
    string jsonFile = check file:joinPath(tmpDir, "experiment.json");
    var jsonPath = check file:getAbsolutePath(jsonFile);
    if check file:test(jsonPath, file:EXISTS) {
        check file:remove(jsonPath);
    }
    log:printDebug("Write " + jsonPath + " ...");
    check io:fileWriteJson(jsonPath, experimentCompleteJson);

    // create zip-  add all files (experiment file(s) + data files) to ZIP
    string zipFileName = regex:replaceAll(experimentComplete.experiment.name, "[\\s+\\\\/:<>\\|\\?\\*]", "-") + ".zip";
    var zipPath = check file:joinPath(tmpDir, zipFileName);
    var zipPathAbs = check file:getAbsolutePath(zipPath);
    log:printDebug("Create zip " + zipPathAbs + " ...");

    check zipExperiment(zipPathAbs, jsonPath, dataFileLocations, os);

    ExperimentExportZip exportResult = {name: zipFileName, location: zipPathAbs};
    return exportResult;
}

# Zip all created export files into one zip file
#
# + zipPath - path of zip
# + jsonPath - path of experiment json
# + dataFileLocations - paths for data files 
# + os - os type to determine appropriate exec command
# + return - error
public isolated transactional function zipExperiment(string zipPath, string jsonPath, string[] dataFileLocations, string os) returns error? {
    // add experiment.json
    os:Process|os:Error result;
    string syntax = "windows";
    if os.includes("windows") {
        result = check os:exec({value: "powershell", arguments: ["Compress-Archive", "-Update", jsonPath, zipPath]});
    } else {
        result = os:exec({value: "zip", arguments: ["-j", zipPath, jsonPath]});
        syntax = "linux";
    }
    if result is os:Error {
        log:printError("Unsupported os type (" + os + ") for file system manipulation (zipExperiment). Using " + syntax + " syntax was unsuccessful...");
        return result;
    } else {
        _ = check result.waitForExit();
    }

    // add experiment data files
    foreach string dataFile in dataFileLocations {
        log:printDebug("Add file to zip... " + dataFile);
        if os.includes("windows") {
            syntax = "windows";
            result = check os:exec({value: "powershell", arguments: ["Compress-Archive", "-Update", dataFile, zipPath]});
        } else {
            result = check os:exec({value: "zip", arguments: ["-j", zipPath, dataFile]});
            syntax = "linux";
        }
        if result is os:Error {
            log:printError("Unsupported os type (" + os + ") for file system manipulation (zipExperiment). Using " + syntax + " syntax was unsuccessful...");
            return result;
        } else {
            _ = check result.waitForExit();
        }
    }
}

# Create and start a long running background task for experiment export and a corresponding db entry.
#
# + experimentId - experiment id
# + config - export configuration // TODO
# + os - os type to determine appropriate exec command
# + storageLocation - storage location
# + return - id of export job db entry
public isolated transactional function createExportJob(int experimentId, ExperimentExportConfig config, string os, string storageLocation) returns int|error {
    // create experiment export db entry
    sql:ParameterizedQuery currentTime = ` strftime('%Y-%m-%dT%H:%M:%S', 'now') `;
    if configuredDBType != "sqlite" {
        currentTime = ` DATE_FORMAT(UTC_TIMESTAMP(), '%Y-%m-%dT%H:%i:%S') `;
    }
    ExperimentFull experiment = check getExperiment(experimentId);
    var insertResult = check experimentDB->execute(sql:queryConcat(`INSERT INTO ExperimentExport (experimentId, name, location, creationDate) VALUES (${experimentId}, ${experiment.name}, "", `, currentTime, `)`));

    var exportId = insertResult.lastInsertId;
    if exportId == () || exportId is string {
        fail error("Expected the expert Id back!");
    }
    int intExportId = check exportId.ensureType();

    // start long-running export task 
    _ = check task:scheduleOneTimeJob(new exportJob(intExportId, experiment, config, os, storageLocation), time:utcToCivil(time:utcAddSeconds(time:utcNow(), 1)));

    return intExportId;
    // TODO: garbage cleaning for import/export experiments
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

# Retrieve a list of recent exports.
#
# + item\-count - count
# + return - id of export job db entry
public isolated transactional function getExportList(int item\-count) returns ExportStatus[]|error {
    stream<ExportStatus, sql:Error?> result = experimentDB->query(`SELECT exportId, experimentId, status, name FROM ExperimentExport ORDER BY exportId DESC LIMIT ${item\-count};`);
    ExportStatus[]? experimentDataList = check from var data in result
        select data;
    check result.close();

    if experimentDataList != () {
        return experimentDataList;
    } else {
        return [];
    }
}

////////////////////////////////////////////////////////////////////////////////
// Export task /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# A background job that prepares an experiment for export. Corresponding db entry is updated on success or failure.
public class exportJob {

    *task:Job;
    int exportId;
    ExperimentFull experiment;
    ExperimentExportConfig exportConfig;
    string configuredOS;
    string storageLocation;

    public isolated function execute() {
        transaction {
            ExperimentExportZip experimentZip;
            experimentZip = check exportExperiment(self.experiment, self.exportId, self.exportConfig, self.configuredOS, self.storageLocation);

            _ = check experimentDB->execute(
                `UPDATE ExperimentExport 
                    SET status="SUCCESS", name=${experimentZip.name}, location=${experimentZip.location}
                WHERE experimentId = ${self.experiment.experimentId} AND exportId = ${self.exportId};`
            );

            check commit;
        } on fail error err {
            var res = experimentDB->execute(
                `UPDATE ExperimentExport 
                    SET status="FAILURE"
                WHERE experimentId = ${self.experiment.experimentId} AND exportId = ${self.exportId};`
            );
            if res is error {
                log:printError("Exporting experiment unsuccessful. Updating ExperimentExport unsuccessful! Failure will not be seen from the outside.", 'error = err, stackTrace = err.stackTrace());
            }
            log:printError("Exporting experiment unsuccessful.", 'error = err, stackTrace = err.stackTrace());
        }
    }

    isolated function init(int exportId, ExperimentFull experiment, ExperimentExportConfig exportConfig, string configuredOS, string storageLocation) {
        self.exportId = exportId;
        self.experiment = experiment;
        self.exportConfig = exportConfig;
        self.configuredOS = configuredOS;
        self.storageLocation = storageLocation;
    }
}

# Delete export entry
#
# + experimentId - experiment id
# + exportId - export db id
# + return - error or empty
public isolated transactional function deleteExport(int experimentId, int exportId) returns error? {
    var result = experimentDB->execute(
        `DELETE FROM ExperimentExport WHERE exportId=${exportId} AND experimentId=${experimentId};`
    );

    if result is error {
        return result;
    } else {
        return;
    }
}
