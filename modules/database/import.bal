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
import ballerina/os;
import ballerina/uuid;

# Import an experiment from a zip file. Assume that zip file is in directory tmp
#
# + zipPath - (relative) path to zip file
# + storageLocation - location of the storage for experiment data
# + zipLocation - (tmp) location of the zip file, assume that the directory only contains the zip file (clearing dir must be taken care of by calling function)
# + os - os type to determine appropriate exec command
# + return - record with details about created zip files or error
public isolated transactional function importExperiment(string zipPath, string storageLocation, string zipLocation, string os) returns ExperimentFull|error {

    // unzip file
    os:Process result;
    if os == "linux" {
        result = check os:exec({value: "unzip", arguments: [zipPath, "-d", zipLocation]});
    }
    else if os == "windows" {
        result = check os:exec({value: "powershell", arguments: ["Expand-Archive", "-DestinationPath", zipLocation, zipPath]});
    } else {
        return error("Unsupported operating system! At the moment, we support 'linux' and 'windows' for importing/exporting experiments. Please make sure to properly specify the os env var or config entry.");
    }
    _ = check result.waitForExit();

    // read experiment.json
    string jsonFile = "experiment.json";
    var jsonPath = check file:joinPath(zipLocation, jsonFile);
    json experimentCompleteJson = check io:fileReadJson(jsonPath);
    ExperimentCompleteExport experimentComplete = check experimentCompleteJson.cloneWithType(ExperimentCompleteExport);

    // create experiment
    ExperimentFull importedExperiment = check createExperiment(experimentComplete.experiment);

    // experiment data
    map<int> dataIdMapping = {};
    string dataStorage = check prepareStorageLocation(importedExperiment.experimentId, storageLocation);
    foreach ExperimentDataExport experimentData in experimentComplete.experimentDataList {
        // create folder for experimentData and copy data files there
        string fileId = experimentData.location;
        string filePath = check file:joinPath(zipLocation, fileId);
        if os == "linux" {
            result = check os:exec({value: "cp", arguments: [filePath, dataStorage]});
        } else if os == "windows" {
            result = check os:exec({value: "powershell", arguments: ["cp", filePath, dataStorage]});
        } else {
            return error("Unsupported operating system! At the moment, we support 'linux' and 'windows' for importing/exporting experiments. Please make sure to properly specify the os env var or config entry.");
        }
        _ = check result.waitForExit();
        var normalizedPath = check file:normalizePath(filePath, file:CLEAN);

        // replace data location with new absolute location
        var abspath = check file:getAbsolutePath(normalizedPath);
        experimentData.location = abspath;

        // create db entries
        int newDataId = check importExperimentData(importedExperiment.experimentId, experimentData);
        dataIdMapping[experimentData.dataId.toString()] = newDataId;
    }

    // import timeline steps (make sure step/substep data is correct)
    int stepSequence = 1;
    foreach TimelineStepExport timelineStep in experimentComplete.timelineSteps {
        _ = check importTimelineStep(importedExperiment.experimentId, timelineStep, stepSequence, dataIdMapping);
        stepSequence += 1;
    }

    return importedExperiment;
}

# Create and start a long running background task for experiment import and a corresponding db entry.
#
# + storageLocation - location of the storage for experiment data
# + configuredOS - os type to determine appropriate exec command
# + request - request with received data
# + return - id of import job db entry
public isolated transactional function createImportJob(string storageLocation, string configuredOS, http:Request request) returns int|error {

    stream<byte[], io:Error?> streamer = check request.getByteStream();
    // create/renew tmp dir
    string zipLocation = check file:joinPath("tmp", "import-" + uuid:createType1AsString());
    var exists = file:test(zipLocation, file:EXISTS);
    if exists !is error && exists {
        if configuredOS == "windows" {
            os:Process r = check os:exec({value: "powershell", arguments: ["Remove-Item", zipLocation, "-recurse", "-force"]});
            _ = check r.waitForExit();
        } else {
            check file:remove(zipLocation, file:RECURSIVE);
        }
    }
    var x = file:createDir(zipLocation);
    if x is error {
        log:printDebug("Creating dir unsuccessful. Continue anyways...");
    }
    // write zip file to file system
    var zipPath = check file:joinPath(zipLocation, "import.zip");
    check io:fileWriteBlocksFromStream(zipPath, streamer);
    check streamer.close();

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
    // TODO: maybe generate a secure importId instead of using autoincremented ints

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
            if res is error {
                log:printError("Importing experiment unsuccessful. Updating ExperimentImport unsuccessful! Failure will not be seen from the outside.", 'error = err, stackTrace = err.stackTrace());
            }
            log:printError("Importing experiment unsuccessful.", 'error = err, stackTrace = err.stackTrace());
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
