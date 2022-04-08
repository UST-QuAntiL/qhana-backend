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
import ballerina/io;
import ballerina/regex;
import ballerina/os;
import qhana_backend.database;

// start configuration values
configurable string[] corsDomains = ["http://localhost:4200"];

function getCorsDomains() returns string[] {
    string d = os:getEnv("QHANA_CORS_DOMAINS");
    if (d.length() > 0) {
        return regex:split(d, "[\\s]+");
    }
    return corsDomains;
}

final string[]&readonly configuredCorsDomains = getCorsDomains().cloneReadOnly();

configurable int port = 9090;

function getPort() returns int {
    string p = os:getEnv("QHANA_PORT");
    if (regex:matches(p, "^[0-9]+$")) {
        do {
            return check int:fromString(p);
        } on fail error err {
            // error should never happen if regex is correct...
        }
    }
    return port;
}

final int&readonly serverPort = getPort().cloneReadOnly();

configurable (decimal|int)[] watcherIntervallConfig = [2, 10, 5, 10, 10, 60, 30, 20, 60, 10, 600];

function coerceToPositiveNumber(string input) returns decimal|int|error {
    boolean isDecimal = regex:matches(input, "^[0-9]+\\.[0-9]+$");
    if (isDecimal) {
        return decimal:fromString(input);
    }
    boolean isInt = regex:matches(input, "^[0-9]+$");
    if (isInt) {
        return int:fromString(input);
    }
    return error(string`Input "${input}" is not a positive number!`);
}

function getWatcherIntervallConfig() returns (decimal|int)[] {
    string intervalls = os:getEnv("QHANA_WATCHER_INTERVALLS");
    if (intervalls.length() > 0) {
        do {
            return from string i in regex:split(intervalls, "[\\s\\(\\),;]+")
                select check coerceToPositiveNumber(i);
        } on fail error err {
            io:println("Failed to parse environment variable QHANA_WATCHER_INTERVALLS!\n", err);
        }
    }
    return watcherIntervallConfig;
}

final (decimal|int)[]&readonly configuredWatcherIntervalls = getWatcherIntervallConfig().cloneReadOnly();

// URL map that can be used to map plugin endpoint watcher urls t URLs reachable for the backend
// Intended for use in a dockerized dev setup where localhost is used as outside URL
configurable map<string> & readonly internalUrlMap = {};

function getInternalUrlMap() returns map<string> {
    string mapping = os:getEnv("QHANA_URL_MAPPING");
    if (mapping.length() > 0) {
        do {
            return check mapping.fromJsonStringWithType();
        } on fail error err {
            io:println("Failed to parse environment variable QHANA_URL_MAPPING!\n", err);
        }
    }
    map<string> newMapping = {};
    foreach var [key, value] in internalUrlMap.entries() {
        if key[0] == "\"" || key[0] == "'" {
            // remove enclosing quotes if necessary
            // FIXME: This is a workaround for a possible bug in Ballerina. Can be removed if the bug is fixed.
            var strippedKey = key.substring(1, key.length() - 1);
            newMapping[strippedKey] = value;
        } else {
            newMapping[key] = value;
        }
    }
    return newMapping;
}

final map<string> & readonly configuredUrlMap = getInternalUrlMap().cloneReadOnly();
// end configuration values

isolated function mapToInternalUrl(string url) returns string {
    if configuredUrlMap.length() == 0 {
        return url; // fast exit
    }
    // apply all replacements specified in the url map, keys are interpreted as regex
    var replacedUrl = url;
    foreach var [pattern, replacement] in configuredUrlMap.entries() {
        replacedUrl = regex:replaceFirst(replacedUrl, pattern, replacement);
    }
    return replacedUrl;
}

# The QHAna backend api service.
@http:ServiceConfig {
    cors: {
        allowOrigins: configuredCorsDomains,
        allowMethods: ["OPTIONS", "GET", "PUT", "POST", "DELETE"],
        allowHeaders: ["Content-Type", "Depth", "User-Agent", "X-File-Size", "X-Requested-With", "If-Modified-Since", "X-File-Name", "Cache-ControlAccess-Control-Allow-Origin"],
        allowCredentials: true,
        maxAge: 84900
    }
}
service / on new http:Listener(serverPort) {
    resource function get .() returns RootResponse {
        return {
            '\@self: "/",
            experiments: "/experiments/",
            pluginRunners: "/pluginRunners/",
            tasks: "/tasks/"
        };
    }

    resource function get plugin\-endpoints() returns PluginEndpointsListResponse|http:InternalServerError {
        int endpointCount;
        database:PluginEndpointFull[] endpoints;

        transaction {
            endpointCount = check database:getPluginEndpointsCount();
            endpoints = check database:getPluginEndpoints();
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var result = from var endpoint in endpoints
            select mapToPluginEndpointResponse(endpoint);
        // FIXME load from database...
        return {
            '\@self: "/plugin-endpoints",
            items: result,
            itemCount: endpointCount
        };
    }

    resource function post plugin\-endpoints(@http:Payload PluginEndpointPost endpoint) returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:addPluginEndpoint(endpoint);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    resource function get plugin\-endpoints/[int endpointId]() returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:getPluginEndpoint(endpointId);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    resource function put plugin\-endpoints/[int endpointId](@http:Payload PluginEndpointPost endpoint) returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:editPluginEndpoint(endpointId, endpoint.'type);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    resource function delete plugin\-endpoints/[int endpointId]() returns http:Ok|http:InternalServerError {
        transaction {
            check database:deletePluginEndpoint(endpointId);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    ////////////////////////////////////////////////////////////////////////////
    // Experiments /////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    resource function get experiments(string? page, string? 'item\-count) returns ExperimentListResponse|http:InternalServerError {
        int experimentCount;
        database:ExperimentFull[] experiments;

        transaction {
            experimentCount = check database:getExperimentCount();
            experiments = check database:getExperiments();
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        // map to api response(s)
        var result = from var exp in experiments
            select mapToExperimentResponse(exp);
        return {'\@self: string `/experiments/`, items: result, itemCount: experimentCount};
    }

    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function post experiments(@http:Payload database:Experiment experiment) returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:createExperiment(experiment);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    resource function get experiments/[int experimentId]() returns ExperimentResponse|http:InternalServerError|error {
        database:ExperimentFull result;
        transaction {
            result = check database:getExperiment(experimentId);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function put experiments/[int experimentId](@http:Payload database:Experiment experiment) returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:updateExperiment(experimentId, experiment);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Data ////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    resource function get experiments/[int experimentId]/data\-summary() returns map<string[]>|http:InternalServerError {
        
        map<string[]> data;

        transaction {
            data = check database:getDataTypesSummary(experimentId);
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        return data;
    }

    resource function get experiments/[int experimentId]/data(boolean? allVersions, int page=0, int item\-count=0) returns ExperimentDataListResponse|http:NotFound|http:InternalServerError|http:BadRequest {
        boolean includeAllVersions = allVersions == true || allVersions == ();

        if (page < 0) {
            return <http:BadRequest>{body: "Cannot retrieve a negative page number!"};
        }

        if (item\-count < 5 || item\-count > 500) {
            return <http:BadRequest>{body: "Item count must be between 5 and 500 (both inclusive)!"};
        }

        var offset = page*item\-count;

        int dataCount;
        database:ExperimentDataFull[] data;

        transaction {
            dataCount = check database:getExperimentDataCount(experimentId, all=includeAllVersions);
            if (offset >= dataCount) {
                // page is out of range!
                check commit;
                return <http:NotFound>{};
            } else {
                data = check database:getDataList(experimentId, all=includeAllVersions, 'limit=item\-count, offset=offset);
                check commit;
            }
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var dataList = from var d in data
            select mapToExperimentDataResponse(d);
        return {'\@self: string `/experiments/${experimentId}/data/?allVersions=${includeAllVersions}`, items: dataList, itemCount: dataCount};
    }

    resource function get experiments/[int experimentId]/data/[string name](string? 'version) returns ExperimentDataResponse|http:InternalServerError {
        database:ExperimentDataFull data;
        int? producingStep;
        int[]? inputFor;

        transaction {
            data = check database:getData(experimentId, name, 'version);
            producingStep = check database:getProducingStepOfData(data);
            inputFor = check database:getStepsUsingData(data);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentDataResponse(data, producingStep, inputFor);
    }

    resource function get experiments/[int experimentId]/data/[string name]/download(string? 'version, http:Caller caller) returns error? {
        database:ExperimentDataFull data;

        http:Response resp = new;

        transaction {
            data = check database:getData(experimentId, name, 'version);
            check commit;
        } on fail error err {
            io:println(err);

            resp.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            resp.setPayload("Something went wrong. Please try again later.");

            check caller->respond(resp);
        }

        resp.statusCode = http:STATUS_OK;
        var cType = data.contentType;
        if cType.startsWith("text/") || cType.startsWith("application/json") || cType.startsWith("application/X-lines+json") {
            resp.addHeader("Content-Disposition", string `inline; filename="${data.name}"`);
        } else {
            resp.addHeader("Content-Disposition", string `attachment; filename="${data.name}"`);
        }
        resp.setFileAsPayload(data.location, contentType = data.contentType);

        check caller->respond(resp);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Timeline ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    resource function get experiments/[int experimentId]/timeline(int page=0, int item\-count=0) returns TimelineStepListResponse|http:BadRequest|http:NotFound|http:InternalServerError {
        if (page < 0) {
            return <http:BadRequest>{body: "Cannot retrieve a negative page number!"};
        }

        if (item\-count < 5 || item\-count > 500) {
            return <http:BadRequest>{body: "Item count must be between 5 and 500 (both inclusive)!"};
        }

        var offset = page*item\-count;

        int stepCount;
        database:TimelineStepFull[] steps;

        transaction {
            stepCount = check database:getTimelineStepCount(experimentId);
            if (offset >= stepCount) {
                // page is out of range!
                check commit;
                return <http:NotFound>{};
            } else {
                steps = check database:getTimelineStepList(experimentId, 'limit=item\-count, offset=offset);
                check commit;
            }
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var stepList = from var s in steps
            select mapToTimelineStepMinResponse(s);
        return {'\@self: string `/experiments/${experimentId}/timeline`, items: stepList, itemCount: stepCount};
    }

    resource function post experiments/[int experimentId]/timeline(@http:Payload TimelineStepPost stepData) returns TimelineStepResponse|http:InternalServerError {
        database:TimelineStepWithParams createdStep;
        database:ExperimentDataReference[] inputData;

        transaction {
            inputData = check trap from var inputUrl in stepData.inputData
                select checkpanic mapFileUrlToDataRef(experimentId, inputUrl); // FIXME move back to check if https://github.com/ballerina-platform/ballerina-lang/issues/34894 is resolved
            createdStep = check database:createTimelineStep(
                experimentId = experimentId,
                parameters = stepData.parameters,
                parametersContentType = stepData.parametersContentType,
                processorName = stepData.processorName,
                processorVersion = stepData.processorVersion,
                processorLocation = stepData.processorLocation
            );
            check database:saveTimelineStepInputData(createdStep.stepId, experimentId, inputData);
            check database:createTimelineStepResultWatcher(createdStep.stepId, mapToInternalUrl(stepData.resultLocation));
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        do {
            ResultWatcher watcher = check new (createdStep.stepId);
            check watcher.schedule(...configuredWatcherIntervalls);
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Failed to start watcher."};
            return resultErr;
        }
        return mapToTimelineStepResponse(createdStep, (), inputData, []);
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]() returns TimelineStepResponse|http:InternalServerError {
        database:TimelineStepWithParams result;
        database:ExperimentDataReference[] inputData;
        database:ExperimentDataReference[] outputData;
        database:TimelineSubstepSQL[] substeps;
        transaction {
            result = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStep);
            inputData = check database:getStepInputData(result);
            outputData = check database:getStepOutputData(result);
            // duplicates input data for substeps, but overhead is negligible 
            substeps = check database:getTimelineSubstepsWithInputData(timelineStep);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToTimelineStepResponse(result, substeps, inputData, outputData);
    }

    resource function put experiments/[int experimentId]/timeline/[int timelineStep](@http:Payload TimelineStepResultQualityPut resultQuality) returns http:Ok|http:BadRequest|http:InternalServerError {
        string rq = resultQuality.resultQuality;
        if rq != "UNKNOWN" && rq != "NEUTRAL" && rq != "GOOD" && rq != "BAD" && rq != "ERROR" && rq != "UNUSABLE" {
            return <http:BadRequest>{body: "Result quality must be one of the following values: 'UNKNOWN', 'NEUTRAL', 'GOOD', 'BAD', 'ERROR', or 'UNUSABLE'."};
        }
        transaction {
            check database:updateTimelineStepResultQuality(experimentId, timelineStep, resultQuality.resultQuality);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]/notes() returns TimelineStepNotesResponse|http:InternalServerError {
        string result;

        transaction {
            result = check database:getTimelineStepNotes(experimentId, timelineStep);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return {
            '\@self: string `/experiments/${experimentId}/timeline/${timelineStep}/notes`,
            notes: result
        };
    }

    resource function put experiments/[int experimentId]/timeline/[int timelineStep]/notes(@http:Payload TimelineStepNotesPost notes) returns http:Ok|http:InternalServerError {
        transaction {
            check database:updateTimelineStepNotes(experimentId, timelineStep, notes.notes);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    resource function post experiments/[int experimentId]/timeline/[int timelineStep]/substeps/[int substepNr](@http:Payload TimelineSubstepPost substepData) returns TimelineSubstepResponse|http:InternalServerError {
        database:TimelineStepWithParams step;
        database:TimelineSubstepWithParams substep;
        database:ExperimentDataReference[] inputData;

        transaction {
            inputData = check trap from var inputUrl in substepData.inputData
                select checkpanic mapFileUrlToDataRef(experimentId, inputUrl); // FIXME move back to check if https://github.com/ballerina-platform/ballerina-lang/issues/34894 is resolved
            step = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStep);
            // verify that substep is in database
            substep = check database:getTimelineSubstepWithParams(step.stepId, substepNr);
            // save input data and update progress
            check database:saveTimelineSubstepParams(step.stepId, substepNr, substepData.parameters, substepData.parametersContentType);
            check database:saveTimelineSubstepInputData(step.stepId, substepNr, experimentId, inputData);
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        do {
            // reschedule result watcher (already running for the timeline step the substep is associated with)
            ResultWatcher watcher;
            lock {
                watcher = check getResultWatcherFromRegistry(step.stepId);
            }
            check watcher.unschedule();
            check watcher.schedule(...configuredWatcherIntervalls);
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Failed to restart watcher."};
            return resultErr;
        }
        return mapToTimelineSubstepResponse(experimentId, substep, inputData);
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]/substeps() returns TimelineSubstepListResponse|http:InternalServerError {
        // no pagination
        database:TimelineSubstepSQL[] steps;

        transaction {
            steps = check database:getTimelineSubsteps(timelineStep);
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        return {'\@self: string `/experiments/${experimentId}/timeline`, items: steps};
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]/substeps/[int substepNr]() returns TimelineSubstepResponse|http:InternalServerError {
        database:TimelineSubstepWithParams step;
        database:ExperimentDataReference[] inputData;

        transaction {
            step = check database:getTimelineSubstepWithParams(timelineStep, substepNr);
            inputData = check database:getSubstepInputData(step.stepId, step.substepNr);
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        return mapToTimelineSubstepResponse(experimentId, step, inputData);
    }
}

public function main() {
    // registering background tasks
    transaction {
        var stepsToWatch = check database:getTimelineStepsWithResultWatchers();
        foreach var stepId in stepsToWatch {
            ResultWatcher watcher = check new (stepId);
            check watcher.schedule(...configuredWatcherIntervalls);
        }
        check commit;
    } on fail error err {
        io:println(err);
    }
}
