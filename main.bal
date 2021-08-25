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
import qhana_backend.database;


configurable string[] corsDomains = ["http://localhost:4200"];
configurable int port = 9090;

# The QHAna backend api service.
@http:ServiceConfig {
    cors: {
        allowOrigins: corsDomains,
        allowMethods: ["OPTIONS", "GET", "PUT", "POST", "DELETE"],
        //allowCredentials: false,
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

    resource function get plugin\-runners() returns PluginRunnersListResponse {
        // FIXME load from database...
        return {
            '\@self: "/plugin-runners",
            items: ["http://localhost:5005"],
            itemCount: 1
        };
    }
    resource function get tasks/[string taskId]() returns http:Ok {
        return {};
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
            check database:createTimelineStepResultWatcher(createdStep.stepId, stepData.resultLocation);
            check commit;
        } on fail error err {
            io:println(err);
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        do {
            ResultWatcher watcher = check new (createdStep.stepId);
            check watcher.schedule(2, 10, 5, 10, 30, 5, 60, 5, 600);
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
    resource function put experiments/[int experimentId]/timeline/[int timelineStep]/notes() returns http:Ok {
        return {};
    }
}


public function main() {
    // registering background tasks
    transaction {
        var stepsToWatch = check database:getTimelineStepsWithResultWatchers();
        foreach var stepId in stepsToWatch {
            ResultWatcher watcher = check new (stepId);
            check watcher.schedule(2, 10, 5, 10, 30, 5, 60, 5, 600);
        }
        check commit;
    } on fail error err {
        io:println(err);
    }
}
