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
import ballerina/io;
import ballerina/mime;
import ballerina/time;
import ballerina/file;
import ballerina/log;
import qhana_backend.java.io as javaio;
import qhana_backend.java.util.zip as javazip;

public type IdSQL record {|
    int id;
|};

# Clones an experiment in the database.
#
# + oldExperimentId - experiment id of the experiment that is to be cloned
# + return - The experiment data including the database id or the encountered error
public isolated transactional function cloneExperiment(int oldExperimentId) returns ExperimentFull|error {
    ExperimentFull? result = ();

    // clone experiment
    ExperimentFull experimentInfo = check getExperiment(oldExperimentId);
    experimentInfo.name = experimentInfo.name + " (copy)";

    var experimentInsertResult = check experimentDB->execute(
        `INSERT INTO Experiment (name, description) VALUES (${experimentInfo.name}, ${experimentInfo.description});`
    );

    // extract experiment id and build full experiment data
    var newExperimentId = experimentInsertResult.lastInsertId;
    if newExperimentId !is int {
        fail error("Expected integer id but got a string or Nil!");
    } else {
        result = {experimentId: newExperimentId, name: experimentInfo.name, description: experimentInfo.description};

        log:printDebug(string `[experimentId ${oldExperimentId}] Cloned experiment has experimentId ${newExperimentId}`); // TODO: remove

        // map old experimentData ids to new (cloned) to avoid duplication
        map<int> oldDataIdToNewDataId = {};

        // clone timeline steps
        stream<record {|int stepId;|}, sql:Error?> timelineStepResult = experimentDB->query(`SELECT stepId FROM TimelineStep WHERE experimentId=${oldExperimentId};`);
        int[]|error|() timelineStepList = from var step in timelineStepResult
            select step.stepId;
        if timelineStepList !is error && timelineStepList !is () {
            int counter = 0;
            foreach var oldTimelineStepId in timelineStepList {
                counter += 1;
                _ = check cloneTimelineStepComplex(newExperimentId, oldExperimentId, oldTimelineStepId, oldDataIdToNewDataId);
            }
            log:printDebug(string `[ExperimentId ${newExperimentId}] Cloned ${counter} TimelineSteps.`);
        }
        if result == () {
            // this should logically never happen but is included for the compiler
            return error("Experiment was empty after transaction comitted.");
        } else {
            return result;
        }
    }
}

# Clones an ExperimentData item. 
#
# Checks if item is already cloned (in mapping of old/new ids). If not the item is cloned and added to the mapping
#
# + oldDataIdToNewDataId - mutable mapping of old ExperimentData item ids to new experiment data ids to check if new experiment data needs to be created or not
# + dataId - id of old ExperimentData item that is to be cloned
# + newExperimentId - experiment id of the new (cloned) experiment
# + oldExperimentId - experiment id of the experiment that is being cloned
# + return - The new (cloned) ExperimentData id or the encountered error
public isolated transactional function cloneExperimentData(map<int> oldDataIdToNewDataId, int dataId, int newExperimentId, int oldExperimentId) returns int|error {
    // TODO: deep copy?
    int? clonedExperimentDataId = oldDataIdToNewDataId[dataId.toString()];
    if clonedExperimentDataId is () {
        // not cloned yet => clone experiment data 
        var experimentDataInsertResult = check experimentDB->execute(
            `INSERT INTO ExperimentData (experimentId, name, version, location, type, contentType) 
            SELECT ${newExperimentId}, name, version, location, type, contentType
            FROM ExperimentData
            WHERE experimentId = ${oldExperimentId} AND dataId = ${dataId};`
        );
        // add to mapping
        var newExperimentDataId = experimentDataInsertResult.lastInsertId;
        if newExperimentDataId is int {
            lock {
                oldDataIdToNewDataId[dataId.toString()] = newExperimentDataId;
            }
            log:printDebug(string `[experimentId ${oldExperimentId}, dataId ${dataId}] Cloned ExperimentData. Cloned ExperimentData has dataId ${newExperimentDataId}.`); // TODO: remove
            return newExperimentDataId;
        } else {
            fail error("Expected the experimentData id back but got nothing or Nil!");
        }
    } else {
        return clonedExperimentDataId;
    }
}

# Clones a timeline step. 
#
# + newExperimentId - experiment id of the new (cloned) experiment
# + oldExperimentId - experiment id of the experiment that is being cloned
# + oldTimelineStepId - step id of (old) timeline step that is to be cloned
# + return - The new (cloned) timeline step id or the encountered error
public isolated transactional function cloneTimelineStepSimple(int newExperimentId, int oldExperimentId, int oldTimelineStepId) returns int|error {
    var timelineStepInsertResult = check experimentDB->execute(
        `INSERT INTO TimelineStep (experimentId, sequence, start, end, status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart, pTarget, pValue, pUnit, notes)
        SELECT ${newExperimentId}, sequence, start, end, status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart, pTarget, pValue, pUnit, notes
        FROM TimelineStep
        WHERE experimentId = ${oldExperimentId} AND stepId = ${oldTimelineStepId};`
    );
    var newTimelineStepId = timelineStepInsertResult.lastInsertId;
    if newTimelineStepId !is int || newTimelineStepId < 0 {
        fail error("Cloning of TimelineStep with (old) id " + oldTimelineStepId.toString() + " unsuccessful [oldExperimentId: " + oldExperimentId.toString() + ", newExperimentId: " + newExperimentId.toString() + "]!");
    } else {
        log:printDebug(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloned TimelineStep has id ${newTimelineStepId}.`); // TODO: remove
        return newTimelineStepId;
    }
}

# Clones timeline substep including associated substep data and experiment data.
#
# + newExperimentId - experiment id of the new (cloned) experiment
# + oldExperimentId - experiment id of the experiment that is being cloned
# + oldTimelineStepId - step id of (old) timeline step that is to be cloned
# + newTimelineStepId - step id of (new, target) timeline step in cloning
# + oldTimelineSubstepNr - substep nr of (old) timeline step that is to be cloned
# + oldDataIdToNewDataId - mutable mapping of old ExperimentData item ids to new experiment data ids to check if new experiment data needs to be created or not
# + return - The new (cloned) timeline step id or the encountered error
public isolated transactional function cloneTimelineSubstepComplex(int newExperimentId, int oldExperimentId, int oldTimelineStepId, map<int> oldDataIdToNewDataId, int newTimelineStepId, int oldTimelineSubstepNr) returns ()|error {
    // clone timeline substep
    var timelineSubstepInsertResult = check experimentDB->execute(
        `INSERT INTO TimelineSubstep (stepId, substepNr, substepId, href, hrefUi, cleared, parameters, parametersContentType)
        SELECT ${newTimelineStepId}, substepNr, substepId, href, hrefUi, cleared, parameters, parametersContentType
        FROM TimelineSubstep
        WHERE stepId = ${oldTimelineStepId} AND substepNr = ${oldTimelineSubstepNr};`
    );
    var rowCount = timelineSubstepInsertResult.affectedRowCount;
    if rowCount == () || rowCount < 1 {
        fail error(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloning of TimelineSubstep with substepNr ${oldTimelineSubstepNr} unsuccessful!`);
    }
    log:printDebug(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloned substep with substepNr ${oldTimelineSubstepNr}.`); // TODO remove

    // find and clone associated substepData
    stream<record {|int id; int dataId;|}, sql:Error?> substepDataResult = experimentDB->query(`SELECT id, dataId FROM SubstepData WHERE stepId = ${oldTimelineStepId} AND substepNr=${oldTimelineSubstepNr};`);
    record {|int id; int dataId;|}[]|error|() substepDataList = from var data in substepDataResult
        select data;
    if substepDataList !is error && substepDataList !is () {
        foreach var substepData in substepDataList {
            // TODO: deep copy
            int clonedExperimentDataId = check cloneExperimentData(oldDataIdToNewDataId, substepData.dataId, newExperimentId, oldExperimentId);

            //   clone step data with id of new experiment data
            var stepDataInsertResult = check experimentDB->execute(
                `INSERT INTO SubstepData (stepId, substepNr, dataId, relationType) 
                SELECT ${newTimelineStepId}, ${oldTimelineSubstepNr}, ${clonedExperimentDataId}, relationType
                FROM StepData
                WHERE stepId = ${oldTimelineStepId} AND dataId = ${substepData.dataId};`
            );
            rowCount = stepDataInsertResult.affectedRowCount;
            if rowCount == () || rowCount < 1 {
                fail error(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}, substepNr ${oldTimelineSubstepNr}] Cloning of SubstepData with dataId ${substepData.dataId} unsuccessful.`);
            }
            log:printDebug(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}, SubstepNr: ${oldTimelineSubstepNr}] Cloned SubstepData item with dataId ${substepData.dataId}.`); // TODO remove
        }
    }
}

# Clones timeline step including associated step data, experiment data, and substeps.
#
# + newExperimentId - experiment id of the new (cloned) experiment
# + oldExperimentId - experiment id of the experiment that is being cloned
# + oldTimelineStepId - step id of (old) timeline step that is to be cloned
# + oldDataIdToNewDataId - mutable mapping of old ExperimentData item ids to new experiment data ids to check if new experiment data needs to be created or not
# + return - The new (cloned) timeline step id or the encountered error
public isolated transactional function cloneTimelineStepComplex(int newExperimentId, int oldExperimentId, int oldTimelineStepId, map<int> oldDataIdToNewDataId) returns ()|error {
    // clone timeline step
    var newTimelineStepId = check cloneTimelineStepSimple(newExperimentId, oldExperimentId, oldTimelineStepId);

    // find and clone associated step data 
    stream<record {|int id; int dataId;|}, sql:Error?> stepDataResult = experimentDB->query(`SELECT id, dataId FROM StepData WHERE stepId = ${oldTimelineStepId};`);
    record {|int id; int dataId;|}[]|error|() stepDataList = from var data in stepDataResult
        select data;
    if stepDataList !is error && stepDataList !is () {
        foreach var stepData in stepDataList {
            // check if associated experiment data was already cloned
            // TODO: deep copy
            int clonedExperimentDataId = check cloneExperimentData(oldDataIdToNewDataId, stepData.dataId, newExperimentId, oldExperimentId);
            //   clone step data with id of new experiment data
            var stepDataInsertResult = check experimentDB->execute(
                `INSERT INTO StepData (stepId, dataId, relationType) 
                SELECT ${newTimelineStepId}, ${clonedExperimentDataId}, relationType
                FROM StepData
                WHERE stepId = ${oldTimelineStepId} AND dataId = ${stepData.dataId};`
            );
            var rowCount = stepDataInsertResult.affectedRowCount;
            if rowCount == () || rowCount < 1 {
                fail error(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloning of StepData with dataId ${clonedExperimentDataId} unsuccessful!`);
            }
            log:printDebug(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloned StepData with dataId ${stepData.dataId}.`); // TODO remove
        }
    }
    // clone all associated timeline substeps
    stream<record {|int substepNr;|}, sql:Error?> timelineSubstepResult = experimentDB->query(`SELECT substepNr FROM TimelineSubstep WHERE stepId=${oldTimelineStepId};`);
    int[]|error|() timelineSubstepNrList = from var substep in timelineSubstepResult
        select substep.substepNr;
    if timelineSubstepNrList !is error && timelineSubstepNrList !is () {
        int counter = 0;
        foreach int oldTimelineSubstepNr in timelineSubstepNrList {
            counter += 1;
            _ = check cloneTimelineSubstepComplex(newExperimentId, oldExperimentId, oldTimelineStepId, oldDataIdToNewDataId, newTimelineStepId, oldTimelineSubstepNr);
        }
        log:printDebug(string `[experimentId ${oldExperimentId}, stepId ${oldTimelineStepId}] Cloned ${counter} TimelineSubsteps.`); // TODO remove
    }
}

# Record for exporting/importing experiment data
#
# + dataId - The database id of the data item (used for reference, changer on import)
public type ExperimentDataExport record {|
    int dataId;
    *ExperimentData; // TODO: how to map location to files in ZIP?
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
    string parameters;
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
        return error(string `[stepId ${stepId}] Could not retrieve substep list for export from database.`);
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
    TimelineStepFull[] timelineStepListDb = check getTimelineStepList(experimentId, allAttributes = true, allSteps = true);
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

# Prepare zip file for export of an experiment.
#
# + experimentId - experiment id of the new (cloned) experiment
# + config - export configuration
# + return - record with details about created zip files or error
public transactional function exportExperiment(int experimentId, ExperimentExportConfig config) returns ExperimentExportZip|error {

    string zipFilename = "";
    string zipFileLocation = "";
    int fileLength = 0;

    ExperimentCompleteExport experimentComplete = check getExperimentDBExport(experimentId);
    // data files
    string[] dataFileLocations = [];
    ExperimentDataExport[] experimentDataList = experimentComplete.experimentDataList;
    foreach var experimentData in experimentDataList {
        string location = experimentData.location;
        dataFileLocations.push(location);
        // remove path from file location
        int? index = location.lastIndexOf("/");
        if index is () {
            index = location.lastIndexOf("\\");
            if index is () {
                return error("Unable to determine relative file location.");
            } else {
                experimentData.location = location.substring(index + 1, location.length());
            }
        } else {
            experimentData.location = location.substring(index + 1, location.length()); // not very pretty but compiler check recognize assignment of index...
        }
    }

    // string tmpDir = check file:createTempDir();
    var exists = file:test("tmp", file:EXISTS);
    if exists !is error && !exists {
        check file:createDir("tmp");
    }
    json experimentCompleteJson = experimentComplete;
    string jsonFile = "experiment.json";
    var jsonPath = check file:joinPath("tmp", jsonFile); //TODO: replace with var jsonPath = check file:joinPath(tmpDir, jsonFile);
    exists = file:test(jsonPath, file:EXISTS);
    if exists !is error && exists {
        check file:remove(jsonPath);
    }
    check io:fileWriteJson(jsonPath, experimentCompleteJson);

    // create zip-  add all files (experiment file(s) + data files) to ZIP
    string zipFileName = "experiment.zip";
    var zipPath = check file:joinPath("tmp", zipFileName); //TODO: replace with var jsonPath = check file:joinPath(tmpDir, zipFileName);
    javaio:File zipFile = javaio:newFile2(zipPath);
    javaio:FileOutputStream fileOutStream = check javaio:newFileOutputStream1(zipFile);
    javazip:ZipOutputStream zipOutStream = javazip:newZipOutputStream1(fileOutStream);

    // add experiment.json
    javaio:FileInputStream inStream = check javaio:newFileInputStream1(javaio:newFile2(jsonPath));
    javazip:ZipEntry entry = javazip:newZipEntry1(jsonFile);
    _ = check zipOutStream.putNextEntry(entry);
    byte[] data = check inStream.readAllBytes();
    _ = check zipOutStream.write(data);
    _ = check zipOutStream.closeEntry();
    _ = check inStream.close();

    // add experiment data files
    foreach string dataFile in dataFileLocations {
        inStream = check javaio:newFileInputStream1(javaio:newFile2(dataFile));
        entry = javazip:newZipEntry1(dataFile);
        _ = check zipOutStream.putNextEntry(entry);
        data = check inStream.readAllBytes();
        _ = check zipOutStream.write(data);
        _ = check zipOutStream.closeEntry();
        _ = check inStream.close();
    }
    _ = check zipOutStream.close();
    _ = check fileOutStream.close();

    fileLength = zipFile.length();
    ExperimentExportZip exportResult = {name: zipPath, location: zipFileLocation, fileLength: fileLength};
    return exportResult;
}
