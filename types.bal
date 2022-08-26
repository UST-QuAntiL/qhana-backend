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

# Post payload to create new plugin endpoint resources.
#
# + url - the URL of the plugin endpoint
# + 'type - the type of the endpoint ("Plugin"|"PluginRunner")
public type PluginEndpointPost record {|
    string url;
    string 'type = "PluginRunner";
|};

# A plugin endpoint resource.
#
# + endpointId - the id of the plugin endpoint
# + url - the URL of the plugin endpoint
# + 'type - the type of the endpoint ("Plugin"|"PluginRunner")
public type PluginEndpointResponse record {|
    *ApiResponse;
    int endpointId;
    string url;
    string 'type = "PluginRunner";
|};

# The plugin endpoints list resource.
#
# + items - the plugin endpoint resources
# + itemCount - the total count of plugin endpoints
public type PluginEndpointsListResponse record {|
    *ApiResponse;
    PluginEndpointResponse[] items;
    int itemCount;
|};

# Helper function to map from `PluginEndpointFull` database record to API record.
#
# + endpoint - the input database record
# + return - the mapped record
public isolated function mapToPluginEndpointResponse(database:PluginEndpointFull endpoint) returns PluginEndpointResponse {
    return {
        '\@self: string `${serverHost}/plugin-endpoints/${endpoint.id}`,
        endpointId: endpoint.id,
        url: endpoint.url,
        'type: endpoint.'type
    };
}

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
        '\@self: string `${serverHost}/experiments/${experiment.experimentId}`,
        experimentId: experiment.experimentId,
        name: experiment.name,
        description: experiment.description
    };
}

////////////////////////////////////////////////////////////////////////////////
// Data ////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Experiment data resource record.
#
# + download - a download link of the data
# + producingStep - the timeline step which produced the data
# + producingStepLink - a link to the producing timeline step
# + inputFor - a list of timeline steps in which this data was used as input
# + inputForLinks - a list of links to timeline steps in which this data was used as input
# + name - the (file-) name of the data
# + 'version - the version of the data
# + 'type - the datatype tag
# + contentType - the content type tag
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

# The experiment data list record.
#
# + items - The list of experiment data resources
# + itemCount - The total count of experiment data resources
public type ExperimentDataListResponse record {|
    *ApiResponse;
    ExperimentDataResponse[] items;
    int itemCount;
|};

# Helper function to map from `ExperimentDataFull` database record to API record.
#
# + data - the input data record
# + producingStep - the database record of the producing step
# + inputFor - the list of database records of steps this data was used in
# + return - the mapped record
public isolated function mapToExperimentDataResponse(database:ExperimentDataFull data, int? producingStep = (), int[]? inputFor = ()) returns ExperimentDataResponse {
    ExperimentDataResponse dataMapped = {
        '\@self: string `${serverHost}/experiments/${data.experimentId}/data/${data.name}?version=${data.'version}`,
        download: string `${serverHost}/experiments/${data.experimentId}/data/${data.name}/download?version=${data.'version}`,
        name: data.name,
        'version: data.'version,
        'type: data.'type,
        contentType: data.contentType
    };
    if (producingStep != ()) {
        dataMapped.producingStep = producingStep;
        dataMapped.producingStepLink = string `${serverHost}/experiments/${data.experimentId}/timeline/${producingStep}`;
    }
    if (inputFor != ()) {
        dataMapped.inputFor = inputFor;
        dataMapped.inputForLinks = from var step in inputFor
            select string `${serverHost}/experiments/${data.experimentId}/timeline/${step}`;
    }
    return dataMapped;
}

////////////////////////////////////////////////////////////////////////////////
// Timeline ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Post payload to create a new timeline step.
#
# + resultLocation - the URL of the pending QHAna plugin result
# + inputData - a list of all data used as input (must also be part of parameters!) 
# + processorName - the plugin name processing the request
# + processorVersion - the plugin version
# + processorLocation - the root URL of the plugin
# + parameters - the user inputs used to request the plugin result
# + parametersContentType - the parameter encoding content type
public type TimelineStepPost record {|
    string resultLocation;
    string[] inputData;
    string processorName;
    string? processorVersion = ();
    string? processorLocation = ();
    string? parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    *database:Progress;
|};

# Minimal timeline step resource record.
#
# + notes - a link to the step notes
# + sequence - the sequence number of the step in the experiment (used as step id)
# + 'start - the time the step was recorded into the backend database
# + end - the time the result was recorded into the backend database
# + status - the current status of the step
# + resultQuality - the result quality
# + processorName - the plugin name processing the request
# + processorVersion - the plugin version
# + processorLocation - the root URL of the plugin
# + parameters - a link to the parameters
# + parametersContentType - the parameter encoding content type
public type TimelineStepMinResponse record {|
    *ApiResponse;
    string notes;
    int sequence;
    string 'start;
    string? end = ();
    string status;
    string resultQuality;
    string processorName;
    string? processorVersion = ();
    string? processorLocation = ();
    string parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    *database:Progress;
|};

# The full timeline step record.
#
# + resultLog - the result log present in the pending plugin result
# + inputData - the input data used (also part of the input parameters)
# + inputDataLinks - links to the input data
# + outputData - the output data of the timeline step
# + outputDataLinks - links to the output data
# + substeps - a list of substeps
public type TimelineStepResponse record {|
    *TimelineStepMinResponse;
    string resultLog;
    database:ExperimentDataReference[] inputData;
    string[] inputDataLinks;
    database:ExperimentDataReference[] outputData;
    string[] outputDataLinks;
    TimelineSubstepResponseWithoutParams[]? substeps = ();
|};

# A list of timeline steps.
#
# Uses the minimal timeline step record.
#
# + items - the timeline steps
# + itemCount - the total number of timeline steps
public type TimelineStepListResponse record {|
    *ApiResponse;
    TimelineStepMinResponse[] items;
    int itemCount;
|};

# Post payload to provide the input parameters of a timeline substep.
#
# + inputData - the input data used in the substep (also in parameters)
# + parameters - the input parameters
# + parametersContentType - the parameter encoding content type
public type TimelineSubstepPost record {|
    string[] inputData;
    string? parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
|};

# Timeline substep record.
#
# + stepId - the step id this is a substep of (the sequence number of the step)
# + sequence - the sequence number of the associated timeline step
# + substepId - the substep id (a string id given to the substep by the plugin)
# + substepNr - the sequence number of the substep in the current step
# + href - the endpoint URL of the substep
# + hrefUi - the micro frontend URL of the substep
# + cleared - the status of the substep (true once data was received for the substep)
# + parameters - the input parameetrs of the substep
# + parametersContentType - the parameter encoding content type
# + inputData - the input data of the substep (also in parameters)
# + inputDataLinks - links to the input data of the substep
public type TimelineSubstepResponseWithParams record {|
    *ApiResponse;
    int stepId; // TODO remove once frontend accepts sequence
    int sequence;
    string? substepId;
    int substepNr;
    string href;
    string? hrefUi;
    boolean cleared;
    string? parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    database:ExperimentDataReference[] inputData;
    string[] inputDataLinks;
|};

# Timeline substep record.
#
# + stepId - the step id this is a substep of (the sequence number of the step)
# + sequence - the sequence number of the associated timeline step
# + substepId - the substep id (a string id given to the substep by the plugin)
# + substepNr - the sequence number of the substep in the current step
# + href - the endpoint URL of the substep
# + hrefUi - the micro frontend URL of the substep
# + cleared - the status of the substep (true once data was received for the substep)
# + inputData - the input data of the substep (also in parameters)
public type TimelineSubstepResponseWithoutParams record {|
    int stepId; // TODO remove once frontend accepts sequence
    int sequence;
    string? substepId;
    int substepNr;
    string href;
    string? hrefUi;
    boolean cleared;
    database:ExperimentDataReference[]? inputData;
|};

# List of timeline substeps
#
# + items - the timeline substeps
public type TimelineSubstepListResponse record {|
    *ApiResponse;
    TimelineSubstepResponseWithoutParams[] items;
|};

# Put payload to change the result quality field of a timeline step.
#
# + resultQuality - the new result quality
public type TimelineStepResultQualityPut record {|
    string resultQuality;
|};

# Timeline step notes record.
#
# + notes - the notes text/markdown content
public type TimelineStepNotesResponse record {|
    *ApiResponse;
    string notes;
|};

# Payload to change the notes of a timeline step
#
# + notes - new the notes text/markdown content
public type TimelineStepNotesPost record {|
    string notes;
|};

# Helper function to map database `TimelineStepFull` records to minimal timeline step API records.
#
# + step - the input database record
# + return - the mapped record
public isolated function mapToTimelineStepMinResponse(database:TimelineStepFull step) returns TimelineStepMinResponse {
    var end = step.end;
    return {
        '\@self: string `${serverHost}/experiments/${step.experimentId}/timeline/${step.sequence}`,
        notes: string `./notes`,
        sequence: step.sequence,
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        resultQuality: step.resultQuality,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parameters: string `${serverHost}/experiments/${step.experimentId}/timeline/${step.sequence}/parameters`,
        parametersContentType: step.parametersContentType,
        progressValue: step.progressValue,
        progressStart: step.progressStart,
        progressTarget: step.progressTarget,
        progressUnit: step.progressUnit
    };
}

# Helper function to map database `TimelineStepFull` records to full timeline step API records.
#
# + step - the input database record
# + substeps - the list of substeps
# + inputData - the input data consumed in this step
# + outputData - the output data produced by this step
# + return - the mapped record  
public isolated function mapToTimelineStepResponse(
        database:TimelineStepWithParams step,
        database:TimelineSubstepSQL[]? substeps,
        database:ExperimentDataReference[] inputData = [],
        database:ExperimentDataReference[] outputData = []
) returns TimelineStepResponse {
    var end = step.end;
    var log = step.resultLog;
    var inputDataLinks = from var dataRef in inputData
        select string `${serverHost}/experiments/${step.experimentId}/data/${dataRef.name}?version=${dataRef.'version}`;
    var outputDataLinks = from var dataRef in outputData
        select string `${serverHost}/experiments/${step.experimentId}/data/${dataRef.name}?version=${dataRef.'version}`;
    TimelineSubstepResponseWithoutParams[]? substepsResponse = ();
    if substeps != () {
        substepsResponse = mapToTimelineSubstepListResponse(step.experimentId, step.sequence, substeps);
    }
    return {
        '\@self: string `${serverHost}/experiments/${step.experimentId}/timeline/${step.sequence}`,
        notes: string `./notes`,
        sequence: step.sequence,
        'start: time:utcToString(step.'start),
        end: end == () ? () : time:utcToString(end),
        status: step.status,
        resultQuality: step.resultQuality,
        resultLog: log == () ? "" : log,
        processorName: step.processorName,
        processorVersion: step.processorVersion,
        processorLocation: step.processorLocation,
        parametersContentType: step.parametersContentType,
        parameters: string `${serverHost}/experiments/${step.experimentId}/timeline/${step.sequence}/parameters`,
        inputData: inputData,
        inputDataLinks: inputDataLinks,
        outputData: outputData,
        outputDataLinks: outputDataLinks,
        progressValue: step.progressValue,
        progressStart: step.progressStart,
        progressTarget: step.progressTarget,
        progressUnit: step.progressUnit,
        substeps: substepsResponse
    };
}

# Helper function to map `TimelineSubstepWithParams` database records to API records.
#
# + experimentId - the id of the experiment the substep is part of
# + timelineStepSequence - the sequence number of the associated timeline step
# + substep - the input substep record
# + inputData - the input data of the substep
# + return - the mapped record
public isolated function mapToTimelineSubstepResponse(
        int experimentId,
        int timelineStepSequence,
        database:TimelineSubstepWithParams substep,
        database:ExperimentDataReference[] inputData = []
) returns TimelineSubstepResponseWithParams {
    var inputDataLinks = from var dataRef in inputData
        select string `${serverHost}/experiments/${experimentId}/data/${dataRef.name}?version=${dataRef.'version}`;
    return {
        '\@self: string `${serverHost}/experiments/${experimentId}/timeline/${timelineStepSequence}/substeps/${substep.substepNr}`,
        stepId: timelineStepSequence,
        sequence: timelineStepSequence,
        substepId: substep.substepId,
        substepNr: substep.substepNr,
        href: substep.href,
        hrefUi: substep.hrefUi,
        cleared: substep.cleared == 1 ? true : false,
        parameters: string `${serverHost}/experiments/${experimentId}/timeline/${timelineStepSequence}/substeps/${substep.substepNr}/parameters`,
        parametersContentType: substep?.parametersContentType,
        inputData: inputData,
        inputDataLinks: inputDataLinks
    };
}

# Helper function to map `TimelineSubstepSQL[]` database records to API records.
#
# + experimentId - the id of the experiment the substep is part of
# + timelineStepSequence - the sequence number of the associated timeline step
# + substeps - the input substep list
# + return - the mapped record
public isolated function mapToTimelineSubstepListResponse(
        int experimentId,
        int timelineStepSequence,
        database:TimelineSubstepSQL[] substeps
) returns TimelineSubstepResponseWithoutParams[] {
    return from var substep in substeps
        select {
            stepId: timelineStepSequence,
            sequence: timelineStepSequence,
            substepId: substep.substepId,
            substepNr: substep.substepNr,
            href: substep.href,
            hrefUi: substep.hrefUi,
            cleared: substep.cleared == 1 ? true : false,
            inputData: substep?.inputData
        };
}

# Parse a data input URL to extract the URL parameters.
#
# + experimentId - the current experiment id
# + url - the data input URL to parse
# + return - the parsed parameters
public isolated function mapFileUrlToDataRef(int experimentId, string url) returns database:ExperimentDataReference|error {
    // TODO refactor once regex supports extrating group matches
    var regex = string `^(https?:\/\/)?[^\/]*\/experiments\/${experimentId}\/data\/[^\/]+\/download\?version=(latest|[0-9]+)$`;
    if !regex:matches(url, regex) {
        return error("url does not match any file from the experiment." + url);
    }
    // retrieve actual positions with index of looks because regex module is lacking 
    // this is safe(ish) because the regex above guarantees the format
    var dataStart = url.indexOf("/data/");
    var filenameEnd = url.lastIndexOf("/download?");
    var queryStart = url.lastIndexOf("?");
    var versionStart = url.lastIndexOf("=");
    if dataStart == () || filenameEnd == () || queryStart == () || versionStart == () {
        return error("A malformed url slipped through the regex test.");
    } else {
        var filename = url.substring(dataStart + 6, filenameEnd);
        var versionNumber = url.substring(versionStart + 1, url.length());
        return {
            name: check url:decode(filename, "UTF-8"),
            'version: check int:fromString(versionNumber)
        };
    }
}
