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
import ballerina/log;
import ballerina/os;
import ballerina/uuid;
import ballerina/time;
import qhana_backend.database;

// start configuration values
# Path to where the backend should store experiment data at.
# Can also be configured by setting the `QHANA_STORAGE_LOCATION` environment variable.
configurable string storageLocation = "experimentData";

# Get the storage location from the `QHANA_STORAGE_LOCATION` environment variable.
# If not present use the configurable variable `storageLocation` as fallback.
#
# + return - the configured cors domains
function getStorageLocation() returns string {
    string location = os:getEnv("QHANA_STORAGE_LOCATION");
    if (location.length() > 0) {
        return location;
    }
    return storageLocation;
}

# The final configured storage location.
final string & readonly configuredStorageLocation = getStorageLocation().cloneReadOnly();
// end configuration values

# A map from stepId to active result watchers
isolated map<ResultWatcher> resultWatcherRegistry = {};

# Add a new result watcher to the registry map.
#
# + watcher - the watcher to add
isolated function addResultWatcherToRegistry(ResultWatcher watcher) {
    lock {
        resultWatcherRegistry[watcher.stepId.toString()] = watcher;
    }
}

# Get a result watcher from the registry map.
#
# + stepId - the database id of the step (not its sequence number!)
# + return - the result watcher or an error
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

# Remove a result watcher from the registry map.
#
# + stepId - the database id of the step (not its sequence number!)
# + return - the removed result watcher or an error
isolated function removeResultWatcherFromRegistry(int stepId) returns ResultWatcher|error {
    lock {
        return resultWatcherRegistry.remove(stepId.toString());
    }
}

# Record describing output data of a task result.
#
# + href - the link to the output data
# + dataType - the data type tag of the output data
# + contentType - the content type describing the serialization format of the output data
# + name - the (file-)name of the output data
type TaskDataOutput record {
    string href;
    string dataType;
    string contentType;
    string? name?;
};

# Result progress record.
#
# + start - the start value of the progress (defaults to 0)
# + target - the target value, e.g., the value where the progress is considered 100% done (defaults to 100)
# + value - the current progress value
# + unit - the unit the progress is counted in, e.g., %, minutes, steps, error rate, etc. (defaults to "%")
type Progress record {|
    float? 'start = 0;
    float? target = 100;
    float? value = ();
    string? unit = "%";
|};

# Record for timeline substeps.
#
# + stepId - the database id of the step this is a substep of (not the sequence number!)
# + href - the URL to the API endpoint corresponding to that substep
# + uiHref - the URL of the micro frontend corresponding to that substep
# + cleared - a boolean flag indicating that this substep is cleared
public type TimelineSubstep record {|
    string? stepId;
    string href;
    string? uiHref;
    boolean cleared;
|};

# Helper function to convert `TimelineSubstep` records to db records.
#
# + substep - the input record
# + return - the mapped record
isolated function timelineSubstepToDBTimelineSubstep(TimelineSubstep substep) returns database:TimelineSubstep {
    string? substepId = substep?.stepId;
    string? uiHref = substep?.uiHref;
    database:TimelineSubstep converted = {
        substepId: substepId,
        href: substep.href,
        hrefUi: uiHref,
        cleared: (substep.cleared) ? 1 : 0
    };

    return converted;
}

# Record describing the pending task result and status resource.
#
# + status - a string describing the current task status
# + taskLog - a human readable log of the task progress
# + outputs - a list of data outputs once the task is finished
# + steps - a list of substeps of the current task
# + progress - the current progress of the task
type TaskStatusResponse record {
    string status;
    string? taskLog?;
    TaskDataOutput[]? outputs?;
    TimelineSubstep[] steps?;
    Progress progress?;
};

# Class containing methods to process the task results with transaction semantics.
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

    # Save the task log and the progress to the database.
    #
    # + return - any error
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

    # Save updates of the steps list in the pending result as substeps in the database.
    #
    # + return - any error
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

    # Process the set result as a concluded result, i.e., a finished or failed result.
    #
    # + return - an error if processing the result has failed
    public isolated function processResult() returns error? {
        if self.result.status == "SUCCESS" {
            check self.saveSuccessfullResult();
        } else {
            check self.saveErrorResult();
        }
    }

    # Reschedule the result watcher on a transaction rollback.
    #
    # + info - the asociated transaction info
    # + cause - the cause of the transaction rollback
    # + willRetry - whether the transaction will be retried
    private isolated function rescheduleResultWatcher('transaction:Info info, error? cause, boolean willRetry) {
        log:printError("Rolling back the transaction");
        // compensate by rescheduling the result watcher
        ResultWatcher|error watcher = getResultWatcherFromRegistry(self.stepId);
        if watcher is error {
            log:printError("Unable to get result watcher", 'error = watcher, stackTrace = watcher.stackTrace());
        } else {
            // TODO: reschedule result watcher
            // error? unschedule = watcher.reschedule();
            // if unschedule is error {
            //     log:printError(unschedule.toString());
            // }
        }
    }

    # Compensate any file creation by deleting the created files again on transaction rollback.
    #
    # + info - the asociated transaction info
    # + cause - the cause of the transaction rollback
    # + willRetry - whether the transaction will be retried
    private isolated function compensateFileCreation('transaction:Info info, error? cause, boolean willRetry) {
        log:printError("Rolling back the transaction");
        // compensate by deleting unused files
        lock {
            foreach var processed in self.processedOutputs {
                do {
                    if check file:test(processed.location, file:EXISTS) {
                        check file:remove(processed.location);
                    }
                } on fail var compensationError {
                    // TODO actual error logging (and periodic cleanup job looking for files not in a database)
                    log:printError(string `Error during deletion of file ${processed.location}, while compensating on error importing result for step ${self.stepId}!`, 'error = compensationError, stackTrace = compensationError.stackTrace());
                }
            }
        }
        self.rescheduleResultWatcher(info, cause, willRetry);
    }

    # Save a successfull result to the database.
    #
    # + return - any error
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
                        // save data for compensation action on transaction rollback
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

    # Save an error result to the database.
    #
    # + return - any error
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

# Task to reschedule the result watcher.
#
# This is in an extra task to be able to delay the rescheduling.
isolated class ResultWatcherRescheduler {

    *task:Job;

    private final ResultWatcher watcher;

    # Set the result watcher instance that will be rescheduled
    #
    # + watcher - the result watcher to reschedule
    isolated function init(ResultWatcher watcher) {
        self.watcher = watcher;
    }

    # The rescheduling logic.
    public isolated function execute() {
        log:printInfo(string `Reschedule watcher ${self.watcher.stepId} after new substep was found.`);
        // TODO: Probably needs to be changed in the future
        (decimal|int)[] initialIntervals = configuredWatcherIntervalls;
        error? err = self.watcher.schedule(...initialIntervals);
        if err != () {
            log:printError("Failed to reschedule watcher.", 'error = err, stackTrace = err.stackTrace());

        }
    }
}

# A background job that polls the configured result endpoint.
#
# The watcher can reschedule itself to be slower if no changes happened for some time.
# If 5 errors happen for consecutive requests then the watcher will unschedule itself completely.
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
            log:printError(string `Unscheduling watcher for step ${self.stepId} because of repeated errors.`);
            var err = self.unschedule();
            if err is error {
                log:printError(string `Failed to unsubscribe step result watcher for step ${self.stepId}`, 'error = err, stackTrace = err.stackTrace());
            } else {
                // not sure if this is needed here
                var err2 = removeResultWatcherFromRegistry(self.stepId);
                if err2 is error {
                    log:printError(string `Failed to remove result watcher from registry for step ${self.stepId}`, 'error = err2, stackTrace = err2.stackTrace());

                }
            }
        }

        // request specified endpoint
        TaskStatusResponse|error result = self.httpClient->get("");
        if result is error {
            lock {
                self.errorCounter += 1;
            }
            log:printError("Could not get task status response.", 'error = result, resultEndpoint = self.resultEndpoint, stackTrace = result.stackTrace());

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
                    int? maxRuns = -1;
                    lock {
                        newInterval = self.scheduleIntervals.length() > 0 ? self.scheduleIntervals.pop() : ();
                        self.currentBackoffCounter = self.backoffCounters.length() > 0 ? self.backoffCounters.pop() : ();
                        maxRuns = self.currentBackoffCounter;
                    }
                    if newInterval == () {
                        log:printInfo(string `Unschedule watcher ${self.stepId} after running out of watching attempts.`);
                        check self.unschedule();
                        _ = check removeResultWatcherFromRegistry(self.stepId);
                        log:printInfo(string `finally finish executing job for step ${self.stepId}`);
                        return;
                    } else {
                        check self.reschedule(newInterval, (maxRuns == ()) ? -1 : maxRuns + 1);
                    }
                } on fail error err {
                    lock {
                        self.errorCounter += 1;
                    }
                    log:printError("Rescheduling failed.", 'error = err, stackTrace = err.stackTrace());
                }
            }
        }
    }

    # Unschedule the current repeating task and schedule self again with the new intervall.
    #
    # + interval - the time in seconds
    # + maxCount - how often the task will be repeated max (-1 for infinite repeats)
    # + return - any error
    private isolated function reschedule(decimal interval, int maxCount = -1) returns error? {
        error? err = self.unschedule();

        if (err != ()) {
            if err.message().startsWith("Invalid job id:") {
                // ignore error, but print it
                log:printError("Unscheduling failed.", 'error = err, stackTrace = err.stackTrace());
            } else {
                return err;
            }
        }

        time:Utc delay = time:utcAddSeconds(time:utcNow(), interval);

        lock {
            // initial delay of new job matches new interval (this prevents the job from executing immediately)
            time:Civil delayCivil = time:utcToCivil(delay.clone());
            self.jobId = check task:scheduleJobRecurByFrequency(self, interval, maxCount, delayCivil);
            log:printInfo(string `Scheduled watcher for step ${self.stepId} with interval ${interval}. JobId: ${self.jobId.toString()}`);
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

            int? maxRuns = self.currentBackoffCounter;

            check self.reschedule(startingIntervall, (maxRuns == ()) ? -1 : maxRuns + 1);
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
            log:printInfo(string `Unscheduled watcher for step ${self.stepId}. JobId: ${jobId.toString()}`);
        }
    }

    # Check the new result resource and handle it according to its status.
    #
    # + result - the result to check
    private isolated function checkTaskResult(TaskStatusResponse result) {
        do {
            if result.status == "UNKNOWN" || result.status == "PENDING" {
                ResultProcessor processor = new (result, self.experimentId, self.stepId, self.resultEndpoint);
                boolean isChanged = check processor.processIntermediateResult();
                if isChanged {
                    // if new subtasks were found, reschedule to poll more frequently again
                    var _ = check task:scheduleOneTimeJob(new ResultWatcherRescheduler(self), time:utcToCivil(time:utcAddSeconds(time:utcNow(), 1)));
                }
            } else {
                // result has concluded/is no longer pending
                ResultProcessor processor = new (result, self.experimentId, self.stepId, self.resultEndpoint);
                check processor.processResult();
                log:printInfo(string `Unschedule watcher ${self.stepId} after result was saved.`);
                check self.unschedule();
                _ = check removeResultWatcherFromRegistry(self.stepId);
            }
        } on fail error e {
            lock {
                self.errorCounter += 1;
            }
            log:printError("Failed to check task result.", 'error = e, stackTrace = e.stackTrace());
        }
    }

    # Initialize the result watcher task.
    #
    # + stepId - the database id of the step to watch
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

# Prepare the storage location and make sure that the folder exists.
#
# + experimentId - the id of the experiment to create a folder for
# + return - the folder to store experiment data in
isolated function prepareStorageLocation(int experimentId) returns string|error {
    var relPath = check file:joinPath(storageLocation, string `${experimentId}`);
    var normalizedPath = check file:normalizePath(relPath, file:CLEAN);
    var abspath = check file:getAbsolutePath(normalizedPath);
    check file:createDir(abspath, file:RECURSIVE);
    return abspath;
}
