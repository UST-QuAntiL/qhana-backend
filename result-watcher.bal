// Copyright 2021 University of Stuttgart
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

import ballerina/http;
import ballerina/task;
import ballerina/file;
import ballerina/io;
import ballerina/uuid;
import qhana_backend.database;

configurable string storageLocation = "experimentData";


type TaskDataOutput record {
    string href;
    string outputType;
    string contentType;
    string? name?;
};

type TaskStatusResponse record {
    string name;
    string taskId;
    string status;
    string? taskLog?;
    TaskDataOutput[]? outputs?;
};


isolated class ResultProcessor {

    private final int experimentId;
    private final int stepId;
    private final string & readonly resultEndpoint;
    private final TaskStatusResponse & readonly result;
    private final database:ExperimentData[] processedOutputs;

    isolated function init(TaskStatusResponse result, int experimentId, int stepId, string resultEndpoint) {
        self.experimentId = experimentId;
        self.stepId = stepId;
        self.resultEndpoint = resultEndpoint;

        self.result = result.cloneReadOnly();
        self.processedOutputs = [];
    }

    public isolated function processResult() returns error? {
        if self.result.status == "SUCCESS" {
            check self.saveSuccessfullResult();
        } else {
            check self.saveErrorResult();
        }
    }

    private isolated function compensateFileCreation('transaction:Info info, error? cause, boolean willRetry) {
        io:println("Rolling back the transaction");
        // compensate by deleting unused files
        lock {
            foreach var processed in self.processedOutputs {
                do {
                    if check file:test(processed.location, file:EXISTS) {
                        check file:remove(processed.location);
                    }
                } on fail var compensationError {
                    // TODO actual error logging (and periodic cleanup job looking for files not in a database)
                    io:println(string`Error during deletion of file ${processed.location}, while compensating on error importing result for task ${self.result.taskId}!`, compensationError);
                }
            }
        }
    }

    private isolated function saveSuccessfullResult() returns error? {
        var outputs = self.result?.outputs;
        
        transaction {

            'transaction:onRollback(self.compensateFileCreation);

            if outputs is TaskDataOutput[] {
                foreach var output in outputs {
                    http:Client c = check new (output.href);
                    http:Response fileResponse = check c->get("");
                    var fileDir = check prepareStorageLocation(self.experimentId);
                    var fileId = uuid:createType4AsString();
                    var filePath = check file:joinPath(fileDir, fileId);
                    while check file:test(filePath, file:EXISTS) {
                        fileId = uuid:createType4AsString();
                        filePath = check file:joinPath(fileDir, fileId);
                    }
                    var filename = output?.name;
                    lock {
                        self.processedOutputs.push({
                            name: filename != () ? filename : fileId,
                            'version: -1,
                            location: filePath,
                            'type: output.outputType,
                            contentType: output.contentType
                        });
                    }
                    check file:create(filePath);
                    var fileStream = fileResponse.getByteStream();
                    if !(fileStream is error) {
                        check io:fileWriteBlocksFromStream(filePath, fileStream, io:OVERWRITE);
                    } else {
                        // try directly reading bytes instead
                        var fileContent = check fileResponse.getBinaryPayload();
                        check io:fileWriteBytes(filePath, fileContent, io:OVERWRITE);
                    }
                }
            }

            lock {
                _ = check database:saveTimelineStepOutputData(self.stepId, self.experimentId, self.processedOutputs);
            }

            var r = self.result;
            var status = r.status;
            var resultLog = r["resultLog"];

            _ = check database:updateTimelineStepStatus(self.stepId, status, resultLog);
            check database:deleteTimelineStepResultWatcher(self.stepId);

            check commit;
        }
    }

    private isolated function saveErrorResult() returns error? {
        transaction {
            var r = self.result;
            var status = r.status;
            var resultLog = r["resultLog"];

            _ = check database:updateTimelineStepStatus(self.stepId, status, resultLog);
            check database:deleteTimelineStepResultWatcher(self.stepId);

            check commit;
        }
    }
}


public isolated class ResultWatcher {

    *task:Job;

    final http:Client httpClient;
    final int experimentId;
    final int stepId;
    private final string&readonly resultEndpoint;
    private int errorCounter;
    private task:JobId? jobId=();
    private decimal[] scheduleIntervals = [5];
    private int[] backoffCounters = [];
    private int? currentBackoffCounter = ();

    public isolated function execute() {
        int currentErrorCounter;
        lock {
            currentErrorCounter = self.errorCounter;
        }
        if currentErrorCounter > 5 {
            var err = self.unschedule();
            if err is error {
                io:println(string`Failed to unsubscribe step result watcher for step ${self.stepId}`, err);
            }
        }

        // request specified endpoint
        TaskStatusResponse|error result = self.httpClient->get("");
        if result is error {
            lock {
                self.errorCounter += 1;
            }
        } else {
            lock {
                if self.errorCounter > 0 {
                    // allow error counter to heal
                    self.errorCounter -= 1;
                }
            }
            self.checkTaskResult(result);
        }

        // handle backoff counter
        int? lastBackoffCounter;
        lock {
            lastBackoffCounter = self.currentBackoffCounter;
        }
        if lastBackoffCounter != () {
            lock {
                self.currentBackoffCounter = lastBackoffCounter - 1;
            }
            if lastBackoffCounter <= 0 {
                do {
                    // perform backoff
                    decimal? newInterval;
                    lock {
                        newInterval = self.scheduleIntervals.length() > 0 ? self.scheduleIntervals.pop() : ();
                        self.currentBackoffCounter = self.backoffCounters.length() > 0 ? self.backoffCounters.pop() : ();
                    }
                    if newInterval == () {
                        check self.unschedule();
                        io:println(`finally finish executing job for step ${self.stepId}`);
                        return;
                    } else {
                        check self.reschedule(newInterval);
                    }
                } on fail error err {
                    lock {
                        self.errorCounter += 1;
                    }
                }
            }
        }
    }

    private isolated function reschedule(decimal interval) returns error? {
        check self.unschedule();

        lock {
            self.jobId = check task:scheduleJobRecurByFrequency(self, interval);
            io:println(string`Scheduled watcher for step ${self.stepId} with interval ${interval}. JobId: ${self.jobId.toString()}`);
        }
    }

    # Schedule this background job periodically with the given interval in seconds.
    # 
    # If more than one number is given every second number starting from the first is
    # interpreted as an interval. The number following the intervall is the number of
    # times this background job is scheduled with that intervall. If no number follows
    # an intervall, then the job will not unschedule itself.
    # 
    # If the number of times is exceeded, then the job will reschedule itself
    # with the next intervall in the list. If no intervall is left, then the job 
    # will unschedule itself.
    #
    # Unschedules the job first if it was already scheduled.
    #
    # + intervals - usage: `[intervall1, backoffCounter1, intervall2, backoffCounter2, ..., [intervallLast]]`
    # + return - The error encountered while (re)scheduling this job (or parsing the intervals)
    public isolated function schedule(decimal|int ...intervals) returns error? {
        if intervals.length() <= 0 {
            return error("Must specify at least one inteval!");
        }
        decimal[] scheduleIntervals = [];
        int[] backoffCounters = [];
        foreach int i in 0..<intervals.length() {
            if i % 2 == 0 {
                scheduleIntervals.push(<decimal> intervals[i]);
            } else {
                var counter = intervals[i];
                if counter is int {
                    backoffCounters.push(counter);
                } else {
                    backoffCounters.push(<int> counter.ceiling());
                }
            }
        }

        lock {
            self.scheduleIntervals = scheduleIntervals.clone().reverse();
            self.backoffCounters = backoffCounters.clone().reverse();

            var startingIntervall = self.scheduleIntervals.pop(); // list always contains >1 entries at this point (see guard at top)
            self.currentBackoffCounter = self.backoffCounters.length()>0 ? self.backoffCounters.pop() : ();

            check self.reschedule(startingIntervall);
        }
    }

    # Unschedule the job.
    # 
    # Only works if the job was scheduled using the `schedule` method of the job.
    # 
    # + return - The error encountered.
    public isolated function unschedule() returns error? {
        task:JobId? jobId;
        lock {
            jobId = self.jobId;
        }
        if jobId is task:JobId {
            check task:unscheduleJob(jobId);
            io:println(string`Unscheduled watcher for step ${self.stepId}. JobId: ${jobId.toString()}`);
        }
    }

    private isolated function checkTaskResult(TaskStatusResponse result) {
        if result.status == "UNKNOWN" || result.status == "PENDING" {
            return; // nothing to do, still waiting for result
        }
        do {
            ResultProcessor processor = new (result, self.experimentId, self.stepId, self.resultEndpoint);
            check processor.processResult();
            check self.unschedule();
        } on fail error e {
            lock {
                self.errorCounter += 1;
            }
            io:println(e);
        }
    }


    isolated function init(int stepId) returns error? {
        self.errorCounter = 0;

        self.stepId = stepId;

        string? resultEndpoint;

        if transactional {
            resultEndpoint = check database:getTimelineStepResultEndpoint(stepId);
            var step = check database:getTimelineStep(stepId=stepId);
            self.experimentId = step.experimentId;
        } else {
            transaction {
                resultEndpoint = check database:getTimelineStepResultEndpoint(stepId);
                var step = check database:getTimelineStep(stepId=stepId);
                self.experimentId = step.experimentId;
                check commit;
            }
        }

        if resultEndpoint is () {
            return error("Cannot watch a task result with no associated resultEndpoint!");
        } else if resultEndpoint == "" {
            return error("Cannot watch a task result with an empty resultEndpoint!");
        } else {
            self.resultEndpoint = resultEndpoint;
            self.httpClient = check new (self.resultEndpoint);
        }
    }
}

isolated function prepareStorageLocation(int experimentId) returns string|error {
    var relPath = check file:joinPath(storageLocation, string`${experimentId}`);
    var normalizedPath = check file:normalizePath(relPath, file:CLEAN);
    var abspath = check file:getAbsolutePath(normalizedPath);
    check file:createDir(abspath, file:RECURSIVE);
    return abspath;
}
