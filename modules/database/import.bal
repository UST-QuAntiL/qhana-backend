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
import ballerina/io;
import ballerina/http;

// import ballerina/uuid;

# Experiment import result record for importing experiments from a zip.
#
# + status - status of experiment import task
# + experimentId - experimentId
public type ExperimentImportResult record {|
    string status;
    int experimentId?;
|};

# Format input date for mariadb. Simply trim trailing 'Z'. May change in future versions.
#
# + date - input date
# + return - formatted date
public isolated function formatInputDateForMariadb(string? date) returns string? {
    if date == () {
        return date;
    }
    if date.endsWith("Z") {
        return date.substring(0, date.length() - 1);
    }
    return date;
}

# Import timeline step into db including associated step data db entries and substeps with associated substep data db entries
#
# + experimentId - experiment id
# + step - step with step data and substep list
# + sequence - step sequence number
# + dataIdMapping - mapping of external dataId to newly created internal dataId
# + return - error or ()
public isolated transactional function importTimelineStep(int experimentId, TimelineStepExport step, int sequence, map<int> & readonly dataIdMapping) returns error? {
    // import step
    sql:ParameterizedQuery startTime = ` strftime('%Y-%m-%dT%H:%M:%S', ${step.'start}), `;
    if configuredDBType != "sqlite" {
        string? 'start = formatInputDateForMariadb(step.'start);
        startTime = ` DATE_FORMAT(${'start}, '%Y-%m-%dT%H:%i:%S'), `;
    }
    sql:ParameterizedQuery endTime;
    if step.end == "" || step.end == () {
        endTime = ` '', `;
        if configuredDBType != "sqlite" {
            endTime = ` NULL, `;
        }
    } else {
        endTime = ` strftime('%Y-%m-%dT%H:%M:%S', ${step.end}), `;
        if configuredDBType != "sqlite" {
            string? end = formatInputDateForMariadb(step.end);
            endTime = ` DATE_FORMAT(${end}, '%Y-%m-%dT%H:%i:%S'), `;
        }
    }

    var insertResult = check experimentDB->execute(sql:queryConcat(
            `INSERT INTO TimelineStep (experimentId, sequence, start, end, status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart, pTarget, pValue, pUnit, notes) 
            VALUES (${experimentId}, ${sequence}, `,
            startTime, endTime,
            ` ${step.status}, ${step.resultQuality}, ${step.resultLog}, ${step.processorName}, ${step.processorVersion}, ${step.processorLocation}, ${step.parameters}, ${step.parametersContentType}, ${step.progressStart}, ${step.progressTarget}, ${step.progressValue}, ${step.progressUnit}, ${step.notes});`)
    );

    // extract experiment id and build full experiment data
    var s = insertResult.lastInsertId;
    if s is string {
        fail error("Expected integer id but got a string!");
    } else if s == () {
        fail error("Expected the experiment id back but got nothing!");
    } else {
        int stepId = check s.ensureType();
        // import step data db entry
        foreach StepDataExport stepData in step.stepDataList {
            _ = check experimentDB->execute(`INSERT INTO StepData (stepId, dataId, relationType) VALUES (${stepId}, ${dataIdMapping.get(stepData.dataId.toString())}, ${stepData.relationType});`);
        }

        // import substeps
        int substepNr = 1;
        foreach TimelineSubstepExport substep in step.timelineSubsteps {
            _ = check importTimelineSubstep(experimentId, stepId, substep, substepNr, dataIdMapping);
            substepNr += 1;
        }
    }
}

# Import timeline substep into db including associated substep data db entries
#
# + experimentId - Experiment id 
# + stepId - Step id of associated timeline step  
# + substep - Substep with substep data list
# + substepNr - Substep sequence number
# + dataIdMapping - mapping of external dataId to newly created internal dataId
# + return - error or ()
public isolated transactional function importTimelineSubstep(int experimentId, int stepId, TimelineSubstepExport substep, int substepNr, map<int> & readonly dataIdMapping) returns error? {
    // import substep
    _ = check experimentDB->execute(
        `INSERT INTO TimelineSubstep (stepId, substepNr, substepId, href, hrefUi, cleared, parameters, parametersContentType) 
         VALUES (${stepId}, ${substepNr}, ${substep.substepId}, ${substep.href}, ${substep.hrefUi}, ${substep.cleared}, ${substep.parameters}, ${substep.parametersContentType});`
    );

    // import substep data db entry
    foreach SubstepDataExport substepData in substep.substepDataList {
        _ = check experimentDB->execute(`INSERT INTO SubstepData (stepId, substepNr, dataId, relationType) VALUES (${stepId}, ${substepData.substepNr}, ${dataIdMapping.get(substepData.dataId.toString())}, ${substepData.relationType});`);
    }
}

# Import experiment data into db
#
# + experimentId - experiment id  
# + data - experiment data record
# + return - dataId of created entry or error
public isolated transactional function importExperimentDataDB(int experimentId, ExperimentDataExport data) returns int|error {
    var insertResult = check experimentDB->execute(`
        INSERT INTO ExperimentData (experimentId, name, version, location, type, contentType) 
        VALUES (${experimentId}, ${data.name}, ${data.'version}, ${data.location}, ${data.'type}, ${data.contentType})`);
    // extract experiment id and build full experiment data
    var dataId = insertResult.lastInsertId;
    if dataId is string {
        fail error("Expected integer id but got a string!");
    } else if dataId == () {
        fail error("Expected the experiment id back but got nothing!");
    } else {
        int id = check dataId.ensureType();
        return id;
    }
}

# Import experiment data from unzipped experiment
#
# + experiment - details of newly created experiment in db
# + experimentComplete - full expriment data to be imported
# + storageLocation - location of the storage for experiment data
# + zipLocation - (tmp) location of the zip file, assume that the directory only contains the zip file (clearing dir must be taken care of by calling function)
# + return - mapping of external dataId to newly created internal dataId
public isolated transactional function importExperimentData(ExperimentFull experiment, ExperimentCompleteExport experimentComplete, string storageLocation, string zipLocation) returns map<int> & readonly|error {
    map<int> dataIdMapping = {};
    string dataStorage = check prepareStorageLocation(experiment.experimentId, storageLocation);
    foreach ExperimentDataExport experimentData in experimentComplete.experimentDataList {
        // create folder for experimentData and copy data files there
        string fileId = experimentData.location;
        var filePath = check file:getAbsolutePath(zipLocation + "/" + fileId);
        var targetFile = check file:getAbsolutePath(dataStorage + "/" + fileId); // TODO replace with joinPath
        log:printDebug("Copy " + filePath + " to " + targetFile + "...");
        check file:copy(filePath, targetFile, file:REPLACE_EXISTING);

        // replace data location with new absolute location
        experimentData.location = filePath;

        // create db entries
        int newDataId = check importExperimentDataDB(experiment.experimentId, experimentData);
        dataIdMapping[experimentData.dataId.toString()] = newDataId;
    }
    return dataIdMapping.cloneReadOnly();
}

# Import timeline steps with substeps
#
# + experiment - details of newly created experiment in db
# + experimentComplete - full expriment data to be imported
# + dataIdMapping - mapping of external dataId to newly created internal dataId
# + return - error 
public isolated transactional function importTimelineSteps(ExperimentFull experiment, ExperimentCompleteExport experimentComplete, map<int> & readonly dataIdMapping) returns error? {
    int stepSequence = 1;
    foreach TimelineStepExport timelineStep in experimentComplete.timelineSteps {
        check importTimelineStep(experiment.experimentId, timelineStep, stepSequence, dataIdMapping.cloneReadOnly());
        stepSequence += 1;
    }
}

# Import an experiment from a zip file. Assume that zip file is in directory tmp
#
# + zipPath - (relative) path to zip file
# + storageLocation - location of the storage for experiment data
# + zipLocation - (tmp) location of the zip file, assume that the directory only contains the zip file (clearing dir must be taken care of by calling function)
# + os - os type to determine appropriate exec command
# + return - record with details about created zip files or error
public isolated transactional function importExperiment(string zipPath, string storageLocation, string zipLocation, string os) returns ExperimentFull|error {

    check unzipFile(zipPath, zipLocation, os);

    // read experiment.json
    string jsonFile = "experiment.json";
    var jsonPath = check file:getAbsolutePath(zipLocation + "/" + jsonFile);
    json experimentCompleteJson = check io:fileReadJson(jsonPath);
    ExperimentCompleteExport experimentComplete = check experimentCompleteJson.cloneWithType(ExperimentCompleteExport);

    ExperimentFull experiment = check createExperiment(experimentComplete.experiment);

    map<int> & readonly dataIdMapping = check importExperimentData(experiment, experimentComplete, storageLocation, zipLocation);

    check importTimelineSteps(experiment, experimentComplete, dataIdMapping);
    return experiment;
}

# Create and start a long running background task for experiment import and a corresponding db entry.
#
# + storageLocation - location of the storage for experiment data
# + configuredOS - os type to determine appropriate exec command
# + request - request with received data
# + return - id of import job db entry
public isolated transactional function createImportJob(string storageLocation, string configuredOS, http:Request request) returns int|error {

    // create experiment import db entry
    sql:ParameterizedQuery currentTime = ` strftime('%Y-%m-%dT%H:%M:%S', 'now') `;
    if configuredDBType != "sqlite" {
        currentTime = ` DATE_FORMAT(UTC_TIMESTAMP(), '%Y-%m-%dT%H:%i:%S') `;
    }
    var insertResult = check experimentDB->execute(sql:queryConcat(`INSERT INTO ExperimentImport (creationTime) VALUES (`, currentTime, `);`));

    var importId = insertResult.lastInsertId;
    if importId == () || importId is string {
        fail error("Expected the expert Id back!");
    }
    int intImportId = check importId.ensureType();

    stream<byte[], io:Error?> streamer = check request.getByteStream();
    // create/renew tmp dir
    var tmpDir = getTmpDir(configuredOS);
    var zipLocation = check file:getAbsolutePath(tmpDir + "/import-" + intImportId.toString());
    check wipeDir(zipLocation);

    // write zip file to file system
    // var zipPath = check file:joinPath(zipLocation, "import.zip"); // TODO: check, joinPath messes up paths in docker
    string zipPath = zipLocation + "/import.zip";
    check io:fileWriteBlocksFromStream(zipPath, streamer);
    check streamer.close();

    // start long-running import task 
    _ = check task:scheduleOneTimeJob(new importJob(intImportId, zipPath, storageLocation, zipLocation, configuredOS), time:utcToCivil(time:utcAddSeconds(time:utcNow(), 1)));

    return intImportId;
}

# Retrieve result for import job.
#
# + importId - id of import db entry
# + return - id of import job db entry
public isolated transactional function getImportResult(int importId) returns ExperimentImportResult|error {
    stream<ExperimentImportResult, sql:Error?> result = experimentDB->query(`SELECT status, experimentId FROM ExperimentImport WHERE importId=${importId};`);

    var experimentImport = result.next();
    check result.close();

    if !(experimentImport is sql:Error) && (experimentImport != ()) {
        return experimentImport.value;
    }

    return error(string `Experiment import entry with id ${importId} was not found!`);
}

# A background job that prepares an experiment for export. Corresponding db entry is updated on success or failure.
public class importJob {

    *task:Job;
    int importId;
    string zipPath;
    string storageLocation;
    string zipLocation;
    string configuredOS;

    public isolated function execute() {
        transaction {
            ExperimentFull result = check importExperiment(self.zipPath, self.storageLocation, self.zipLocation, self.configuredOS);

            _ = check experimentDB->execute(
                `UPDATE ExperimentImport 
                    SET status="SUCCESS", experimentId=${result.experimentId}
                WHERE importId = ${self.importId};`
            );

            check commit;
        } on fail error err {
            var res = experimentDB->execute(
                `UPDATE ExperimentImport 
                    SET status="FAILURE"
                WHERE importId = ${self.importId};`
            );
            log:printError("Importing experiment unsuccessful.", 'error = err, stackTrace = err.stackTrace());
            if res is error {
                log:printError("While processing an error during the experiment import another error occurred: updating ExperimentImport unsuccessful! Failure will not be seen from the outside.", 'error = res, stackTrace = res.stackTrace());
            }
        }
    }

    isolated function init(int importId, string zipPath, string storageLocation, string zipLocation, string configuredOS) {
        self.importId = importId;
        self.zipPath = zipPath;
        self.storageLocation = storageLocation;
        self.zipLocation = zipLocation;
        self.configuredOS = configuredOS;
    }
}
