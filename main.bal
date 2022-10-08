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
import ballerina/regex;
import ballerina/os;
import ballerina/log;
import qhana_backend.database;
import ballerina/file;
import ballerina/io;

// start configuration values
# List of domains that are allowed CORS requests to the backend.
# Can also be configured by setting the `QHANA_CORS_DOMAINS` environment variable.
configurable string[] corsDomains = ["*"];

# Get the port from the `QHANA_CORS_DOMAINS` environment variable.
# If not present use the configurable variable `corsDomains` as fallback.
#
# + return - the configured cors domains
function getCorsDomains() returns string[] {
    string d = os:getEnv("QHANA_CORS_DOMAINS");
    if (d.length() > 0) {
        return regex:split(d, "[\\s]+");
    }
    return corsDomains;
}

# The final configured cors domains.
final string[] & readonly configuredCorsDomains = getCorsDomains().cloneReadOnly();

# User configurable port of the backend server.
# Can also be configured by setting the `QHANA_PORT` environment variable.
configurable int port = 9090;

# Get the port from the `QHANA_PORT` environment variable.
# If not present use the configurable variable `port` as fallback.
#
# + return - the configured port number
function getPort() returns int {
    string p = os:getEnv("QHANA_PORT");
    if (regex:matches(p, "^[0-9]+$")) {
        do {
            return check int:fromString(p);
        } on fail {
            // error should never happen if regex is correct...
        }
    }
    return port;
}

# The final configured server port.
final int & readonly serverPort = getPort().cloneReadOnly();

# User specified host ip address of backend server (with protocol and port)
# Can also be specified by setting the `QHANA_HOST` environment variable.
configurable string host = "http://localhost:" + serverPort.toString();

# Determine the base host url from the `QHANA_HOST` environment variable.
# If not present use the configurable variable `host` as fallback.
#
# + return - the configured host base path (including protocol and port)
function getHost() returns string {
    string h = os:getEnv("QHANA_HOST");
    if (regex:matches(h, "^https?:\\/\\/.*$")) {
        return h;
    }
    return host;
}

# The final configured server host.
final string & readonly serverHost = getHost().cloneReadOnly();

# User configurable watcher intervall configuration.
# Can also be configured by setting the `QHANA_WATCHER_INTERVALLS` environment variable.
# The numbers are interpreted as folowing: `[<intervall in seconds>, [<iterations until next intervall>]]*`
# If the list ends with an intervall, i.e., the iterations count is missing, then the intervall 
# will be repeated indefinitely.
configurable (decimal|int)[] watcherIntervallConfig = [2, 10, 5, 10, 10, 60, 30, 20, 60, 10, 600];

# Coerce the string input to a positive int or decimal.
#
# + input - the string input to coerce
# + return - the coerced number or the error if coercion failed (or the number was negative)
function coerceToPositiveNumber(string input) returns decimal|int|error {
    boolean isDecimal = regex:matches(input, "^\\+?[0-9]+\\.[0-9]+$");
    if (isDecimal) {
        return decimal:fromString(input);
    }
    boolean isInt = regex:matches(input, "^\\+?[0-9]+$");
    if (isInt) {
        return int:fromString(input);
    }
    return error(string `Input "${input}" is not a positive number!`);
}

# Get the watcher intervalls from the `QHANA_WATCHER_INTERVALLS` environment variable.
# If not present use the configurable variable `watcherIntervallConfig` as fallback.
#
# + return - the configured watcher intervalls
function getWatcherIntervallConfig() returns (decimal|int)[] {
    string intervalls = os:getEnv("QHANA_WATCHER_INTERVALLS");
    if (intervalls.length() > 0) {
        do {
            return from string i in regex:split(intervalls, "[\\s\\(\\),;]+")
                select check coerceToPositiveNumber(i);
        } on fail error err {
            log:printError("Failed to parse environment variable QHANA_WATCHER_INTERVALLS!\n", 'error = err, stackTrace = err.stackTrace());
        }
    }
    return watcherIntervallConfig;
}

# The final configured watcher intervalls.
final (decimal|int)[] & readonly configuredWatcherIntervalls = getWatcherIntervallConfig().cloneReadOnly();

# User configurable URL map which is used by the backend to rewrite URLs used by the result watchers.
# Can also be configured by setting the `QHANA_URL_MAPPING` environment variable.
# The keys are regex patterns and the values replacement string.
# All replacements will be applied to an URL.
#
# Intended for use in a dockerized dev setup where localhost is used as outside URL
configurable map<string> & readonly internalUrlMap = {};

# Get the URL map from the `QHANA_URL_MAPPING` environment variable.
# If not present use the configurable variable `internalUrlMap` as fallback.
#
# + return - the configured watcher intervalls
function getInternalUrlMap() returns map<string> {
    string mapping = os:getEnv("QHANA_URL_MAPPING");
    if (mapping.length() > 0) {
        do {
            return check mapping.fromJsonStringWithType();
        } on fail error err {
            log:printError("Failed to parse environment variable QHANA_URL_MAPPING!\n", 'error = err, stackTrace = err.stackTrace());
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

# The final configured URL map.
final map<string> & readonly configuredUrlMap = getInternalUrlMap().cloneReadOnly();

# Preset plugins.
# Can also be configured by setting the `QHANA_PLUGINS` environment variable.
configurable string[] plugins = [];

# Preset plugin runners.
# Can also be configured by setting the `QHANA_PLUGIN_RUNNERS` environment variable.
configurable string[] pluginRunners = [];

# Get preset plugin runner from the `QHANA_PLUGIN_RUNNERS` environment variable.
# If not present use the configurable variable `pluginRunners` as fallback.
#
# + return - the configured watcher intervalls
function getPluginRunnersConfig() returns string[] {
    string pRunners = os:getEnv("QHANA_PLUGIN_RUNNERS");
    if (pRunners.length() > 0) {
        do {
            return check pRunners.fromJsonStringWithType();
        } on fail error err {
            log:printError("Failed to parse environment variable QHANA_PLUGIN_RUNNERS!\n", 'error = err, stackTrace = err.stackTrace());
        }
    }
    return pluginRunners;
}

# The final configured plugin runners.
final string[] & readonly preconfiguredPluginRunners = getPluginRunnersConfig().cloneReadOnly();

# Get preset plugins from the `QHANA_PLUGINS` environment variable.
# If not present use the configurable variable `plugins` as fallback.
#
# + return - the configured watcher intervalls
function getPluginsConfig() returns string[] {
    string pluginList = os:getEnv("QHANA_PLUGINS");
    if (pluginList.length() > 0) {
        do {
            return check pluginList.fromJsonStringWithType();
        } on fail error err {
            log:printError("Failed to parse environment variable QHANA_PLUGINS!\n", 'error = err, stackTrace = err.stackTrace());
        }
    }
    return plugins;
}

# The final configured plugins.
final string[] & readonly preconfiguredPlugins = getPluginsConfig().cloneReadOnly();

// end configuration values

# Rewrite the given URL with the rules configured in the variable `configuredUrlMap`.
#
# + url - the input URL
# + return - the rewritten URL
isolated function mapToInternalUrl(string url) returns string {
    if configuredUrlMap.length() == 0 {
        return url; // fast exit
    }
    // apply all replacements specified in the url map, keys are interpreted as regex
    var replacedUrl = url;
    foreach var [pattern, replacement] in configuredUrlMap.entries() {
        replacedUrl = regex:replace(replacedUrl, pattern, replacement);
    }
    return replacedUrl;
}

# The QHAna backend api service.
@http:ServiceConfig {
    cors: {
        allowOrigins: configuredCorsDomains,
        allowMethods: ["OPTIONS", "GET", "PUT", "POST", "DELETE"],
        allowHeaders: ["Content-Type", "Depth", "User-Agent", "range", "X-File-Size", "X-Requested-With", "If-Modified-Since", "X-File-Name", "Cache-ControlAccess-Control-Allow-Origin"],
        allowCredentials: true,
        maxAge: 84900
    }
}
service / on new http:Listener(serverPort) {

    # The root resource of the QHAna backend API.
    #
    # All resources contain a `@self` link that is the canonical URL of the resource.
    # Resources can contain links to other resources.
    #
    # + return - the root resource
    resource function get .() returns RootResponse {
        return {
            '\@self: serverHost + "/",
            experiments: serverHost + "/experiments/",
            pluginRunners: serverHost + "/pluginRunners/",
            tasks: serverHost + "/tasks/"
        };
    }

    # Get a list of configured plugin or plugin-runner endpoints.
    #
    # + return - the list of endpoints as a "ListResponse".
    resource function get plugin\-endpoints() returns PluginEndpointsListResponse|http:InternalServerError {
        int endpointCount;
        database:PluginEndpointFull[] endpoints;

        transaction {
            endpointCount = check database:getPluginEndpointsCount();
            endpoints = check database:getPluginEndpoints();
            check commit;
        } on fail error err {
            log:printError("Could not get plugin endpoints.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var result = from var endpoint in endpoints
            select mapToPluginEndpointResponse(endpoint);
        // FIXME load from database...
        return {
            '\@self: serverHost + "/plugin-endpoints",
            items: result,
            itemCount: endpointCount
        };
    }

    # Add a new endpoint to the list of plugin(-runner) endpoints.
    #
    # + return - the created resource
    resource function post plugin\-endpoints(@http:Payload PluginEndpointPost endpoint) returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:addPluginEndpoint(endpoint);
            check commit;
        } on fail error err {
            log:printError("Could not add new plugin endpoint", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    # Get a specific plugin(-runner) endpoint resource.
    #
    # + return - the endpoint resource
    resource function get plugin\-endpoints/[int endpointId]() returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:getPluginEndpoint(endpointId);
            check commit;
        } on fail error err {
            log:printError("Could not get plugin endpoint.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    # Update an existing plugin(-runner) endpoint resource.
    #
    # + return - the updated endpoint resource
    resource function put plugin\-endpoints/[int endpointId](@http:Payload PluginEndpointPost endpoint) returns PluginEndpointResponse|http:InternalServerError {
        database:PluginEndpointFull result;
        transaction {
            result = check database:editPluginEndpoint(endpointId, endpoint.'type);
            check commit;
        } on fail error err {
            log:printError("Could not update plugin endpoint", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToPluginEndpointResponse(result);
    }

    # Remove an existing plugin(-runner) endpoint resource.
    #
    # + return - an empty response with a 2xx http status code on success
    resource function delete plugin\-endpoints/[int endpointId]() returns http:Ok|http:InternalServerError {
        transaction {
            check database:deletePluginEndpoint(endpointId);
            check commit;
        } on fail error err {
            log:printError("Could not delete plugin endpoint", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    ////////////////////////////////////////////////////////////////////////////
    // Experiments /////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    # Get a list of experiments.
    #
    # The experiments list resource is paginated
    #
    # + search - filter by experiment name
    # + page - the requested page (starting with page 0)
    # + 'item\-count - the number of items per page (5 <= item-count <= 500)
    # + sort - 1 for asc sort, -1 for desc sort by experiment name
    # + return - the list resource containing the experiments
    resource function get experiments(string? search, int? page = 0, int? 'item\-count = 10, int? sort = 1) returns ExperimentListResponse|http:InternalServerError|http:BadRequest|http:NotFound {
        int intPage = (page is ()) ? 0 : page;
        int itemCount = (item\-count is ()) ? 10 : item\-count;
        int intSort = (sort is ()) ? 1 : sort;

        if (intPage < 0) {
            return <http:BadRequest>{body: "Cannot retrieve a negative page number!"};
        }

        if (itemCount < 5 || itemCount > 500) {
            return <http:BadRequest>{body: "Item count must be between 5 and 500 (both inclusive)!"};
        }

        var offset = intPage * itemCount;

        int experimentCount;
        database:ExperimentFull[] experiments;

        transaction {
            experimentCount = check database:getExperimentCount(search = search);
            if (offset >= experimentCount) {
                // page is out of range!
                check commit;
                return <http:NotFound>{};
            } else {
                experiments = check database:getExperiments(search = search, 'limit = itemCount, offset = offset, sort = intSort);
                check commit;
            }
        } on fail error err {
            log:printError("Could not get experiments.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        // map to api response(s)
        var result = from var exp in experiments
            select mapToExperimentResponse(exp);
        // TODO include query params in self link
        return {'\@self: serverHost + "/experiments/", items: result, itemCount: experimentCount};
    }

    # Create a new experiment.
    #
    # + return - the created experiment resource
    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function post experiments(@http:Payload database:Experiment experiment) returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:createExperiment(experiment);
            check commit;
        } on fail error err {
            log:printError("Could not create new experiment", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    # Get a specific experiment by its id.
    #
    # + experimentId - the id of the requested experiment
    # + return - the experiment resource
    resource function get experiments/[int experimentId]() returns ExperimentResponse|http:InternalServerError|error {
        database:ExperimentFull result;
        transaction {
            result = check database:getExperiment(experimentId);
            check commit;
        } on fail error err {
            log:printError("Could not get experiment.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    # Update an existing experiment.
    #
    # + experimentId - the id of the experiment to update
    # + return - the updated experiment
    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function put experiments/[int experimentId](@http:Payload database:Experiment experiment) returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:updateExperiment(experimentId, experiment);
            check commit;
        } on fail error err {
            log:printError("Could not update experiment.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Data ////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    # Get summary information about data available in the experiment.
    #
    # The summary is a map which keys are the available data types.
    # The values of the map are lists of content types describing the serialization
    # formats available for the specific data type. This summary can be used to
    # decide if all input requirements for a plugin can be fulfilled by the
    # data available in the experiment.
    #
    # + experimentId - the id of the experiment
    # + return - the summary information of the currently available data
    resource function get experiments/[int experimentId]/data\-summary() returns map<string[]>|http:InternalServerError {

        map<string[]> data;

        transaction {
            data = check database:getDataTypesSummary(experimentId);
            check commit;
        } on fail error err {
            log:printError("Could not get data types summary.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        return data;
    }

    # Get a list of data available in the experiment.
    #
    # The data is sorted with newer versions appearing before oder versions.
    #
    # + experimentId - the id of the experiment
    # + sort - 1 for asc sort, -1 for desc sort by name and version
    # + search - search keyword in name, data type and content type (insensitive)
    # + return - the paginated list of data resources
    resource function get experiments/[int experimentId]/data(boolean? allVersions, string? search, int page = 0, int item\-count = 10, int? sort = 1) returns ExperimentDataListResponse|http:NotFound|http:InternalServerError|http:BadRequest {
        boolean includeAllVersions = allVersions == true || allVersions == ();
        int intSort = (sort is ()) ? 1 : sort;
        string searchString = (search is ()) ? "" : search;

        if (page < 0) {
            return <http:BadRequest>{body: "Cannot retrieve a negative page number!"};
        }

        if (item\-count < 5 || item\-count > 500) {
            return <http:BadRequest>{body: "Item count must be between 5 and 500 (both inclusive)!"};
        }

        var offset = page * item\-count;

        int dataCount;
        database:ExperimentDataFull[] data;

        transaction {
            dataCount = check database:getExperimentDataCount(experimentId, searchString, all = includeAllVersions);
            if (offset >= dataCount) {
                // page is out of range!
                check commit;
                return <http:NotFound>{};
            } else {
                data = check database:getDataList(experimentId, searchString, all = includeAllVersions, 'limit = item\-count, offset = offset, sort = intSort);
                check commit;
            }
        } on fail error err {
            log:printError("Could not get experiment data list.", 'error = err, stackTrace = err.stackTrace());

            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var dataList = from var d in data
            select mapToExperimentDataResponse(d);
        // TODO add query params to self URL
        return {'\@self: string `${serverHost}/experiments/${experimentId}/data/?allVersions=${includeAllVersions}`, items: dataList, itemCount: dataCount};
    }

    # Get a specific experiment data resource.
    #
    # + experimentId - the id of the experiment
    # + version - the version of the experiment data resource (optional, defaults to "latest")
    # + return - the experiment data resource
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
            log:printError("Could not get experiment data resource.", 'error = err, stackTrace = err.stackTrace());

            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentDataResponse(data, producingStep, inputFor);
    }

    # Download the actual data behind the experiment data resource.
    #
    # + experimentId - the id of the experiment
    # + version - the version of the experiment data resource (optional, defaults to "latest")
    # + return - the data of the experiment data resource
    resource function get experiments/[int experimentId]/data/[string name]/download(string? 'version, http:Caller caller) returns error? {
        database:ExperimentDataFull data;

        http:Response resp = new;
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.addHeader("Access-Control-Allow-Methods", "OPTIONS, GET");
        resp.addHeader("Access-Control-Allow-Headers", "range,Content-Type,Depth,User-Agent,X-File-Size,X-Requested-With,If-Modified-Since,X-File-Name,Cache-Control,Access-Control-Allow-Origin");

        transaction {
            data = check database:getData(experimentId, name, 'version);
            check commit;
        } on fail error err {
            log:printError("Could not get experiment data for download.", 'error = err, stackTrace = err.stackTrace());

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

    # Get a list of timeline entries of an experiment.
    #
    # The list resource of timeline entries is paginated
    #
    # + experimentId - the id of the experiment
    # + plugin\-name - filter by plugin name
    # + 'version - filter by version (name + version for exact match)
    # + status - filter by status (pending/finished)
    # + uncleared\-substep - filter by step status (whether there is an uncleared substep that requires user inputs) - 1 for true, 0 for false 
    # + page - the requested page (starting with page 0)
    # + 'item\-count - the number of items per page (5 <= item-count <= 500)
    # + sort - 1 for asc sort, -1 for desc sort by step sequence
    # + return - the list resource containing the timeline entries
    resource function get experiments/[int experimentId]/timeline(string? plugin\-name, string? 'version, string? status, int? uncleared\-substep, int page = 0, int item\-count = 0, int? sort = 1) returns TimelineStepListResponse|http:BadRequest|http:NotFound|http:InternalServerError {

        if (page < 0) {
            return <http:BadRequest>{body: "Cannot retrieve a negative page number!"};
        }

        if (item\-count < 5 || item\-count > 500) {
            return <http:BadRequest>{body: "Item count must be between 5 and 500 (both inclusive)!"};
        }

        int intSort = (sort is ()) ? 1 : sort;
        var offset = page * item\-count;

        int stepCount;
        database:TimelineStepFull[] steps;

        transaction {

            stepCount = check database:getTimelineStepCount(experimentId, plugin\-name, 'version, status, uncleared\-substep);
            if (offset >= stepCount) {
                // page is out of range!
                check commit;
                return <http:NotFound>{};
            } else {
                steps = check database:getTimelineStepList(experimentId, plugin\-name, 'version, status, uncleared\-substep, 'limit = item\-count, offset = offset, sort = intSort);
                check commit;
            }

        } on fail error err {
            log:printError("Could not get timeline step list.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }

        var stepList = from var s in steps
            select mapToTimelineStepMinResponse(s);
        return {'\@self: string `${serverHost}/experiments/${experimentId}/timeline`, items: stepList, itemCount: stepCount};
    }

    # Create a new timeline step entry.
    #
    # This also creates a new result watcher that keeps polling the plugin result
    # until the final result is available.
    #
    # + experimentId - the id of the experiment
    # + return - the created timeline step resource
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
            log:printError("Could not create new timeline step entry.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        do {
            ResultWatcher watcher = check new (createdStep.stepId);
            check watcher.schedule(...configuredWatcherIntervalls);
        } on fail error err {
            log:printError("Failed to start watcher.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Failed to start watcher."};
            return resultErr;
        }
        return mapToTimelineStepResponse(createdStep, (), inputData, []);
    }

    # Get a specific timeline step by its step number.
    #
    # + experimentId - the id of the experiment
    # + timelineStepSequence - the step number of the timeline step
    # + return - the requested timeline step resource
    resource function get experiments/[int experimentId]/timeline/[int timelineStepSequence]() returns TimelineStepResponse|http:InternalServerError {
        database:TimelineStepWithParams step;
        database:ExperimentDataReference[] inputData;
        database:ExperimentDataReference[] outputData;
        database:TimelineSubstepSQL[] substeps;
        transaction {
            step = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStepSequence);
            inputData = check database:getStepInputData(step);
            outputData = check database:getStepOutputData(step);
            // duplicates input data for substeps, but overhead is negligible 
            // TODO: FIXME substep has stepId field that is misinterpreted by ui -> change to sequence
            substeps = check database:getTimelineSubstepsWithInputData(step.stepId);
            check commit;
        } on fail error err {
            log:printError("Could not get timeline step.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToTimelineStepResponse(step, substeps, inputData, outputData);
    }

    # Update the result quality associated with a specific timeline step.
    #
    # Result quality must be one of the following values: 'UNKNOWN', 'NEUTRAL', 'GOOD', 'BAD', 'ERROR', or 'UNUSABLE'.
    #
    # + experimentId - the id of the experiment
    # + timelineStep - the step number of the timeline step
    # + return - an empty response with a 2xx http status code on success
    resource function put experiments/[int experimentId]/timeline/[int timelineStep](@http:Payload TimelineStepResultQualityPut resultQuality) returns http:Ok|http:BadRequest|http:InternalServerError {
        string rq = resultQuality.resultQuality;
        if rq != "UNKNOWN" && rq != "NEUTRAL" && rq != "GOOD" && rq != "BAD" && rq != "ERROR" && rq != "UNUSABLE" {
            return <http:BadRequest>{body: "Result quality must be one of the following values: 'UNKNOWN', 'NEUTRAL', 'GOOD', 'BAD', 'ERROR', or 'UNUSABLE'."};
        }
        transaction {
            check database:updateTimelineStepResultQuality(experimentId, timelineStep, resultQuality.resultQuality);
            check commit;
        } on fail error err {
            log:printError("Could not update result quality of timeline step.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    # Get the notes associated with a specific timelin step.
    #
    # + experimentId - the id of the experiment
    # + timelineStepSequence - the step number of the timeline step
    # + return - the timline step notes
    resource function get experiments/[int experimentId]/timeline/[int timelineStepSequence]/notes() returns TimelineStepNotesResponse|http:InternalServerError {
        string result;

        transaction {
            result = check database:getTimelineStepNotes(experimentId, timelineStepSequence);
            check commit;
        } on fail error err {
            log:printError("Could not get timeline step notes.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return {
            '\@self: string `${serverHost}/experiments/${experimentId}/timeline/${timelineStepSequence}/notes`,
            notes: result
        };
    }

    # Update the notes associated with a specific timeline step.
    #
    # + experimentId - the id of the experiment
    # + timelineStep - the step number of the timeline step
    # + return - the updated timline step notes
    resource function put experiments/[int experimentId]/timeline/[int timelineStep]/notes(@http:Payload TimelineStepNotesPost notes) returns http:Ok|http:InternalServerError {
        transaction {
            check database:updateTimelineStepNotes(experimentId, timelineStep, notes.notes);
            check commit;
        } on fail error err {
            log:printError("Could not update timeline step notes.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return <http:Ok>{};
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]/parameters(http:Caller caller) returns error? {
        database:TimelineStepWithParams result;

        http:Response resp = new;
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.addHeader("Access-Control-Allow-Methods", "OPTIONS, GET");
        resp.addHeader("Access-Control-Allow-Headers", "range,Content-Type,Depth,User-Agent,X-File-Size,X-Requested-With,If-Modified-Since,X-File-Name,Cache-Control,Access-Control-Allow-Origin");

        transaction {
            result = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStep);
            check commit;
        } on fail error err {
            log:printError("Could not get timeline step for parameter retrieval.", 'error = err, stackTrace = err.stackTrace());

            resp.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            resp.setPayload("Something went wrong. Please try again later.");

            check caller->respond(resp);
        }

        resp.statusCode = http:STATUS_OK;
        var cType = result.parametersContentType;
        if cType.startsWith("text/") || cType.startsWith("application/json") || cType.startsWith("application/X-lines+json") {
            resp.addHeader("Content-Disposition", "inline; filename=\"parameters\"");
        } else {
            resp.addHeader("Content-Disposition", "attachment; filename=\"parameters\"");
        }
        resp.setTextPayload(result.parameters, contentType = result.parametersContentType);

        check caller->respond(resp);
    }

    # Post the user input data associated with an unfinished timeline substep.
    #
    # + experimentId - the id of the experiment
    # + timelineStepSequence - the step number of the timeline step
    # + substepNr - the step number of the timeline substep
    # + return - the updated timline substep
    resource function post experiments/[int experimentId]/timeline/[int timelineStepSequence]/substeps/[int substepNr](@http:Payload TimelineSubstepPost substepData) returns TimelineSubstepResponseWithParams|http:InternalServerError {
        database:TimelineStepWithParams step;
        database:TimelineSubstepSQL substep;
        database:ExperimentDataReference[] inputData;

        transaction {
            inputData = check trap from var inputUrl in substepData.inputData
                select checkpanic mapFileUrlToDataRef(experimentId, inputUrl); // FIXME move back to check if https://github.com/ballerina-platform/ballerina-lang/issues/34894 is resolved
            step = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStepSequence);
            // verify that substep is in database
            substep = check database:getTimelineSubstep(step.stepId, substepNr);
            // save input data and update progress
            check database:saveTimelineSubstepParams(step.stepId, substepNr, substepData.parameters, substepData.parametersContentType);
            check database:saveTimelineSubstepInputData(step.stepId, substepNr, experimentId, inputData);
            check commit;
        } on fail error err {
            log:printError("Could not save input data for timeline substep.", 'error = err, stackTrace = err.stackTrace());
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
            check watcher.schedule(...configuredWatcherIntervalls);
        } on fail error err {
            log:printError("Failed to restart watcher.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Failed to restart watcher."};
            return resultErr;
        }
        return mapToTimelineSubstepResponse(experimentId, timelineStepSequence, substep, inputData);
    }

    # Get a list of substeps of a timeline entry.
    #
    # + experimentId - the id of the experiment
    # + timelineStepSequence - the step number of the timeline step
    # + return - the list of timline substeps
    resource function get experiments/[int experimentId]/timeline/[int timelineStepSequence]/substeps() returns TimelineSubstepListResponse|http:InternalServerError {
        // no pagination
        database:TimelineSubstepSQL[] substeps;

        transaction {
            database:TimelineStepWithParams step = check database:getTimelineStep(experimentId = experimentId, sequence = timelineStepSequence);
            substeps = check database:getTimelineSubsteps(step.stepId, experimentId);
            check commit;
        } on fail error err {
            log:printError("Could not get list of timeline substeps.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        TimelineSubstepResponseWithoutParams[] substepsResponse = mapToTimelineSubstepListResponse(experimentId, timelineStepSequence, substeps);
        return {
            '\@self: string `${serverHost}/experiments/${experimentId}/timeline/${timelineStepSequence}/substeps`,
            items: substepsResponse
        };
    }

    # Get a specific substep of a timeline entry.
    #
    # + experimentId - the id of the experiment
    # + timelineStepSequence - the step number of the timeline step
    # + substepNr - the step number of the timeline substep
    # + return - the requested timline substep
    resource function get experiments/[int experimentId]/timeline/[int timelineStepSequence]/substeps/[int substepNr]() returns TimelineSubstepResponseWithParams|http:InternalServerError {
        database:TimelineSubstepWithParams substep;
        database:ExperimentDataReference[] inputData;

        transaction {
            // FIXME timelineStep != database step id!!!! Requested timelineStepSequence is in fact stepId (ui should not know that id) 
            substep = check database:getTimelineSubstepWithParams(experimentId, timelineStepSequence, substepNr);
            inputData = check database:getSubstepInputData(substep.stepId, substep.substepNr);
            check commit;
        } on fail error err {
            log:printError("Could not get timeline substep entry.", 'error = err, stackTrace = err.stackTrace());
            // if with return does not correctly narrow type for rest of function... this does.
            http:InternalServerError resultErr = {body: "Something went wrong. Please try again later."};
            return resultErr;
        }
        return mapToTimelineSubstepResponse(experimentId, timelineStepSequence, substep, inputData);
    }

    resource function get experiments/[int experimentId]/timeline/[int timelineStep]/substeps/[int substepNr]/parameters(http:Caller caller) returns error? {
        database:TimelineSubstepWithParams substep;

        http:Response resp = new;
        resp.addHeader("Access-Control-Allow-Origin", "*");
        resp.addHeader("Access-Control-Allow-Methods", "OPTIONS, GET");
        resp.addHeader("Access-Control-Allow-Headers", "range,Content-Type,Depth,User-Agent,X-File-Size,X-Requested-With,If-Modified-Since,X-File-Name,Cache-Control,Access-Control-Allow-Origin");

        transaction {
            substep = check database:getTimelineSubstepWithParams(experimentId, timelineStep, substepNr);
            check commit;
        } on fail error err {
            log:printError("Could not get parameters for timeline substep.", 'error = err, stackTrace = err.stackTrace());

            resp.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            resp.setPayload("Something went wrong. Please try again later.");

            check caller->respond(resp);
        }

        resp.statusCode = http:STATUS_OK;
        var cType = substep.parametersContentType;
        if cType.startsWith("text/") || cType.startsWith("application/json") || cType.startsWith("application/X-lines+json") {
            resp.addHeader("Content-Disposition", "inline; filename=\"parameters\"");
        } else {
            resp.addHeader("Content-Disposition", "attachment; filename=\"parameters\"");
        }
        resp.setTextPayload(substep.parameters, contentType = substep.parametersContentType);

        check caller->respond(resp);
    }

    # Clone an experiment.
    #
    # + experimentId - the id of the experiment to be cloned
    # + return - the cloned experiment resource
    resource function post experiments/[int experimentId]/clone() returns ExperimentResponse|http:InternalServerError {
        database:ExperimentFull result;
        transaction {
            result = check database:cloneExperiment(experimentId);
            check commit;
        } on fail error err {
            log:printError("Could not clone the experiment.", 'error = err, stackTrace = err.stackTrace());
            return <http:InternalServerError>{body: "Something went wrong. Please try again later."};
        }

        return mapToExperimentResponse(result);
    }

    # Export an experiment as a zip.
    #
    # + experimentId - the id of the experiment to be cloned
    # + exportConfig - configuration of export // TODO
    # + return - the cloned experiment resource
    resource function get experiments/[int experimentId]/export(string? exportConfig, http:Caller caller) returns error? {
        database:ExperimentExportZip experimentZip;
        http:Response resp = new;
        transaction {
            experimentZip = check database:exportExperiment(experimentId, exportConfig);
            check commit;
        } on fail error err {
            log:printError("Exporting experiment unsuccessful.", 'error = err, stackTrace = err.stackTrace());

            resp.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            resp.setPayload("Something went wrong. Please try again later.");

            check caller->respond(resp);
        }

        resp.statusCode = http:STATUS_OK;
        resp.addHeader("Content-Disposition", string `attachment; filename="${experimentZip.name}"`);
        resp.setFileAsPayload(experimentZip.location, contentType = "application/zip");
        // TODO: length? 
        check caller->respond(resp);
    }

    # Import an experiment from a zip.
    #
    # + return - TODO
    @http:ResourceConfig {
        consumes: ["application/json"]
    }
    resource function post experiments/[int experimentId]/'import(http:Caller caller, http:Request request) returns error? {
        stream<byte[], io:Error?> streamer = check request.getByteStream();
        var exists = file:test("tmp", file:EXISTS);
        if exists !is error && !exists {
            check file:createDir("tmp");
        }
        var zipPath = check file:joinPath("tmp", "import.zip"); // TODO: remove if 
        exists = file:test(zipPath, file:EXISTS);
        if exists !is error && exists {
            check file:remove(zipPath);
        }
        check io:fileWriteBlocksFromStream(zipPath, streamer);
        check streamer.close();
        // TODO: import file
        // relative file links need to be made absolute again
    }
}

# Start all ResultWatchers from their DB entries.
public function main() {
    // insert preset plugin runners and plugins into database
    transaction {
        database:PluginEndpointFull|error x;
        foreach string pRunner in preconfiguredPluginRunners {
            x = database:addPluginEndpoint({url: pRunner, 'type: "PluginRunner"});
            if x is error {
                log:printDebug("Could not load preset plugin-runner endpoint", 'error = x, stackTrace = x.stackTrace());
            }
        }
        foreach string plugin in preconfiguredPlugins {
            x = check database:addPluginEndpoint({url: plugin, 'type: "Plugin"});
            if x is error {
                log:printDebug("Could not load preset plugin endpoint", 'error = x, stackTrace = x.stackTrace());
            }
        }
        check commit;
    } on fail error err {
        log:printError("Could not load preset plugin(-runner) endpoints", 'error = err, stackTrace = err.stackTrace());
    }

    // registering background tasks
    transaction {
        var stepsToWatch = check database:getTimelineStepsWithResultWatchers();
        foreach var stepId in stepsToWatch {
            ResultWatcher watcher = check new (stepId);
            check watcher.schedule(...configuredWatcherIntervalls);
        }
        check commit;
    } on fail error err {
        log:printError("Could not start result watchers.", 'error = err, stackTrace = err.stackTrace());
    }
}
