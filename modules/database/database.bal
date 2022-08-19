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

import ballerina/log;
import ballerina/time;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerina/os;
import ballerina/mime;

# The connection pool config for sqlite databases.
sql:ConnectionPool sqlitePool = {
    maxOpenConnections: 5, // limit the concurrent connections as sqlite is not really concurrency friendly
    maxConnectionLifeTime: 1800, // limit keepalive to ensure pool resets faster on errors
    minIdleConnections: 0
};

# Either "sqlite" or "mariadb"
# Can also be configured by setting the `QHANA_DB_TYPE` environment variable.
configurable string dbType = "sqlite";

// sqlite specific config
# File Path to the sqlite db
# Can also be configured by setting the `QHANA_DB_PATH` environment variable.
configurable string dbPath = "qhana-backend.db";

// mariadb specific config
# Hostname + port for mariadb db
# Can also be configured by setting the `QHANA_DB_HOST` environment variable.
configurable string dbHost = "localhost:3306";
# DB name for mariadb db
# Can also be configured by setting the `QHANA_DB_NAME` environment variable.
configurable string dbName = "QHAnaExperiments";
# DB user for mariadb db
# Can also be configured by setting the `QHANA_DB_USER` environment variable.
configurable string dbUser = "QHAna";
# DB password for mariadb db
# Can also be configured by setting the `QHANA_DB_PASSWORD` environment variable.
configurable string dbPassword = "";

# Get the db type from the `QHANA_DB_TYPE` environment variable.
# If not present use the configurable variable `dbType` as fallback.
#
# + return - the configured db type
function getDBType() returns string {
    string d = os:getEnv("QHANA_DB_TYPE");
    if (d.length() > 0) {
        return d;
    }
    return dbType;
}

# The final configured db type.
final string & readonly configuredDBType = getDBType().cloneReadOnly();

# Initialize the database client from the supplied config.
#
# Also reads config from environment variables.
#
# + return - the created client or an error
function initClient() returns jdbc:Client|error {
    // load config from env vars
    var dbPathLocal = os:getEnv("QHANA_DB_PATH");
    if (dbPathLocal.length() == 0) {
        dbPathLocal = dbPath;
    }
    var dbHostLocal = os:getEnv("QHANA_DB_HOST");
    if (dbHostLocal.length() == 0) {
        dbHostLocal = dbHost;
    }
    var dbNameLocal = os:getEnv("QHANA_DB_NAME");
    if (dbNameLocal.length() == 0) {
        dbNameLocal = dbName;
    }
    var dbUserLocal = os:getEnv("QHANA_DB_USER");
    if (dbUserLocal.length() == 0) {
        dbUserLocal = dbUser;
    }
    var dbPasswordLocal = os:getEnv("QHANA_DB_PASSWORD");
    if (dbPasswordLocal.length() == 0) {
        dbPasswordLocal = dbPassword;
    }

    // use config options to create db client
    if configuredDBType == "sqlite" {
        return new jdbc:Client(string `jdbc:sqlite:${dbPathLocal}`, connectionPool = sqlitePool);
    } else if configuredDBType == "mariadb" || configuredDBType == "mysql" {
        string connection = string `jdbc:mariadb://${dbHostLocal}/${dbNameLocal}?user=${dbUserLocal}`;
        if dbPasswordLocal != "" {
            string passwordPart = string `&password=${dbPasswordLocal}`;
            connection = connection + passwordPart;
        }
        log:printDebug(connection); // FIXME remove to stop outputting password to stdout
        return new jdbc:Client(connection);
    } else {
        return error(string `Db type ${configuredDBType} is unknownn!`);
    }
}

// always provide an initialized dummy jdbc client to circumvent null handling in every method
# the database client used by all database functions
final jdbc:Client experimentDB = check initClient();

# A record holding a single row count.
#
# + rowCount - the row count
type RowCount record {
    int rowCount;
};

# Database record of plugin endpoints.
#
# + url - the URL of the plugin endpoint
# + 'type - the type of the plugin endpoint
public type PluginEndpoint record {|
    string url;
    string 'type = "PluginRunner";
|};

# Full database record of plugin endpoints with the database id.
#
# + id - the id of the plugin record in the database
public type PluginEndpointFull record {|
    readonly int id;
    *PluginEndpoint;
|};

// Experiments /////////////////////////////////////////////////////////////////

# Record containing the pure data of an Experiment.
#
# + name - The experiment name
# + description - The experiment description
public type Experiment record {|
    string name;
    string description = "";
|};

# Record containing the experiment data and the database ID of the Experiment
#
# + experimentId - The database id of the record
public type ExperimentFull record {|
    readonly int experimentId;
    *Experiment;
|};

// Data ////////////////////////////////////////////////////////////////////////

# Database record of references to experiment data.
#
# + name - the (file-)name of the experiment data
# + 'version - the version of the data
public type ExperimentDataReference record {|
    string name;
    int 'version;
|};

# Record specifying data and content type tags.
#
# + dataType - the data type (what kind of data)
# + contentType - the content type or mimetype (how is the data stored)
type DataTypeTuple record {|
    string dataType;
    string contentType;
|};

# Database record for experiment data.
#
# + location - the path where the data is stored
# + 'type - the data type of the stored data
# + contentType - the content type of the stored data
public type ExperimentData record {|
    *ExperimentDataReference;
    string location;
    string 'type;
    string contentType;
|};

# Full database record for experiment data.
#
# + dataId - the database id of the record
# + experimentId - the id of the experiment this data is part of
public type ExperimentDataFull record {|
    readonly int dataId;
    readonly int experimentId;
    *ExperimentData;
|};

// Timeline ////////////////////////////////////////////////////////////////////

# Database result progress record.
#
# + progressStart - the start value of the progress (defaults to 0)
# + progressTarget - the target value, e.g., the value where the progress is considered 100% done (defaults to 100)
# + progressValue - the current progress value
# + progressUnit - the unit the progress is counted in, e.g., %, minutes, steps, error rate, etc. (defaults to "%")
public type Progress record {|
    float? progressStart = 0;
    float? progressTarget = 100;
    float? progressValue = ();
    string? progressUnit = "%";
|};

# Record of a reference to a timeline step.
#
# + experimentId - the experiment id
# + sequence - the sequence number of the step in the experiment
public type TimelineStepRef record {|
    readonly int experimentId;
    readonly int sequence;
|};

# Database record of a reference to a timeline step.
#
# + stepId - the database id of the timeline step
public type TimelineStepDbRef record {|
    readonly int stepId;
|};

# Database record of a timeline step.
#
# + 'start - the time when the timeline step was created
# + end - the time when a result or error was recorded for the timeline step
# + status - the current status of the timeline step result
# + resultQuality - the result quality
# + resultLog - the log output that is part of the result
# + processorName - the plugin handling the computation for this step
# + processorVersion - the version of the plugin
# + processorLocation - the root URL of the plugin
# + parameters - the parameters used to invoke the plugin with
# + parametersContentType - the content type of the serialized parameters
# + notes - the text of the notes stored for this step
public type TimelineStep record {|
    time:Utc 'start;
    time:Utc? end = ();
    string status = "PENDING";
    string resultQuality = "UNKNOWN";
    string? resultLog = ();
    string processorName;
    string? processorVersion = ();
    string? processorLocation = ();
    string parameters?; // optional for small requests
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    string notes?; // optional for small requests
    *Progress;
|};

# Full database record of a timeline step containing the database id of the step.
public type TimelineStepFull record {|
    *TimelineStepDbRef;
    *TimelineStepRef;
    *TimelineStep;
|};

# Helper type used in SQL queries to get around issues with converting times 
# to strings and back in sqlite databases.
#
# + 'start - the time when the timeline step was created
# + end - the time when a result or error was recorded for the timeline step
# + status - the current status of the timeline step result
# + resultQuality - the result quality
# + resultLog - the log output that is part of the result
# + processorName - the plugin handling the computation for this step
# + processorVersion - the version of the plugin
# + processorLocation - the root URL of the plugin
# + parameters - the parameters used to invoke the plugin with
# + parametersContentType - the content type of the serialized parameters
# + notes - the text of the notes stored for this step
public type TimelineStepSQL record {|
    *TimelineStepDbRef;
    *TimelineStepRef;
    string|time:Utc 'start;
    string|time:Utc|() end = ();
    string status = "PENDING";
    string resultQuality = "UNKNOWN";
    string? resultLog = ();
    string processorName;
    string? processorVersion = ();
    string? processorLocation = ();
    string parameters?; // optional for small requests
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
    string notes?; // optional for small requests
    *Progress;
|};

# Database record of a timeline step but with mandatory parameters field.
#
# + parameters - the parameters used to invoke the plugin with
public type TimelineStepWithParams record {|
    *TimelineStepFull;
    string parameters;
|};

# Database record of timeline substeps.
#
# + substepId - the string id assigned to the substep by the plugin
# + href - the URL to the resource accepting the substep input
# + hrefUi - the URL of the corresponding micro frontend
# + cleared - a boolean flag to indicate whether the substep is cleared
public type TimelineSubstep record {|
    string? substepId;
    string href;
    string? hrefUi;
    int cleared;
|};

# Full database record of timeline substeps without parameters.
#
# + substepNr - 1 based substep index 
# + stepId - id of associated step
# + inputData - input data of the substep
public type TimelineSubstepSQL record {|
    *TimelineSubstep;
    int substepNr;
    int stepId;
    ExperimentDataReference[] inputData?;
|};

# Full database record of timeline substeps including parameters.
#
# + parameters - the parameters which were input for this substep
# + parametersContentType - the content type of these parameters
public type TimelineSubstepWithParams record {|
    *TimelineSubstepSQL;
    string parameters;
    string parametersContentType = mime:APPLICATION_FORM_URLENCODED;
|};

// Timeline to Data links //////////////////////////////////////////////////////

# Database record of a relation between a timeline step and its input/output data.
#
# + stepId - the database id of the timeline step
# + dataId - the database id of the data
# + relationType - the type of the relation (e.g. input/output)
public type StepToData record {|
    readonly int stepId;
    readonly int dataId;
    string relationType;
|};

public isolated transactional function getPluginEndpointsCount() returns int|error {
    stream<RowCount, sql:Error?> result = experimentDB->query(`SELECT count(*) AS rowCount FROM PluginEndpoints;`);
    var count = result.next();
    check result.close();
    if count is error {
        return count;
    }
    if count is record {RowCount value;} {
        return count.value.rowCount;
    } else {
        // should never happen based on the sql query
        return error("Could not determine the plugin endpoint count!");
    }
}

public isolated transactional function getPluginEndpoints() returns PluginEndpointFull[]|error {
    stream<PluginEndpointFull, sql:Error?> endpoints = experimentDB->query(
        `SELECT id, url, type FROM PluginEndpoints ORDER BY type, url;`
    );

    PluginEndpointFull[]? endpointList = check from var endpoint in endpoints
        select endpoint;

    check endpoints.close();

    if endpointList != () {
        return endpointList;
    }

    return [];
}

public isolated transactional function getPluginEndpoint(int endpointId) returns PluginEndpointFull|error {
    stream<PluginEndpointFull, sql:Error?> endpoints = experimentDB->query(
        `SELECT id, url, type FROM PluginEndpoints WHERE id=${endpointId};`
    );

    var endpoint = endpoints.next();
    check endpoints.close();

    if !(endpoint is sql:Error) && (endpoint != ()) {
        return endpoint.value;
    }

    return error(string `Endpoint with id ${endpointId} was not found!`);
}

public isolated transactional function addPluginEndpoint(*PluginEndpoint endpoint) returns PluginEndpointFull|error {
    var result = check experimentDB->execute(
        `INSERT INTO PluginEndpoints (url, type) VALUES (${endpoint.url}, ${endpoint.'type});`
    );

    var endpointId = result.lastInsertId;

    if !(endpointId is int) {
        return error("Could not parse last insert id for endpoint.");
    } else {
        return {
            id: endpointId,
            url: endpoint.url,
            'type: endpoint.'type
        };
    }
}

public isolated transactional function editPluginEndpoint(int endpointId, string 'type) returns PluginEndpointFull|error {
    _ = check experimentDB->execute(
        `UPDATE PluginEndpoints SET type=${'type} WHERE id=${endpointId};`
    );

    return getPluginEndpoint(endpointId);
}

public isolated transactional function deletePluginEndpoint(int endpointId) returns error? {
    var result = experimentDB->execute(
        `DELETE FROM PluginEndpoints WHERE id=${endpointId};`
    );

    if result is error {
        return result;
    } else {
        return;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Experiments /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Return the number of experiments in the database.
#
# + return - The number of experiments or the encountered error
public isolated transactional function getExperimentCount() returns int|error {
    stream<RowCount, sql:Error?> result = experimentDB->query(`SELECT count(*) AS rowCount FROM Experiment;`);
    var count = result.next();
    check result.close();
    if count is error {
        return count;
    }
    if count is record {RowCount value;} {
        return count.value.rowCount;
    } else {
        // should never happen based on the sql query
        return error("Could not determine the experiment count!");
    }
}

# Get the list of experiments from the database.
#
# + 'limit - The maximum number of experiments fetched in one call (default: `100`)
# + offset - The offset applied to the sql query (default: `0`)
# + return - The list of experiments or the encountered error
public isolated transactional function getExperiments(int 'limit = 100, int offset = 0) returns ExperimentFull[]|error {
    stream<ExperimentFull, sql:Error?> experiments = experimentDB->query(
        `SELECT experimentId, name, description FROM Experiment ORDER BY name ASC LIMIT ${'limit} OFFSET ${offset};`
    );

    ExperimentFull[]? experimentList = check from var experiment in experiments
        select experiment;

    check experiments.close();

    if experimentList != () {
        return experimentList;
    }

    return [];
}

# Get a single experiment from the database.
#
# + experimentId - The database id of the experiment to fetch
# + return - The experiment or the encountered error
public isolated transactional function getExperiment(int experimentId) returns ExperimentFull|error {
    stream<ExperimentFull, sql:Error?> experiments = experimentDB->query(
        `SELECT experimentId, name, description FROM Experiment WHERE experimentId = ${experimentId} LIMIT 1;`
    );

    var experiment = experiments.next();
    check experiments.close();

    if !(experiment is sql:Error) && (experiment != ()) {
        return experiment.value;
    }

    return error(string `Experiment ${experimentId} was not found!`);
}

# Create a new experiment in the database.
#
# + experiment - The data for the new experiment
# + return - The experiment data including the database id or the encountered error
public isolated transactional function createExperiment(*Experiment experiment) returns ExperimentFull|error {
    ExperimentFull? result = ();

    var insertResult = check experimentDB->execute(
        `INSERT INTO Experiment (name, description) VALUES (${experiment.name}, ${experiment.description});`
    );

    // extract experiment id and build full experiment data
    var experimentId = insertResult.lastInsertId;
    if experimentId is string {
        fail error("Expected integer id but got a string!");
    } else if experimentId == () {
        fail error("Expected the experiment id back but got nothing!");
    } else {
        result = {experimentId: experimentId, name: experiment.name, description: experiment.description};
    }

    if result == () {
        // this should logically never happen but is included for the compiler
        return error("Experiment was empty after transaction comitted.");
    } else {
        return result;
    }
}

# Update an existing experiment in place in the database.
#
# + experimentId - The database id of the experiment to update
# + experiment - The updated data for the existing experiment
# + return - The updated experiment data including the database id or the encountered error
public isolated transactional function updateExperiment(int experimentId, *Experiment experiment) returns ExperimentFull|error {
    _ = check experimentDB->execute(
        `UPDATE Experiment SET name=${experiment.name}, description=${experiment.description} WHERE experimentId = ${experimentId};`
    );
    return {experimentId, name: experiment.name, description: experiment.description};
}

////////////////////////////////////////////////////////////////////////////////
// Data ////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

# Get the number of data entries for a specific experiment.
#
# + experimentId - The experiment id
# + all - If true count all experiment data including old version, if false count only the newest verwions (e.g. distinct data names)
# + return - The count or the encountered error
public isolated transactional function getExperimentDataCount(int experimentId, boolean all = true) returns int|error {
    stream<RowCount, sql:Error?> result;
    if all {
        result = experimentDB->query(`SELECT count(*) AS rowCount FROM ExperimentData WHERE experimentId = ${experimentId};`);
    } else {
        result = experimentDB->query(`SELECT count(DISTINCT name) AS rowCount FROM ExperimentData WHERE experimentId = ${experimentId};`);
    }
    var count = result.next();

    check result.close();
    if count is record {RowCount value;} {
        return count.value.rowCount;
    } else if count is error {
        return count;
    } else {
        // should never happen based on the sql query
        return error("Could not determine the experiment count!");
    }
}

public isolated transactional function getDataTypesSummary(int experimentId) returns map<string[]>|error {
    stream<DataTypeTuple, sql:Error?> dataSummaryRaw = experimentDB->query(`SELECT DISTINCT type as dataType, contentType from ExperimentData WHERE experimentId=${experimentId} GROUP BY type ORDER BY type, contentType;`);

    map<string[]> dataSummary = {};
    check from var dt in dataSummaryRaw
        do {
            string[]? contentTypes = dataSummary[dt.dataType];
            if contentTypes == () {
                dataSummary[dt.dataType] = [dt.contentType];
            } else {
                contentTypes.push(dt.dataType);
                dataSummary[dt.dataType] = contentTypes;
            }
        };

    check dataSummaryRaw.close();

    return dataSummary;
}

public isolated transactional function getDataList(int experimentId, boolean all = true, int 'limit = 100, int offset = 0) returns ExperimentDataFull[]|error {
    sql:ParameterizedQuery baseQuery = `SELECT dataId, experimentId, name, version, location, type, contentType 
                     FROM ExperimentData WHERE experimentId=${experimentId} `;
    sql:ParameterizedQuery baseQuerySuffix = `ORDER BY name ASC, version DESC 
                           LIMIT ${'limit} OFFSET ${offset};`;

    stream<ExperimentDataFull, sql:Error?> experimentData;
    if all {
        experimentData = experimentDB->query(sql:queryConcat(baseQuery, baseQuerySuffix));
    } else {
        sql:ParameterizedQuery extraFilter = `AND version=(SELECT MAX(t2.version)
                                FROM ExperimentData AS t2 
                                WHERE ExperimentData.name=t2.name AND t2.experimentId=${experimentId}) `;
        experimentData = experimentDB->query(sql:queryConcat(baseQuery, extraFilter, baseQuerySuffix));
    }

    ExperimentDataFull[]? experimentDataList = check from var data in experimentData
        select data;

    check experimentData.close();

    if experimentDataList != () {
        return experimentDataList;
    }

    return [];
}

public isolated transactional function getData(int experimentId, string name, string|int|() 'version) returns ExperimentDataFull|error {
    sql:ParameterizedQuery baseQuery = `SELECT dataId, experimentId, name, version, location, type, contentType 
                     FROM ExperimentData WHERE experimentId=${experimentId} AND name=${name}`;
    stream<ExperimentDataFull, sql:Error?> data;

    if 'version == () || 'version == "latest" {
        // get latest version with order by descending and limit to one
        data = experimentDB->query(sql:queryConcat(baseQuery, ` ORDER BY version DESC LIMIT 1;`));
    } else {
        // get a specific version with order by descending and limit to one
        data = experimentDB->query(sql:queryConcat(baseQuery, ` AND version=${'version} LIMIT 1;`));
    }

    var result = data.next();
    check data.close();

    if !(result is sql:Error) && (result != ()) {
        return result.value;
    }

    return error(string `Experiment data with experimentId: ${experimentId}, name: ${name} and version: ${'version == () ? "latest" : 'version} was not found!`);
}

public isolated transactional function getProducingStepOfData(int|ExperimentDataFull data) returns int|error {
    stream<record {int producingStep;}, sql:Error?> step;

    final var dataId = (data is int) ? data : data.dataId;
    step = experimentDB->query(
        `SELECT sequence AS producingStep FROM StepData JOIN TimelineStep ON StepData.stepId = TimelineStep.stepId 
         WHERE relationType = "output" and dataId = ${dataId} LIMIT 1;`
    );

    var result = step.next();
    check step.close();

    if !(result is sql:Error) && (result != ()) {
        return result.value.producingStep;
    }

    return error(string `Experiment data with dataId: ${dataId} has no producing step!`);
}

public isolated transactional function getStepsUsingData(int|ExperimentDataFull data) returns int[]|error {
    stream<record {int sequence;}, sql:Error?> steps;

    final var dataId = (data is int) ? data : data.dataId;
    steps = experimentDB->query(
        `SELECT sequence FROM StepData JOIN TimelineStep ON StepData.stepId = TimelineStep.stepId 
         WHERE relationType = "input" and dataId = ${dataId} LIMIT 1;`
    );

    int[]|error? inputForSteps = from var step in steps
        select step.sequence;

    check steps.close();

    if inputForSteps is () {
        return [];
    } else if !(inputForSteps is error) {
        return inputForSteps;
    }

    return error(string `Experiment data with dataId: ${dataId} has no producing step!`);
}

////////////////////////////////////////////////////////////////////////////////
// Timeline ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public isolated transactional function getTimelineStepCount(int experimentId, string? plugin\-name, string? 'version, string? status, int? uncleared\-substep) returns int|error {
    sql:ParameterizedQuery query = `SELECT count(*) AS rowCount FROM TimelineStep `;
    if uncleared\-substep != () {
        query = sql:queryConcat(query, `JOIN TimelineSubstep ON TimelineStep.stepId = TimelineSubstep.stepId `);
    }
    query = sql:queryConcat(query, `WHERE experimentId = ${experimentId}`);
    if plugin\-name != () {
        query = sql:queryConcat(query, ` AND processorName = ${plugin\-name}`);
    }
    if 'version != () {
        query = sql:queryConcat(query, ` AND processorVersion = ${'version}`);
    }
    if status != () {
        query = sql:queryConcat(query, ` AND status = ${status}`);
    }
    if uncleared\-substep != () {
        // (COUNT(*) - SUM(TimelineSubstep.cleared)) is the number of uncleared substeps (at most 1)
        // e.g., must be 1 if uncleared substep is required (uncleared\-substep = 1)
        query = sql:queryConcat(query, ` GROUP BY TimelineStep.stepId HAVING (COUNT(*) - SUM(TimelineSubstep.cleared))=${uncleared\-substep}`);
    }

    stream<RowCount, sql:Error?> result = experimentDB->query(
        sql:queryConcat(query, `;`)
    );

    var count = result.next();
    check result.close();

    if count is record {RowCount value;} {
        return count.value.rowCount;
    } else if count is error {
        return count;
    } else {
        // should never happen based on the sql query
        return error("Could not determine the experiment count!");
    }
}

public isolated transactional function castToTimelineStepFull(TimelineStepSQL step) returns TimelineStepFull|error {
    var startString = step.'start; // needed for correct type narrowing
    if startString is string {
        var utcString = startString; // needed for correct type narrowing
        if !startString.endsWith("Z") {
            utcString += ".00Z";
        }
        time:Utc 'start = check time:utcFromString(utcString);
        step.'start = 'start;
    }
    var endString = step.end; // needed for correct type narrowing
    if endString is string {
        var utcString = endString; // needed for correct type narrowing
        if !endString.endsWith("Z") {
            utcString += ".00Z";
        }
        time:Utc end = check time:utcFromString(utcString);
        step.end = end;
    }
    return step.cloneWithType();
}

public isolated transactional function getTimelineStepList(int experimentId, string? plugin\-name, string? 'version, string? status, int? uncleared\-substep, boolean allAttributes = false, int 'limit = 100, int offset = 0) returns TimelineStepFull[]|error {

    sql:ParameterizedQuery baseQuery = `SELECT TimelineStep.stepId, experimentId, sequence, `;
    if configuredDBType == "sqlite" {
        baseQuery = sql:queryConcat(baseQuery, `cast(start as TEXT) AS start, cast(end as TEXT) AS end, `);
    } else {
        baseQuery = sql:queryConcat(baseQuery, `DATE_FORMAT(start, '%Y-%m-%dT%H:%i:%S') AS start, DATE_FORMAT(end, '%Y-%m-%dT%H:%i:%S') AS end, `);
    }
    baseQuery = sql:queryConcat(baseQuery, `status, processorName, processorVersion, processorLocation `);
    if allAttributes {
        baseQuery = sql:queryConcat(baseQuery, `, resultQuality, resultLog, TimelineSubstep.parameters, TimelineSubstep.parametersContentType, notes `);
    } else {
        baseQuery = sql:queryConcat(baseQuery, `, resultQuality, NULL AS resultLog `);
    }
    baseQuery = sql:queryConcat(baseQuery, `FROM TimelineStep `);

    if uncleared\-substep != () {
        baseQuery = sql:queryConcat(baseQuery, `JOIN TimelineSubstep ON TimelineStep.stepId = TimelineSubstep.stepId `);
    }

    baseQuery = sql:queryConcat(baseQuery, `WHERE experimentId=${experimentId}`);

    if plugin\-name != () {
        baseQuery = sql:queryConcat(baseQuery, ` AND processorName = ${plugin\-name}`);
    }
    if 'version != () {
        baseQuery = sql:queryConcat(baseQuery, ` AND processorVersion = ${'version}`);
    }
    if status != () {
        baseQuery = sql:queryConcat(baseQuery, ` AND status = ${status}`);
    }
    // filtering for (un)cleared substeps
    if uncleared\-substep != () {
        // (COUNT(*) - SUM(TimelineSubstep.cleared)) is the number of uncleared substeps (at most 1)
        // e.g., must be 1 if uncleared substep is required (uncleared\-substep = 1)
        baseQuery = sql:queryConcat(baseQuery, ` GROUP BY TimelineStep.stepId HAVING (COUNT(*) - SUM(TimelineSubstep.cleared))=${uncleared\-substep}`);
    }

    stream<TimelineStepSQL, sql:Error?> timelineSteps = experimentDB->query(check new ConcatQuery(baseQuery, ` ORDER BY sequence ASC LIMIT ${'limit} OFFSET ${offset};`));

    (TimelineStepSQL|TimelineStepFull)[]|error|() tempList = from var step in timelineSteps
        select step;

    check timelineSteps.close();

    TimelineStepFull[] stepList = [];
    if tempList is error {
        return tempList;
    } else if tempList is () {
        return [];
    } else {
        // convert timestamps to correct utc type if timestamps come from sqlite
        foreach var step in tempList {
            TimelineStepFull stepFull = check castToTimelineStepFull(step);
            stepList.push(stepFull);
        }
    }

    return stepList;
}

public isolated transactional function createTimelineStep(
        int experimentId,
        string processorName,
        string? processorVersion = (),
        string? processorLocation = (),
        string? parameters = (),
        string? parametersContentType = mime:APPLICATION_FORM_URLENCODED
) returns TimelineStepWithParams|error {
    if parameters == () && parametersContentType == () {
        return error("When parameters are given the parameters content type is required!");
    }

    sql:ParameterizedQuery currentTime = `strftime('%Y-%m-%dT%H:%M:%S', 'now')`;
    if configuredDBType != "sqlite" {
        currentTime = `DATE_FORMAT(UTC_TIMESTAMP(), '%Y-%m-%dT%H:%i:%S')`;
    }
    var insertResult = check experimentDB->execute(
        sql:queryConcat(
            `INSERT INTO TimelineStep (experimentId, sequence, start, end, processorName, processorVersion, processorLocation, parameters, parametersContentType) 
            VALUES (${experimentId}, (SELECT sequence from (SELECT count(*)+1 AS sequence FROM TimelineStep WHERE experimentId = ${experimentId}) subquery), `,
            currentTime,
            `, NULL, ${processorName}, ${processorVersion}, ${processorLocation}, ${parameters}, ${parametersContentType});`
        )
    );

    // extract experiment id and build full experiment data
    var stepId = insertResult.lastInsertId;
    if stepId is string {
        fail error("Expected integer id but got a string!");
    } else if stepId == () {
        fail error("Expected the experiment id back but got nothing!");
    } else {
        int s = check stepId.ensureType();
        return getTimelineStep(stepId = s);
    }
}

public isolated transactional function getTimelineStep(int? experimentId = (), int? sequence = (), int? stepId = ()) returns TimelineStepWithParams|error {
    sql:ParameterizedQuery baseQuery = `SELECT stepId, experimentId, sequence, cast(start as TEXT) AS start, cast(end as TEXT) AS end, status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart AS progressStart, pTarget AS progressTarget, pValue AS progressValue, pUnit AS progressUnit
                     FROM TimelineStep `;
    if configuredDBType != "sqlite" {
        baseQuery = `SELECT stepId, experimentId, sequence, DATE_FORMAT(start, '%Y-%m-%dT%H:%i:%S') AS start, DATE_FORMAT(end, '%Y-%m-%dT%H:%i:%S') AS end, status, resultQuality, resultLog, processorName, processorVersion, processorLocation, parameters, parametersContentType, pStart AS progressStart, pTarget AS progressTarget, pValue AS progressValue, pUnit AS progressUnit
                     FROM TimelineStep `;
    }

    stream<TimelineStepSQL, sql:Error?> timelineStep;

    TimelineStepRef|TimelineStepDbRef ref;

    if experimentId == () && sequence == () && stepId == () {
        return error("Must provide either experimentId and sequence or the stepId!");
    } else if experimentId != () && sequence != () && stepId != () {
        return error("Must not provide all parameters at the same time!");
    } else if experimentId != () && sequence != () {
        timelineStep = experimentDB->query(
            sql:queryConcat(baseQuery, `WHERE experimentId=${experimentId} AND sequence=${sequence} LIMIT 1;`)
        );
        ref = {experimentId: experimentId, sequence: sequence};
    } else if stepId != () {
        timelineStep = experimentDB->query(sql:queryConcat(baseQuery, `WHERE stepId=${stepId} LIMIT 1;`));
        ref = {stepId: stepId};
    } else {
        return error("Must provide either experimentId and sequence or the stepId!");
    }

    var result = timelineStep.next();
    check timelineStep.close();

    if !(result is sql:Error) && (result != ()) {
        TimelineStepFull|error stepFull = castToTimelineStepFull(result.value);
        if stepFull is error {
            return error(string `The Timeline step with reference ${ref.toString()} could not be read from the database!`, stepFull);
        } else {
            TimelineStepWithParams|error step = stepFull.cloneWithType(TimelineStepWithParams);
            if step is error {
                return error(string `The Timeline step with reference ${ref.toString()} did not have the required parameters field!`, step);
            }
            return step;
        }
    }

    return error(string `Timeline step with reference ${ref.toString()} was not found!`);
}

public isolated transactional function updateTimelineStepStatus(int|TimelineStepFull step, string status, string? resultLog) returns error? {
    var stepId = step is int ? step : step.stepId;
    sql:ParameterizedQuery currentTime = `strftime('%Y-%m-%dT%H:%M:%S', 'now')`;
    if configuredDBType != "sqlite" {
        currentTime = `DATE_FORMAT(UTC_TIMESTAMP(), '%Y-%m-%dT%H:%i:%S')`;
    }

    _ = check experimentDB->execute(
        sql:queryConcat(
            `UPDATE TimelineStep 
                SET 
                    end=`, currentTime, `, 
                    status=${status},
                    resultLog=${resultLog}
                WHERE stepId = ${stepId} AND end IS NULL;`
        )
    );
}

public isolated transactional function updateTimelineTaskLog(int|TimelineStepFull step, string? resultLog) returns error? {
    var stepId = step is int ? step : step.stepId;
    _ = check experimentDB->execute(`UPDATE TimelineStep 
            SET resultLog=${resultLog}
            WHERE stepId = ${stepId};`);
}

public isolated transactional function getStepInputData(int|TimelineStepFull step) returns ExperimentDataReference[]|error {
    stream<ExperimentDataReference, sql:Error?> inputData;

    var stepId = step is int ? step : step.stepId;
    inputData = experimentDB->query(
        `SELECT name, version FROM StepData JOIN ExperimentData ON StepData.dataId = ExperimentData.dataId 
         WHERE relationType = "input" and stepId = ${stepId};`
    );

    ExperimentDataReference[]|error? inputDataList = from var row in inputData
        select row;
    check inputData.close();

    if inputDataList is () {
        return [];
    } else if !(inputDataList is error) {
        return inputDataList;
    }

    return error(string `Failed to retrieve input data for experiment step with stepId ${stepId}!`);
}

public isolated transactional function saveTimelineStepInputData(int stepId, int experimentId, ExperimentDataReference[] inputData) returns error? {
    foreach var data in inputData {
        var experimentData = check getData(experimentId, data.name, data.'version);
        _ = check experimentDB->execute(`INSERT INTO StepData (stepId, dataId, relationType) VALUES (${stepId}, ${experimentData.dataId}, ${"input"});`);
    }
}

public isolated transactional function getStepOutputData(int|TimelineStepFull step) returns ExperimentDataReference[]|error {
    stream<ExperimentDataReference, sql:Error?> outputData;

    var stepId = step is int ? step : step.stepId;
    outputData = experimentDB->query(
        `SELECT name, version FROM StepData JOIN ExperimentData ON StepData.dataId = ExperimentData.dataId 
         WHERE relationType = "output" and stepId = ${stepId};`
    );

    ExperimentDataReference[]|error? outputDataList = from var row in outputData
        select row;
    check outputData.close();

    if outputDataList is () {
        return [];
    } else if !(outputDataList is error) {
        return outputDataList;
    }

    return error(string `Failed to retrieve output data for experiment step with stepId ${stepId}!`);
}

public isolated transactional function saveTimelineStepOutputData(int stepId, int experimentId, ExperimentData[] outputData) returns error? {
    sql:ParameterizedQuery baseQuery = `INSERT INTO ExperimentData (experimentId, name, version, location, type, contentType) VALUES `;
    sql:ParameterizedQuery[] dataQuery = from var d in outputData
        select `(${experimentId}, ${d.name}, (SELECT version FROM (SELECT count(*) + 1 AS version FROM ExperimentData WHERE name = ${d.name}) subquery), ${d.location}, ${d.'type}, ${d.contentType})`;

    foreach var insertData in dataQuery {
        var result = check experimentDB->execute(sql:queryConcat(baseQuery, insertData));
        var dataId = result.lastInsertId;
        _ = check experimentDB->execute(`INSERT INTO StepData (stepId, dataId, relationType) VALUES (${stepId}, ${dataId}, ${"output"});`);
    }
}

public isolated transactional function getTimelineStepNotes(int experimentId, int sequence) returns string|error {
    stream<record {|string? notes;|}, sql:Error?> note = experimentDB->query(
        `SELECT notes
         FROM TimelineStep WHERE experimentId=${experimentId} AND sequence=${sequence} LIMIT 1;`
    );

    var result = note.next();
    check note.close();

    if !(result is sql:Error) && (result != ()) {
        var notesText = result.value.notes;
        if notesText == () {
            return "";
        } else {
            return notesText;
        }
    }

    return error(string `Notes for timeline step with experimentId: ${experimentId} and sequence: ${sequence} were not found!`);
}

public isolated transactional function updateTimelineStepNotes(int experimentId, int sequence, string notes) returns error? {
    _ = check experimentDB->execute(
        `UPDATE TimelineStep SET notes=${notes} WHERE experimentId = ${experimentId} AND sequence=${sequence};`
    );
}

public isolated transactional function updateTimelineStepResultQuality(int experimentId, int sequence, string resultQuality) returns error? {
    var test = check experimentDB->execute(
        `UPDATE TimelineStep SET resultQuality=${resultQuality} WHERE experimentId = ${experimentId} AND sequence=${sequence};`
    );
}

public isolated transactional function getTimelineStepsWithResultWatchers() returns int[]|error {
    stream<record {int stepId;}, sql:Error?> stepWatchers = experimentDB->query(
        `SELECT stepId FROM ResultWatchers;`
    );
    int[]|error|() result = from var watcher in stepWatchers
        select watcher.stepId;
    check stepWatchers.close();

    if result is () {
        return [];
    } else {
        return result;
    }
}

public isolated transactional function createTimelineStepResultWatcher(int stepId, string resultEndpoint) returns error? {
    if resultEndpoint == "" {
        return error("Result endpoint cannot be empty!");
    }
    _ = check experimentDB->execute(
        `INSERT INTO ResultWatchers (stepId, resultEndpoint) 
         VALUES (${stepId}, ${resultEndpoint});`
    );
}

public isolated transactional function getTimelineStepResultEndpoint(int stepId) returns string?|error {
    stream<record {string resultEndpoint;}, sql:Error?> result = experimentDB->query(
        `SELECT resultEndpoint FROM ResultWatchers WHERE stepId = ${stepId};`
    );
    var first = result.next();
    check result.close();

    if first is record {record {string resultEndpoint;} value;} {
        return first.value.resultEndpoint;
    } else {
        return first;
    }
}

public isolated transactional function deleteTimelineStepResultWatcher(int stepId) returns error? {
    _ = check experimentDB->execute(
        `DELETE FROM ResultWatchers WHERE stepId = ${stepId};`
    );
}

public isolated transactional function getTimelineSubsteps(int stepId, int? experimentId = ()) returns TimelineSubstepSQL[]|error {

    stream<TimelineSubstepSQL, sql:Error?> substeps;
    if (experimentId is ()) {
        // experimentId is nil, use stepId as database id
        substeps = experimentDB->query(
            `SELECT stepId, substepNr, substepId, href, hrefUi, cleared FROM TimelineSubstep WHERE stepId=${stepId} ORDER BY substepNr ASC;`
        );
    } else {
        // experimentId was given, use stepId as step sequence
        substeps = experimentDB->query(
            `SELECT 
                    TimelineSubstep.stepId, substepNr, substepId, href, hrefUi, cleared
                FROM TimelineSubstep JOIN TimelineStep ON TimelineSubstep.stepId=TimelineStep.stepId
                WHERE TimelineStep.experimentId=${experimentId} AND TimelineStep.sequence=${stepId} ORDER BY substepNr ASC;`
        );
    }
    TimelineSubstepSQL[]|error|() result = check from var substep in substeps
        select substep;
    check substeps.close();

    if result is () {
        return [];
    } else {
        return result;
    }
}

public isolated transactional function getTimelineSubstepsWithInputData(int stepId) returns TimelineSubstepSQL[]|error {
    TimelineSubstepSQL[]|error tempSubsteps = getTimelineSubsteps(stepId);
    // add mapping of input data to substeps
    if !(tempSubsteps is error) {
        TimelineSubstepSQL[] substeps = [];
        foreach TimelineSubstepSQL tempSubstep in tempSubsteps {
            ExperimentDataReference[] substepInputData = check getSubstepInputData(stepId, tempSubstep.substepNr);
            TimelineSubstepSQL substep = {
                stepId: tempSubstep.stepId,
                substepNr: tempSubstep.substepNr,
                substepId: tempSubstep.substepId,
                href: tempSubstep.href,
                hrefUi: tempSubstep.hrefUi,
                cleared: tempSubstep.cleared,
                inputData: substepInputData
            };
            substeps.push(substep);
        }
        return substeps;
    } else {
        return tempSubsteps;
    }
}

# Returns timeline substep with available experiment data reference if available
#
# + stepId - ID of step 
# + substepNr - number of substep
# + return - substep with experiment data or error
public isolated transactional function getTimelineSubstep(int stepId, int substepNr) returns TimelineSubstepSQL|error {
    stream<TimelineSubstepSQL, sql:Error?> substeps = experimentDB->query(
        `SELECT stepId, substepNr, substepId, href, hrefUi, cleared FROM TimelineSubstep WHERE stepId=${stepId} AND substepNr=${substepNr};`
    );
    var result = substeps.next();
    check substeps.close();

    ExperimentDataReference[]|error inputData = check getSubstepInputData(stepId, substepNr);
    if result is record {|TimelineSubstepSQL value;|} {
        if inputData is error {
            return inputData;
        } else {
            result.value.inputData = inputData;
            return result.value;
        }
    } else if result is error {
        return result;
    } else {
        return error("Could not find timeline substep with step id " + stepId.toString() + " and substep number " + substepNr.toString());
    }
}

public isolated transactional function getTimelineSubstepWithParams(int experimentId, int stepSequence, int substepNr) returns TimelineSubstepWithParams|error {
    // as in getTimelineStep
    stream<TimelineSubstepWithParams, sql:Error?> substeps = experimentDB->query(
        `SELECT 
                TimelineSubstep.stepId, substepNr, substepId, href, hrefUi, cleared, TimelineSubstep.parameters, TimelineSubstep.parametersContentType 
            FROM TimelineSubstep JOIN TimelineStep ON TimelineSubstep.stepId=TimelineStep.stepId
            WHERE TimelineStep.experimentId=${experimentId} AND TimelineStep.sequence=${stepSequence} AND substepNr=${substepNr};`
    );
    var result = substeps.next();
    check substeps.close();

    if result is record {|TimelineSubstepWithParams value;|} {
        return result.value;
    } else if result is error {
        return result;
    } else {
        return error("Could not find timeline substep with experimentId " + experimentId.toString() + " step sequence " + stepSequence.toString() + " and substep number " + substepNr.toString());
    }
}

public isolated transactional function createTimelineSubstep(int stepId, TimelineSubstep substep) returns error? {
    if substep.href == "" {
        return error("Href cannot be empty!");
    }
    int count = check experimentDB->queryRow(`SELECT count(*) FROM TimelineSubstep WHERE stepId=${stepId};`);
    count += 1;
    string? substepId = substep.substepId;
    _ = check experimentDB->execute(
        `INSERT INTO TimelineSubstep (stepId, substepNr, substepId, href, hrefUi, cleared) 
         VALUES (${stepId}, ${count}, ${substep.substepId != () ? substepId : count.toString()}, ${substep.href}, ${substep.hrefUi}, ${substep.cleared});`
    );
}

# Updates cleared field of timeline substep
#
# + stepId - stepId
# + substep - substep
# + return - error in case no update or multiple updated
public isolated transactional function updateTimelineSubstep(int stepId, TimelineSubstep substep) returns error? {
    // TODO: refactor
    if substep.href == "" {
        return error("Href cannot be empty!");
    }
    sql:ExecutionResult result;
    if substep.substepId == () {
        if substep.hrefUi == () {
            result = check experimentDB->execute(
                `UPDATE TimelineSubstep SET cleared=${substep.cleared} WHERE stepId=${stepId} AND href=${substep.href};`
            );
        } else {
            result = check experimentDB->execute(
                `UPDATE TimelineSubstep SET cleared=${substep.cleared} WHERE stepId=${stepId} AND href=${substep.href} AND hrefUi=${substep.hrefUi};`
            );
        }
    } else {
        if substep.hrefUi == () {
            result = check experimentDB->execute(
                `UPDATE TimelineSubstep SET cleared=${substep.cleared} WHERE stepId=${stepId} AND href=${substep.href} AND substepId=${substep.substepId};`
            );
        } else {
            result = check experimentDB->execute(
                `UPDATE TimelineSubstep SET cleared=${substep.cleared} WHERE stepId=${stepId} AND href=${substep.href} AND hrefUi=${substep.hrefUi} AND substepId=${substep.substepId};`
            );
        }
    }
    if result?.affectedRowCount != 1 {
        int? rowCount = result?.affectedRowCount;
        return error(string `Update not successful. Affected rows: ${rowCount != () ? rowCount : 0}`);
    }
}

# Updates cleared field of all timeline substeps with substepNr <= substepNrBound
#
# + stepId - stepId
# + substepNrBound - bound of substepNr's
# + return - Returns true if changes were made successfully and false if no changes were made. Else raises an error.
public isolated transactional function clearTimelineSubsteps(int stepId, int substepNrBound) returns boolean|error {
    sql:ExecutionResult result = check experimentDB->execute(
        `UPDATE TimelineSubstep SET cleared=${true} WHERE stepId=${stepId} AND substepNr<=${substepNrBound};`
    );
    var affectedRowCount = result?.affectedRowCount;
    if affectedRowCount != () {
        if affectedRowCount > 0 {
            return true;
        }
    }
    return false;
}

# Updates database from a list of received substeps. First checks received list against old list of substeps for the given step in the database to find updated and new substeps. If steps are missing or illegal changes were made (apart from setting cleared to 1) or multiple new uncleared substeps are added an appropriate error is returned. If at least one new substep is added, all old substeps are automatically cleared (in case they are not cleared in the received list). A warning is printed if more than one new substep is added. 
#
# + stepId - Timeline step id
# + receivedSubsteps - list of received substeps
# + return - Returns true if changes were made successfully and false if no changes were made. Else raises an error.
public isolated transactional function updateTimelineSubsteps(int stepId, TimelineSubstep[] receivedSubsteps) returns boolean|error {
    // returns timelineSubsteps ordered by substepNr
    TimelineSubstepSQL[] oldDBSubsteps = check getTimelineSubsteps(stepId);

    if receivedSubsteps.length() < oldDBSubsteps.length() {
        return error(string `Received substeps list smaller than stored substep list in database (stepId: ${stepId}).`);
    }

    int substepNr = 0;
    var oldDBSubstepsIterator = oldDBSubsteps.iterator();
    boolean changes = false;
    // nUncleared is for the case that receivedSubsteps.length() == oldDBSubsteps.length() and the last substep is cleared
    int nUncleared = 1;

    // we assume that index in receivedSubsteps corresponds to substepNr
    foreach TimelineSubstep receivedSubstep in receivedSubsteps {

        var tmp = oldDBSubstepsIterator.next();
        if tmp != () {
            substepNr += 1;
            TimelineSubstepSQL oldDBSubstep = tmp.value;

            // make sure that no invalid changes have been made
            if receivedSubstep.href != oldDBSubstep.href {
                return error(string `UI illegally changed the href of a substep or changed the order of substeps (stepId: ${stepId}, substep index: ${substepNr}, new hrefUi: ${receivedSubstep.href}).`);
            }
            if receivedSubstep.substepId != () && receivedSubstep.substepId != oldDBSubstep.substepId {
                string? substepId = receivedSubstep.substepId;
                return error(string `UI illegally set or changed the substepId of a substep  or changed the order of substeps (stepId: ${stepId}, substep index: ${substepNr}, new substepId: ${substepId != () ? substepId : ""}).`);
            }
            if receivedSubstep.hrefUi != () && receivedSubstep.hrefUi != oldDBSubstep.hrefUi {
                string? hrefUi = receivedSubstep.hrefUi;
                return error(string `UI illegally set or changed the hrefUi of a substep or changed the order of substeps (stepId: ${stepId}, substep index: ${substepNr}, new hrefUi: ${hrefUi != () ? hrefUi : ""}).`);
            }
            if receivedSubstep.cleared == 0 && oldDBSubstep.cleared == 1 {
                return error(string `Previously cleared substep was set to cleared=false or changed the order of substeps (stepId: ${stepId}, substep index: ${substepNr}, href: ${receivedSubstep.href})!`);
            }
            if receivedSubstep.cleared == 1 && substepNr == receivedSubsteps.length() {
                nUncleared = 0;
                if oldDBSubstep.cleared == 0 {
                    changes = true;
                }
            }
        } else {
            // new substep
            check createTimelineSubstep(stepId, receivedSubstep);
            changes = true;
        }
    }

    // set all previous substeps except the latest one to cleared by default (should have been done, but we don't care here). The latest one should only be set manually. 
    _ = check clearTimelineSubsteps(stepId, receivedSubsteps.length() - nUncleared);
    if (nUncleared > 1) {
        return true;
    }
    return changes;
}

public isolated transactional function updateTimelineProgress(int stepId, Progress progress) returns error? {
    _ = check experimentDB->execute(
        `UPDATE TimelineStep SET pStart = ${progress.progressStart}, pTarget = ${progress.progressTarget}, pValue = ${progress.progressValue}, pUnit = ${progress.progressUnit} WHERE stepId = ${stepId};`
    );
}

public isolated transactional function getSubstepInputData(int stepId, int substepNr) returns ExperimentDataReference[]|error {
    stream<ExperimentDataReference, sql:Error?> inputData;

    inputData = experimentDB->query(
        `SELECT name, version FROM SubstepData JOIN ExperimentData ON SubstepData.dataId = ExperimentData.dataId 
         WHERE relationType = "input" and stepId = ${stepId} and substepNr = ${substepNr};`
    );

    ExperimentDataReference[]|error? inputDataList = from var row in inputData
        select row;
    check inputData.close();

    if inputDataList is () {
        return [];
    } else if !(inputDataList is error) {
        return inputDataList;
    }

    return error(string `Failed to retrieve input data for experiment substep with stepId ${stepId} and substepNr ${substepNr}!`);
}

public isolated transactional function saveTimelineSubstepParams(int stepId, int substepNr, string? parameters, string parametersContentType) returns error? {
    _ = check experimentDB->execute(
                `UPDATE TimelineSubstep SET parameters=${parameters}, parametersContentType=${parametersContentType} WHERE stepId=${stepId} AND substepNr=${substepNr};`
            );
}

public isolated transactional function saveTimelineSubstepInputData(int stepId, int substepNr, int experimentId, ExperimentDataReference[] inputData) returns error? {
    foreach var data in inputData {
        var experimentData = check getData(experimentId, data.name, data.'version);
        _ = check experimentDB->execute(`INSERT INTO SubstepData (stepId, substepNr, dataId, relationType) VALUES (${stepId}, ${substepNr}, ${experimentData.dataId}, ${"input"});`);
    }
}
