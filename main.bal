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
import qhana_backend.database;


configurable string[] corsDomains = ["http://localhost:4200"];
configurable int port = 9090;

configurable (decimal|int)[] watcherIntervallConfig = [2, 10, 5, 10, 10, 60, 30, 20, 60, 10, 600];

// URL map that can be used to map plugin endpoint watcher urls t URLs reachable for the backend
// Intended for use in a dockerized dev setup where localhost is used as outside URL
configurable map<string>&readonly internalUrlMap = {};

isolated function mapToInternalUrl(string url) returns string {
    if internalUrlMap.length() == 0 {
        return url; // fast exit
    }
    // apply all replacements specified in the url map, keys are interpreted as regex
    var replacedUrl = url;
    foreach var key in internalUrlMap {
        replacedUrl = regex:replaceFirst(url, key, internalUrlMap.get(key));
    }
    return replacedUrl;
}

# The QHAna backend api service.
@http:ServiceConfig {
    cors: {
        allowOrigins: corsDomains,
        allowMethods: ["OPTIONS", "GET", "PUT", "POST", "DELETE"],
        allowHeaders: ["Content-Type", "Depth", "User-Agent", "X-File-Size", "X-Requested-With", "If-Modified-Since", "X-File-Name", "Cache-ControlAccess-Control-Allow-Origin"],
        allowCredentials: true,
        maxAge: 84900
    }
}
service / on new http:Listener(port) {
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
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    resource function delete plugin\-endpoints/[int endpointId]() returns http:Ok|http:InternalServerError {
        error? result;
        transaction {
            result = check database:deletePluginEndpoint(endpointId);
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
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function update experiments/[int experimentId](@http:Payload database:Experiment experiment) returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:updateExperiment(experimentId, experiment);
            check commit;
        } on fail error err {
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Data ////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    resource function get experiments/[int experimentId]/data(boolean? allVersions) returns ExperimentDataListResponse|http:InternalServerError {
        boolean includeAllVersions = allVersions == true || allVersions == ();

        int dataCount;
        database:ExperimentDataFull[] data;

        transaction {
            dataCount = check database: getExperimentDataCount(experimentId, all=includeAllVersions);
            data = check database:getDataList(experimentId, all=includeAllVersions);
            check commit;
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
            io:println(data);
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
        if cType.startsWith("text/") || cType.startsWith("application/json") || cType.startsWith("application/X-lines+json"){
            resp.addHeader("Content-Disposition", string`inline; filename="${data.name}"`);
        } else {
            resp.addHeader("Content-Disposition", string`attachment; filename="${data.name}"`);
        }
        resp.setFileAsPayload(data.location, contentType=data.contentType);

        check caller->respond(resp);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Timeline ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    resource function get experiments/[int experimentId]/timeline() returns TimelineStepListResponse|http:InternalServerError {
        int stepCount;
        database:TimelineStepFull[] steps;

        transaction {
            stepCount = check database:getTimelineStepCount(experimentId);
            steps = check database:getTimelineStepList(experimentId);
            check commit;
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
            inputData = from var inputUrl in stepData.inputData
                        select check mapFileUrlToDataRef(experimentId, inputUrl);
            createdStep = check database:createTimelineStep(
                experimentId=experimentId,
                parameters=stepData.parameters,
                parametersContentType=stepData.parametersContentType,
                parametersDescriptionLocation=stepData.parametersDescriptionLocation,
                processorName=stepData.processorName,
                processorVersion=stepData.processorVersion,
                processorLocation=stepData.processorLocation
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
            check watcher.schedule(...watcherIntervallConfig);
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Failed to start watcher."};
            return resultErr;
        }
        return mapToTimelineStepResponse(createdStep, inputData, []);
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]() returns TimelineStepResponse|http:InternalServerError {
        database:TimelineStepWithParams result;
        database:ExperimentDataReference[] inputData;
        database:ExperimentDataReference[] outputData;
        
        transaction {
            result = check database:getTimelineStep(experimentId=experimentId, sequence=timelineStep);
            inputData = check database:getStepInputData(result);
            outputData = check database:getStepOutputData(result);
            check commit;
        } on fail error err {
            io:println(err);
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToTimelineStepResponse(result, inputData, outputData);
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
}


public function main() {
    // registering background tasks
    transaction {
        var stepsToWatch = check database:getTimelineStepsWithResultWatchers();
        foreach var stepId in stepsToWatch {
            ResultWatcher watcher = check new (stepId);
            check watcher.schedule(...watcherIntervallConfig);
        }
        check commit;
    } on fail error err {
        io:println(err);
    }
}
