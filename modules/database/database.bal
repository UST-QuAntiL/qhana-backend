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

//import ballerina/io;
//import ballerina/time;
import ballerina/sql;
import ballerinax/java.jdbc;


final jdbc:Client testDB = check new jdbc:Client("jdbc:sqlite:qhana-backend.db", options={datasourceName:""});

public type Experiment record {|
    string name;
    string description;
|};

public type ExperimentFull record {|
    *Experiment;
    int experimentId;
|};


# Description
# + return - Return Value Description  
public isolated function getExperiments() returns ExperimentFull[]|error {
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(`SELECT experimentId, name, description FROM Experiment;`);


    ExperimentFull[]? experimentList = check from var experiment in experiments select experiment;

    if experimentList != () {
        return experimentList;
    }
    
    return [];
}


public isolated function getExperiment(int experimentId) returns ExperimentFull|error {
    stream<ExperimentFull, sql:Error?> experiments = testDB->query(`SELECT experimentId, name, description FROM Experiment WHERE experimentId = ${experimentId};`);

    var experiment = experiments.next();

    if !(experiment is sql:Error) && (experiment != ()) {
        return experiment.value;
    }

    fail error(string`Experiment ${experimentId} was not found!`);
}

public isolated function createExperiment(*Experiment experiment) returns error? {
    transaction {
        stream<Experiment, sql:Error?> experiments;
        _ = check testDB->execute(`INSERT INTO Experiment (name, description) VALUES (${experiment.name}, ${experiment.description});`);
        check commit;
    }
}

public isolated function updateExperiment(int experimentId, *Experiment experiment) returns error? {
    transaction {
        stream<Experiment, sql:Error?> experiments;
        _ = check testDB->execute(`UPDATE Experiment SET name=${experiment.name}, description=${experiment.description} WHERE experimentId = ${experimentId};`);
        check commit;
    }
}

