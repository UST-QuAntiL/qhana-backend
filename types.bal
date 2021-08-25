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

import ballerina/time;
import ballerina/mime;
import ballerina/regex;
import ballerina/url;
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


public type PluginRunnersListResponse record {|
    *ApiResponse;
    string[] items;
    int itemCount;
|};


////////////////////////////////////////////////////////////////////////////////
// Experiments /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


# Api response for a single experiment.
# 
# + experimentId - The database id of the experiment
public type ExperimentResponse record {|
    *ApiResponse;
    int experimentId;
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
        experimentId: experiment.experimentId,
        name: experiment.name,
        description: experiment.description
    };
}


////////////////////////////////////////////////////////////////////////////////
// Data ////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


public type ExperimentDataResponse record {|
    *ApiResponse;
    string download;
    int producingStep?;
    string producingStepLink?;
    int[] inputFor?;
    string[] inputForLinks?;
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


public isolated function mapToExperimentDataResponse(database:ExperimentDataFull data, int? producingStep=(), int[]? inputFor=()) returns ExperimentDataResponse {
    ExperimentDataResponse dataMapped = {
        '\@self: string `/experiments/${data.experimentId}/data/${data.name}?version=${data.'version}`,
        download: string `/experiments/${data.experimentId}/data/${data.name}/download?version=${data.'version}`,
        name: data.name,
        'version: data.'version,
        'type: data.'type,
        contentType: data.contentType
    };
    if (producingStep != ()) {
        dataMapped.producingStep = producingStep;
        dataMapped.producingStepLink = string `/experiments/${data.experimentId}/timeline/${producingStep}`;
    }
    if (inputFor != ()) {
        dataMapped.inputFor = inputFor;
        dataMapped.inputForLinks = from var step in inputFor select string `/experiments/${data.experimentId}/timeline/${step}`;
    }
    return dataMapped;
}


////////////////////////////////////////////////////////////////////////////////
// Timeline ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public type TimelineStepPost record {|
    string resultLocation;
    string[] inputData;

    string processorName;
    string? processorVersion=();
    string? processorLocation=();
    string? parameters;
    string parametersContentType=mime:APPLICATION_FORM_URLENCODED;
    string? parametersDescriptionLocation=();
|};

public type TimelineStepMinResponse record {|
    *ApiResponse;
    string notes;
    int sequence;
    string 'start;
    string? end=();
    string status;
    string processorName;
    string? processorVersion=();
    string? processorLocation=();
    string? parametersContentType=();
    string? parametersDescriptionLocation=();
|};

public type TimelineStepResponse record {|
    *TimelineStepMinResponse;
    string resultLog;
    string parameters;
    database:ExperimentDataReference[] inputData;
    string[] inputDataLinks;
    database:ExperimentDataReference[] outputData;
    string[] outputDataLinks;
|};


public type TimelineStepListResponse record {|
    *ApiResponse;
    TimelineStepMinResponse[] items;
    int itemCount;
|};

public type TimelineStepNotesResponse record {|
    *ApiResponse;
    string notes;
|};


public isolated function mapToTimelineStepMinResponse(database:TimelineStepFull step) returns TimelineStepMinResponse {
    var end = step.end;
    return {
        '\@self: string`/experiments/${step.experimentId}/timeline/${step.sequence}`,
        notes: string `./notes`,
        sequence: step.sequence,
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parametersDescriptionLocation: step.parametersDescriptionLocation
    };
}

public isolated function mapToTimelineStepResponse(
        database:TimelineStepWithParams step, 
        database:ExperimentDataReference[] inputData=[], 
        database:ExperimentDataReference[] outputData=[]
    ) returns TimelineStepResponse {
    var end = step.end;
    var log = step.resultLog;
    var inputDataLinks = from var dataRef in inputData 
        select string`/experiments/${step.experimentId}/data/${dataRef.name}?version=${dataRef.'version}`;
    var outputDataLinks = from var dataRef in outputData 
        select string`/experiments/${step.experimentId}/data/${dataRef.name}?version=${dataRef.'version}`;
    return {
        '\@self: string `/experiments/${step.experimentId}/timeline/${step.sequence}`,
        notes: string `./notes`,
        sequence: step.sequence,
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        resultLog: log == () ? "" : log,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parametersDescriptionLocation: step.parametersDescriptionLocation,
        parametersContentType: step.parametersContentType,
        parameters: step?.parameters,
        inputData: inputData,
        inputDataLinks: inputDataLinks,
        outputData: outputData,
        outputDataLinks: outputDataLinks
    };
}

public isolated function mapFileUrlToDataRef(int experimentId, string url) returns database:ExperimentDataReference|error {
    var regex = string`^(https?:\/\/)?[^\/]*\/experiments\/${experimentId}\/data\/[^\/]+\/download\?version=(latest|[0-9]+)$`;
    if !regex:matches(url, regex) {
        return error("url does not match any file from the experiment.");
    }
    var dataStart = url.lastIndexOf("/data/");
    var filenameEnd = url.lastIndexOf("/download?");
    var queryStart = url.lastIndexOf("?");
    var versionStart = url.lastIndexOf("=");
    if dataStart == () || filenameEnd == () || queryStart == () || versionStart == () {
        return error("A malformed url slipped through the regex test.");
    } else {
        var filename = url.substring(dataStart + 6, filenameEnd);
        var versionNumber = url.substring(versionStart+1, url.length());
        return {
            name: check url:decode(filename, "UTF-8"),
            'version: check int:fromString(versionNumber)
        };
    }
}
