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

import qhana_backend.database;

public type Error record {
    # The error message indicating what the issue is
    string message;
    # The http status code
    int code;
};

type RootResponse record {|
    string experiments;
    string pluginRunners;
    string tasks;
|};


type ApiResponse record {|
    string '\@self;
|};


type ExperimentResponse record {|
    *ApiResponse;
    *database:Experiment;
|};


type ExperimentListResponse record {|
    *ApiResponse;
    ExperimentResponse[] items;
|};

function mapToExperimentResponse(database:ExperimentFull experiment) returns ExperimentResponse {
    return {
        '\@self: string`/experiments/${experiment.experimentId}`, 
        name: experiment.name, 
        description: experiment.description
    };
}
