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

# Generic error response for the api.
#
# + message - The error message
# + code - The http status code
public type Error record {
    string message;
    int code;
};

# The base record for api responses.
#
# + '\@self - Canonical self link of the resource
public type ApiResponse record {|
    string '\@self;
|};

# The root api response
#
# + experiments - Url to the experiments collection resource
# + pluginRunners - Url to the plugin runners collection resource
# + tasks - Url to the tasks collection resource
public type RootResponse record {|
    *ApiResponse;
    string experiments;
    string pluginRunners;
    string tasks;
|};

# Api response for a single experiment.  
public type ExperimentResponse record {|
    *ApiResponse;
    *database:Experiment;
|};

# Api response for a list of experiments.
#
# + items - The experiment list
# + itemCount - The total number of resources in the collection
public type ExperimentListResponse record {|
    *ApiResponse;
    ExperimentResponse[] items;
    int itemCount;
|};

# Convenience function to map database experiment entries to experiment responses.
#
# + experiment - The full experiment data from the database
# + return - The api response
public isolated function mapToExperimentResponse(database:ExperimentFull experiment) returns ExperimentResponse {
    return {
        '\@self: string `/experiments/${experiment.experimentId}`,
        name: experiment.name,
        description: experiment.description
    };
}


public type ExperimentDataResponse record {|
    *ApiResponse;
    string download;
    string name;
    int 'version;
    string 'type;
    string contentType;
|};


public type ExperimentDataListResponse record {|
    *ApiResponse;
    ExperimentDataResponse[] items;
    int itemCount;
|};


public isolated function mapToExperimentDataResponse(database:ExperimentDataFull data) returns ExperimentDataResponse {
    return {
        '\@self: string `/experiments/${data.experimentId}/data/${data.name}?version=${data.'version}`,
        download: string `/experiments/${data.experimentId}/data/${data.name}/download?version=${data.'version}`,
        name: data.name,
        'version: data.'version,
        'type: data.'type,
        contentType: data.contentType
    };
}
