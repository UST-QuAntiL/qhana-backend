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

isolated map<ResultWatcher> resultWatcherRegistry = {};

isolated function addResultWatcherToRegistry(ResultWatcher watcher) {
    lock {
        resultWatcherRegistry[watcher.stepId.toString()] = watcher;
    }
}

isolated function getResultWatcherFromRegistry(int stepId) returns ResultWatcher|error {
    lock {
        ResultWatcher? w = resultWatcherRegistry[stepId.toString()];
        if w != () {
            return w;
        } else {
            return error(string `No ResultWatcher with stepId ${stepId}`);
        }
    }
}

isolated function removeResultWatcherFromRegistry(int stepId) returns ResultWatcher|error {
    lock {
        return resultWatcherRegistry.remove(stepId.toString());
    }
}

type TaskDataOutput record {
    string href;
    string dataType;
    string contentType;
    string? name?;
};

type Progress record {|
    float? 'start = 0;
    float? target = 100;
    float? value = ();
    string? unit = "%";
|};

public type TimelineSubstep record {|
    string? stepId;
    string href;
    string? uiHref;
    boolean cleared;
|};

isolated function timelineSubstepToDBTimelineSubstep(TimelineSubstep substep)  returns database:TimelineSubstep {
    string? substepId = substep?.stepId;
    string? uiHref =  substep?.uiHref;
    database:TimelineSubstep converted = {
        substepId: substepId,
        href: substep.href,
        hrefUi: uiHref,
        cleared: (substep.cleared) ? 1: 0
    };

    return converted;
}

type TaskStatusResponse record {
    string status;
    string? taskLog?;
    TaskDataOutput[]? outputs?;
    TimelineSubstep[] steps?;
    Progress progress?;
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

    # Processes intermediate task result for progress and task log updates as well as for timeline substep updates
    #
    # + return - true if timeline substeps were updated (new timeline step added), else false
    public isolated function processIntermediateResult() returns boolean|error {
        boolean isChanged = false;
        transaction {
            check self.saveResultProgressAndLog();
            isChanged = check self.updateResultSubsteps();
            check commit;
        }
        return isChanged;
    }

    private isolated transactional function saveResultProgressAndLog() returns error? {
        Progress? tmpProgress = self.result?.progress;
        database:Progress? progress = ();
        if tmpProgress != () {
            progress = {
                progressStart: tmpProgress.'start,
                progressTarget: tmpProgress.target,
                progressValue: tmpProgress.value,
                progressUnit: tmpProgress.unit
            };
        }
        string? taskLog = self.result?.taskLog;
        if progress != () {
            check database:updateTimelineProgress(self.stepId, progress);
        }
        check database:updateTimelineTaskLog(self.stepId, taskLog);
    }

    private isolated transactional function updateResultSubsteps() returns boolean|error {
        TimelineSubstep[]? receivedSubsteps = self.result?.steps;
        
        boolean isChanged = false;
        if receivedSubsteps != () {
            // write changes in timeline substeps into db
            database:TimelineSubstep[] convertedSubsteps = from var substep in receivedSubsteps
                select timelineSubstepToDBTimelineSubstep(substep);
            isChanged = check database:updateTimelineSubsteps(self.stepId, convertedSubsteps);
        }
        return isChanged;
    }

    public isolated function processResult() returns error? {
        if self.result.status == "SUCCESS" {
            check self.saveSuccessfullResult();
        } else {
            check self.saveErrorResult();
        }
    }

    private isolated function rescheduleResultWatcher('transaction:Info info, error? cause, boolean willRetry) {
        io:println("Rolling back the transaction");
        // compensate by rescheduling the result watcher
        ResultWatcher|error watcher = getResultWatcherFromRegistry(self.stepId);
        if watcher is error {
            io:println(watcher.toString());
        } else {
            // TODO: reschedule result watcher
            // error? unschedule = watcher.reschedule();
            // if unschedule is error {
            //     io:println(unschedule.toString());
            // }
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
                    io:println(string `Error during deletion of file ${processed.location}, while compensating on error importing result for step ${self.stepId}!`, compensationError);
                }
            }
        }
        self.rescheduleResultWatcher(info, cause, willRetry);
    }

    private isolated function saveSuccessfullResult() returns error? {
        var outputs = self.result?.outputs;

        transaction {
            // save progress and task log
            check self.saveResultProgressAndLog();
            // update substeps one last time
            _ = check self.updateResultSubsteps();

            // compensate for file creation outside of transaction control
            'transaction:onRollback(self.compensateFileCreation);

            // process task output data
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
                            'type: output.dataType,
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
            'transaction:onRollback(self.rescheduleResultWatcher);
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
    private final string & readonly resultEndpoint;
    private int errorCounter;
    private task:JobId? jobId = ();
    private decimal[] scheduleIntervals = [5];
    private int[] backoffCounters = [];
    private int? currentBackoffCounter = ();

    public isolated function execute() {
        int currentErrorCounter;
        lock {
            currentErrorCounter = self.errorCounter;
        }
        if currentErrorCounter > 5 {
            io:println(string `Unscheduling watcher for step ${self.stepId} because of repeated errors.`);
            var err = self.unschedule();
            if err is error {
                io:println(string `Failed to unsubscribe step result watcher for step ${self.stepId}`, err);
            } else {
                // not sure if this is needed here
                var err2 = removeResultWatcherFromRegistry(self.stepId);
                if err2 is error {
                    io:println(string `Failed to remove result watcher from registry for step ${self.stepId}`, err2);
                }
            }
        }

        // request specified endpoint
        TaskStatusResponse|error result = self.httpClient->get("");
        if result is error {
            lock {
                self.errorCounter += 1;
            }
            io:println(result);
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
                        io:println(string `Unschedule watcher ${self.stepId} after running out of watching attempts.`);
                        check self.unschedule();
                        _ = check removeResultWatcherFromRegistry(self.stepId);
                        io:println(`finally finish executing job for step ${self.stepId}`);
                        return;
                    } else {
                        check self.reschedule(newInterval);
                    }
                } on fail error err {
                    lock {
                        self.errorCounter += 1;
                    }
                    io:println(err);
                }
            }
        }
    }

    private isolated function reschedule(decimal interval) returns error? {
        error? err = self.unschedule();

        if (err != ()) {
            if err.message().startsWith("Invalid job id:") {
                // ignore error, but print it
                io:println(err);
            } else {
                return err;
            }
        }

        lock {
            self.jobId = check task:scheduleJobRecurByFrequency(self, interval);
            io:println(string `Scheduled watcher for step ${self.stepId} with interval ${interval}. JobId: ${self.jobId.toString()}`);
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
    public isolated function schedule(decimal|int... intervals) returns error? {
        if intervals.length() <= 0 {
            return error("Must specify at least one inteval!");
        }
        decimal[] scheduleIntervals = [];
        int[] backoffCounters = [];
        foreach int i in 0 ..< intervals.length() {
            if i % 2 == 0 {
                scheduleIntervals.push(<decimal>intervals[i]);
            } else {
                var counter = intervals[i];
                if counter is int {
                    backoffCounters.push(counter);
                } else {
                    backoffCounters.push(<int>counter.ceiling());
                }
            }
        }

        lock {
            self.scheduleIntervals = scheduleIntervals.clone().reverse();
            self.backoffCounters = backoffCounters.clone().reverse();

            var startingIntervall = self.scheduleIntervals.pop(); // list always contains >1 entries at this point (see guard at top)
            self.currentBackoffCounter = self.backoffCounters.length() > 0 ? self.backoffCounters.pop() : ();

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
            io:println(string `Unscheduled watcher for step ${self.stepId}. JobId: ${jobId.toString()}`);
        }
    }

    private isolated function checkTaskResult(TaskStatusResponse result) {
        if result.status == "UNKNOWN" || result.status == "PENDING" {
            do {
                ResultProcessor processor = new (result, self.experimentId, self.stepId, self.resultEndpoint);
                boolean isChanged = check processor.processIntermediateResult();
                if isChanged {
                    io:println(string `Reschedule watcher ${self.stepId} after new substep was found.`);
                    // TODO: Probably needs to be changed in the future
                    (decimal|int)[] initialIntervals = [2, 10, 5, 10, 10, 60, 30, 20, 60, 10, 600];
                    check self.schedule(...initialIntervals);
                }
            } on fail error e {
                lock {
                    self.errorCounter += 1;
                }
                io:println(e);
            }
        } else {
            do {
                ResultProcessor processor = new (result, self.experimentId, self.stepId, self.resultEndpoint);
                check processor.processResult();
                io:println(string `Unschedule watcher ${self.stepId} after result was saved.`);
                check self.unschedule();
                _ = check removeResultWatcherFromRegistry(self.stepId);
            } on fail error e {
                lock {
                    self.errorCounter += 1;
                }
                io:println(e);
            }
        }
    }

    isolated function init(int stepId) returns error? {
        self.errorCounter = 0;

        self.stepId = stepId;

        string? resultEndpoint;

        if transactional {
            resultEndpoint = check database:getTimelineStepResultEndpoint(stepId);
            var step = check database:getTimelineStep(stepId = stepId);
            self.experimentId = step.experimentId;
        } else {
            transaction {
                resultEndpoint = check database:getTimelineStepResultEndpoint(stepId);
                var step = check database:getTimelineStep(stepId = stepId);
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
        addResultWatcherToRegistry(self); // TODO: perhaps refactor into helper function creating watcher and adding it into registry
    }
}

isolated function prepareStorageLocation(int experimentId) returns string|error {
    var relPath = check file:joinPath(storageLocation, string `${experimentId}`);
    var normalizedPath = check file:normalizePath(relPath, file:CLEAN);
    var abspath = check file:getAbsolutePath(normalizedPath);
    check file:createDir(abspath, file:RECURSIVE);
    return abspath;
}
