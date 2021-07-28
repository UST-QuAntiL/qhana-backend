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

configurable int port = 9090;



# The QHAna backend api service.
service / on new http:Listener(port) {
    resource function get .() returns RootResponse {
        return {
            experiments: "/experiments/",
            pluginRunners: "/pluginRunners/",
            tasks: "/tasks/"
        };
    }

    resource function get plugin\-runners() returns http:Ok {
        return {};
    }
    resource function get tasks/[string taskId]() returns http:Ok {
        return {};
    }

    resource function get experiments(string? page, string? 'item\-count) returns ExperimentResponse[]|http:InternalServerError {
        var experiments = database:getExperiments();

        if !(experiments is error) {
            // make sure that the id is not included in the answer
            var result = from var exp in experiments select mapToExperimentResponse(exp);
            return result;
        }

        io:println(experiments);

        http:InternalServerError err = {body: "Something went wrong. Please try again later."};
        return err;
    }
    
    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function post experiments(@http:Payload database:Experiment experiment) returns http:Ok|http:InternalServerError {
        error? result = database:createExperiment(experiment);

        if !(result is error) {
            return <http:Ok>{};
        }

        return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
    }
    
    resource function get experiments/[int experimentId]() returns ExperimentResponse|http:InternalServerError {
        var experiment = database:getExperiment(experimentId);

        if !(experiment is error) {
            return mapToExperimentResponse(experiment);
        }

        return <http:InternalServerError>{body: "Something went wrong. Please try again later."};

    }
    
    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function update experiments/[int experimentId](@http:Payload database:Experiment experiment) returns http:Ok {
        return {};
    }
    resource function get experiments/[int experimentId]/data() returns http:Ok {
        return {};
    }
    resource function get experiments/[int experimentId]/data/[string name](string? 'version) returns http:Ok {
        return {};
    }
    resource function get experiments/[int experimentId]/timeline() returns http:Ok {
        return {};
    }
    resource function post experiments/[int experimentId]/timeline() returns http:Ok {
        return {};
    }
    resource function get experiments/[int experimentId]/timeline/[string timelineStep]() returns http:Ok {
        return {};
    }
    resource function get experiments/[int experimentId]/timeline/[string timelineStep]/notes() returns http:Ok {
        return {};
    }
    resource function put experiments/[int experimentId]/timeline/[string timelineStep]/notes() returns http:Ok {
        return {};
    }
}
