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
//import ballerina/time;
import ballerina/sql;
import ballerinax/java.jdbc;


final jdbc:Client testDB = check new jdbc:Client("jdbc:sqlite:qhana-backend.db", options={datasourceName:""});

# Record containing the pure data of an Experiment.
#
# + name - The experiment name
# + description - The experiment description
public type Experiment record {|
    string name;
    string description;
|};

# Record containing the experiment data and the database ID of the Experiment
#
# + experimentId - The database id of the record
public type ExperimentFull record {|
    readonly int experimentId;
    *Experiment;
|};

type RowCount record {
    int rowCount;
};


# Return the number of experiments in the database.
#
# + return - The number of experiments or the encountered error
public isolated  function getExperimentCount() returns int|error {
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
public isolated function getExperiments(int 'limit=100, int offset=0) returns ExperimentFull[]|error {
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(`SELECT experimentId, name, description FROM Experiment ORDER BY name ASC LIMIT ${'limit} OFFSET ${offset};`);


    ExperimentFull[]? experimentList = check from var experiment in experiments select experiment;

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
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(`SELECT experimentId, name, description FROM Experiment WHERE experimentId = ${experimentId};`);

    var experiment = experiments.next();

    if !(experiment is sql:Error) && (experiment != ()) {
        return experiment.value;
    }

    fail error(string`Experiment ${experimentId} was not found!`);
}

# Create a new experiment in the database.
#
# + experiment - The data for the new experiment
# + return     - The experiment data including the database id or the encountered error
public isolated function createExperiment(*Experiment experiment) returns ExperimentFull|error {
    ExperimentFull? result = ();

    transaction {
        stream<Experiment, sql:Error?> experiments;
        var insertResult = check testDB->execute(`INSERT INTO Experiment (name, description) VALUES (${experiment.name}, ${experiment.description});`);

        // extract experiment id and build full experiment data
        var experimentId = insertResult.lastInsertId;
        if experimentId is string {
            fail error("Expected integer id but got a string!");
        } else if experimentId == () {
            fail error("Expected the experiment id back but got nothing!");
        } else {
            result = { experimentId: experimentId, name: experiment.name, description: experiment.description };
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
        var test = check testDB->execute(`UPDATE Experiment SET name=${experiment.name}, description=${experiment.description} WHERE experimentId = ${experimentId};`);
        io:println(test);
        check commit;
    }
    return {experimentId, name: experiment.name, description: experiment.description};
}

