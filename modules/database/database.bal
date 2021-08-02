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

import ballerina/io;
import ballerina/time;
import ballerina/sql;
import ballerinax/java.jdbc;

final jdbc:Client testDB = check new jdbc:Client("jdbc:sqlite:qhana-backend.db");

type RowCount record {
    int rowCount;
};

// Experiments /////////////////////////////////////////////////////////////////

# Record containing the pure data of an Experiment.
#
# + name - The experiment name
# + description - The experiment description
public type Experiment record {|
    string name;
    string description="";
|};

# Record containing the experiment data and the database ID of the Experiment
#
# + experimentId - The database id of the record
public type ExperimentFull record {|
    readonly int experimentId;
    *Experiment;
|};

// Data ////////////////////////////////////////////////////////////////////////

public type ExperimentData record {|
    string name;
    int 'version;
    string location;
    string 'type;
    string contentType;
|};

public type ExperimentDataFull record {|
    readonly int dataId;
    readonly int experimentId;
    *ExperimentData;
|};

// Timeline ////////////////////////////////////////////////////////////////////

public type TimelineStep record {|
    time:Utc 'start;
    time:Utc? end=();
    string processorName;
    string? processorVersion=();
    string? processorLocation=();
    string parameters?; // optional for small requests
    string? parameterDescriptionLocation=();
    string notes?; // optional for small requests
|};

public type TimelineStepFull record {|
    readonly int stepId;
    readonly int experimentId;
    readonly int sequence;
    *TimelineStep;
|};

public type TimelineStepSQL record {|
    readonly int stepId;
    readonly int experimentId;
    readonly int sequence;
    string|time:Utc 'start;
    string|time:Utc|() end=();
    string processorName;
    string? processorVersion=();
    string? processorLocation=();
    string parameters?; // optional for small requests
    string? parameterDescriptionLocation=();
    string notes?; // optional for small requests
|};

public type TimelineStepWithParams record {|
    *TimelineStepFull;
    string parameters;
|};

// Timeline to Data links //////////////////////////////////////////////////////

public type StepToData record {|
    readonly int stepId;
    readonly int dataId;
    string relationType;
|};


////////////////////////////////////////////////////////////////////////////////
// Experiments /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


# Return the number of experiments in the database.
#
# + return - The number of experiments or the encountered error
public isolated function getExperimentCount() returns int|error {
    var result = testDB->query("SELECT count(*) AS rowCount FROM Experiment;", RowCount);
    var count = result.next();
    if !(count is error) {
        return count.value.rowCount;
    } else {
        return count;
    }
}

# Get the list of experiments from the database.
#
# + 'limit - The maximum number of experiments fetched in one call (default: `100`)
# + offset - The offset applied to the sql query (default: `0`)
# + return - The list of experiments or the encountered error
public isolated function getExperiments(int 'limit = 100, int offset = 0) returns ExperimentFull[]|error {
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(
        `SELECT experimentId, name, description FROM Experiment ORDER BY name ASC LIMIT ${'limit} OFFSET ${offset};`
    );

    ExperimentFull[]? experimentList = check from var experiment in experiments
        select experiment;

    if experimentList != () {
        return experimentList;
    }

    return [];
}

# Get a single experiment from the database.
#
# + experimentId - The database id of the experiment to fetch
# + return - The experiment or the encountered error
public isolated function getExperiment(int experimentId) returns ExperimentFull|error {
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(
        `SELECT experimentId, name, description FROM Experiment WHERE experimentId = ${experimentId};`
    );

    var experiment = experiments.next();

    if !(experiment is sql:Error) && (experiment != ()) {
        return experiment.value;
    }

    return error(string `Experiment ${experimentId} was not found!`);
}

# Create a new experiment in the database.
#
# + experiment - The data for the new experiment
# + return - The experiment data including the database id or the encountered error
public isolated function createExperiment(*Experiment experiment) returns ExperimentFull|error {
    ExperimentFull? result = ();

    transaction {
        stream<Experiment, sql:Error?> experiments;
        var insertResult = check testDB->execute(
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
            check commit;
        }
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
public isolated function updateExperiment(int experimentId, *Experiment experiment) returns ExperimentFull|error {
    transaction {
        stream<Experiment, sql:Error?> experiments;
        var test = check testDB->execute(
            `UPDATE Experiment SET name=${experiment.name}, description=${experiment.description} WHERE experimentId = ${experimentId};`
        );
        io:println(test);
        check commit;
    }
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
public isolated function getExperimentDataCount(int experimentId, boolean all=true) returns int|error {
    stream<RowCount, sql:Error> result;
    if all {
        result = testDB->query(`SELECT count(*) AS rowCount FROM ExperimentData WHERE experimentId = ${experimentId};`);
    } else {
        result = testDB->query(`SELECT count(DISTINCT name) AS rowCount FROM ExperimentData WHERE experimentId = ${experimentId};`);
    }
    var count = result.next();
    if !(count is error) {
        return count.value.rowCount;
    } else {
        return count;
    }
}


public isolated function getDataList(int experimentId, boolean all=true, int 'limit = 100, int offset = 0) returns ExperimentDataFull[]|error {
    stream<ExperimentDataFull, sql:Error?> experimentData;
    if all {
        experimentData = testDB->query(`SELECT dataId, experimentId, name, version, location, type, contentType 
                                        FROM ExperimentData WHERE experimentId=${experimentId} 
                                        ORDER BY name ASC, version DESC 
                                        LIMIT ${'limit} OFFSET ${offset};`);
    } else {
        experimentData = testDB->query(`SELECT dataId, experimentId, name, version, location, type, contentType 
                                        FROM ExperimentData WHERE experimentId=${experimentId} 
                                            AND version=(SELECT MAX(t2.version) 
                                                FROM ExperimentData AS t2 
                                                WHERE ExperimentData.name=t2.name AND t2.experimentId=${experimentId})
                                        ORDER BY name ASC, version DESC 
                                        LIMIT ${'limit} OFFSET ${offset};`);
    }

    ExperimentDataFull[]? experimentDataList = check from var data in experimentData
        select data;

    if experimentDataList != () {
        return experimentDataList;
    }

    return [];
}


public isolated function getData(int experimentId, string name, string? 'version) returns ExperimentDataFull|error {
    stream<ExperimentDataFull, sql:Error?> data;

    if 'version == () || 'version == "latest" {
        data = testDB->query(`SELECT dataId, experimentId, name, version, location, type, contentType 
                              FROM ExperimentData WHERE experimentId=${experimentId} AND name=${name}
                              ORDER BY version DESC 
                              LIMIT 1;`); // get latest version with order by descending and limit to one
    } else {
        data = testDB->query(`SELECT dataId, experimentId, name, version, location, type, contentType 
                              FROM ExperimentData WHERE experimentId=${experimentId} AND name=${name} AND version=${'version};`);
    }

    var result = data.next();

    if !(result is sql:Error) && (result != ()) {
        return result.value;
    }

    return error(string `Experiment data with experimentId: ${experimentId}, name: ${name} and version: ${'version == () ? "latest" : 'version} was not found!`);
}


////////////////////////////////////////////////////////////////////////////////
// Timeline ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public isolated function getTimelineStepCount(int experimentId) returns int|error {
    stream<RowCount, sql:Error> result = testDB->query(
        `SELECT count(*) AS rowCount FROM TimelineStep WHERE experimentId = ${experimentId};`
    );

    var count = result.next();
    if !(count is error) {
        return count.value.rowCount;
    } else {
        return count;
    }
}

public isolated function castToTimelineStepFull(TimelineStepSQL step) returns TimelineStepFull|error {
    var startString = step.'start;
    if startString is string {
        if !startString.endsWith("Z") {
            startString += ".00Z";
        }
        time:Utc 'start = check time:utcFromString(startString);
        step.'start = 'start;
    }
    var endString = step.end; // needed for correct type narrowing
    if endString is string {
        if !endString.endsWith("Z") {
            endString += ".00Z";
        }
        time:Utc end = check time:utcFromString(endString);
        step.end = end;
    }
    return step.cloneWithType();
}

public isolated function getTimelineStepList(int experimentId, boolean allAttributes=false, int 'limit = 100, int offset = 0) returns TimelineStepFull[]|error {
    stream<TimelineStepSQL, sql:Error?> timelineSteps;
    if allAttributes {
        timelineSteps = testDB->query(
            `SELECT stepId, experimentId, sequence, cast(start as TEXT) AS start, cast(end as TEXT) AS end, processorName, processorVersion, processorLocation, parameterDescriptionLocation, parameters, notes 
             FROM TimelineStep WHERE experimentId=${experimentId} 
             ORDER BY sequence ASC 
             LIMIT ${'limit} OFFSET ${offset};`
        );
    } else {
        timelineSteps = testDB->query(
            `SELECT stepId, experimentId, sequence, cast(start as TEXT) AS start, cast(end as TEXT) AS end, processorName, processorVersion, processorLocation, parameterDescriptionLocation 
             FROM TimelineStep WHERE experimentId=${experimentId} 
             ORDER BY sequence ASC 
             LIMIT ${'limit} OFFSET ${offset};`
        );
    }

    (TimelineStepSQL|TimelineStepFull)[]|error|() tempList = from var step in timelineSteps select step;

    io:println(tempList);

    TimelineStepFull[] stepList = [];
    if tempList is error{
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


public isolated function getTimelineStep(int experimentId, int sequence) returns TimelineStepWithParams|error {
    stream<TimelineStepSQL, sql:Error?> timelineStep = testDB->query(
        `SELECT stepId, experimentId, sequence, cast(start as TEXT) AS start, cast(end as TEXT) AS end, processorName, processorVersion, processorLocation, parameterDescriptionLocation, parameters
         FROM TimelineStep WHERE experimentId=${experimentId} AND sequence=${sequence};`
    );

    var result = timelineStep.next();

    if !(result is sql:Error) && (result != ()) {
        TimelineStepFull|error stepFull = castToTimelineStepFull(result.value);
        if stepFull is error {
            return error(string`The Timeline step with experimentId: ${experimentId} and sequence: ${sequence} could not be read from the database!`, stepFull);
        } else {
            TimelineStepWithParams|error step = stepFull.cloneWithType(TimelineStepWithParams);
            if step is error {
                return error(string`The Timeline step with experimentId: ${experimentId} and sequence: ${sequence} did not have the required parameters field!`, step);
            }
            return step;
        }
    }

    io:println(result);

    return error(string `Timeline step with experimentId: ${experimentId} and sequence: ${sequence} was not found!`);
}

public isolated function getTimelineStepNotes(int experimentId, int sequence) returns string|error {
    stream<record {|string notes;|}, sql:Error?> note = testDB->query(
        `SELECT notes
         FROM TimelineStep WHERE experimentId=${experimentId} AND sequence=${sequence};`
    );

    var result = note.next();

    if !(result is sql:Error) && (result != ()) {
        return result.value.notes;
    }

    return error(string `Notes for timeline step with experimentId: ${experimentId} and sequence: ${sequence} were not found!`);
}

