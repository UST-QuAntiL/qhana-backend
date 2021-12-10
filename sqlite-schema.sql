-- Copyright 2021 University of Stuttgart
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS "Experiment" (
	"experimentId"	INTEGER NOT NULL,
	"name"	VARCHAR(500) NOT NULL COLLATE NOCASE,
	"description"	TEXT NOT NULL,
	PRIMARY KEY("experimentId" AUTOINCREMENT)
);
CREATE INDEX IF NOT EXISTS "ix_pk_experiment" ON "Experiment" (
	"experimentId"	ASC
);

CREATE TABLE IF NOT EXISTS "ExperimentData" (
	"dataId"	INTEGER NOT NULL,
	"experimentId"	INTEGER NOT NULL,
	"name"	VARCHAR(500) NOT NULL COLLATE NOCASE,
	"version"	INTEGER NOT NULL,
	"location"	TEXT NOT NULL,
	"type"	VARCHAR(500) NOT NULL,
	"contentType"	VARCHAR(500) NOT NULL,
	CONSTRAINT "ux_name_and_version" UNIQUE("experimentId","name","version"),
	FOREIGN KEY("experimentId") REFERENCES "Experiment"("experimentId"),
	PRIMARY KEY("dataId" AUTOINCREMENT)
);
CREATE INDEX IF NOT EXISTS "ix_pk_experiment_data" ON "ExperimentData" (
	"dataId"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_fk_data_to_experiment" ON "ExperimentData" (
	"experimentId"
);
CREATE INDEX IF NOT EXISTS "ix_data_name" ON "ExperimentData" (
	"name"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_data_version" ON "ExperimentData" (
	"version"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_data_type" ON "ExperimentData" (
	"type"
);
CREATE INDEX IF NOT EXISTS "ix_data_contenttype" ON "ExperimentData" (
	"contentType"
);

-- "start"	DATETIME NOT NULL DEFAULT `strftime('%Y-%m-%dT%H:%M:%S', 'now')`, (does not work in sqlite, preserved here for later)
CREATE TABLE IF NOT EXISTS "TimelineStep" (
	"stepId"	INTEGER NOT NULL,
	"experimentId"	INTEGER NOT NULL,
	"sequence"	INTEGER NOT NULL,
	"start"	DATETIME NOT NULL,
	"end"	DATETIME,
	"status"	VARCHAR(50) DEFAULT 'PENDING',
	"resultQuality"	VARCHAR(50) NOT NULL DEFAULT 'UNKNOWN',
	"resultLog"	TEXT,
	"processorName"	VARCHAR(500) NOT NULL,
	"processorVersion"	VARCHAR(150),
	"processorLocation"	TEXT,
	"parameters"	TEXT NOT NULL,
	"parametersContentType"	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	"parametersDescriptionLocation"	TEXT,
	"pStart"	REAL,
	"pTarget"	REAL,
	"pValue"	REAL,
	"pUnit"	VARCHAR(500),
	"notes"	TEXT,
	FOREIGN KEY("experimentId") REFERENCES "Experiment"("experimentId"),
	CONSTRAINT "ux_experiment_step" UNIQUE("experimentId","sequence"),
	PRIMARY KEY("stepId" AUTOINCREMENT)
);
CREATE INDEX IF NOT EXISTS "ix_pk_experiment_step" ON "TimelineStep" (
	"stepId"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_fk_step_to_experiment" ON "TimelineStep" (
	"experimentId"
);
CREATE INDEX IF NOT EXISTS "ix_step_sequence" ON "TimelineStep" (
	"sequence"
);
CREATE INDEX IF NOT EXISTS "ix_step_processor" ON "TimelineStep" (
	"processorName"
);

CREATE TABLE IF NOT EXISTS "StepData" (
	"id"	INTEGER NOT NULL,
	"stepId"	INTEGER NOT NULL,
	"dataId"	INTEGER NOT NULL,
	"relationType"	VARCHAR(50) NOT NULL COLLATE NOCASE,
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	FOREIGN KEY("dataId") REFERENCES "ExperimentData"("dataId"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE INDEX IF NOT EXISTS "ix_pk_step_data" ON "StepData" (
	"id"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_to_step" ON "StepData" (
	"stepId"
);
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_to_data" ON "StepData" (
	"dataId"
);
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_relation" ON "StepData" (
	"relationType"
);

CREATE TABLE IF NOT EXISTS "TimelineSubstep" (
	"stepId"	INTEGER NOT NULL,
	"substepNr"	INTEGER NOT NULL,
	"substepId"	VARCHAR(500) NOT NULL,
	"href"	TEXT NOT NULL,
	"hrefUi"	TEXT,
	"cleared"	INTEGER DEFAULT 0 CHECK(cleared=0 or cleared=1),
	"parameters"	TEXT NOT NULL,
	"parametersContentType"	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	PRIMARY KEY("stepId","substepNr")
);
CREATE INDEX IF NOT EXISTS "ix_pk_substep_to_step" ON "TimelineSubstep" (
	"stepId"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_pk_substep_nr" ON "TimelineSubstep" (
	"substepNr"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_substep_id" ON "TimelineSubstep" (
	"substepId"	ASC
);

CREATE TABLE IF NOT EXISTS "SubstepData" (
	"id"	INTEGER NOT NULL,
	"stepId"	INTEGER NOT NULL,
	"substepNr"	INTEGER NOT NULL,
	"dataId"	INTEGER NOT NULL,
	"relationType"	VARCHAR(50) NOT NULL COLLATE NOCASE,
	FOREIGN KEY("stepId") REFERENCES "TimelineSubstep"("stepId"),
	FOREIGN KEY("substepNr") REFERENCES "TimelineSubstep"("substepNr"),
	FOREIGN KEY("dataId") REFERENCES "ExperimentData"("dataId"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE INDEX IF NOT EXISTS "ix_pk_substep_data" ON "SubstepData" (
	"id"	ASC
);
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_to_step" ON "SubstepData" (
	"stepId"
);
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data2_to_step" ON "SubstepData" (
	"substepNr"
);
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_to_data" ON "SubstepData" (
	"dataId"
);
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_relation" ON "SubstepData" (
	"relationType"
);

CREATE TABLE IF NOT EXISTS "ResultWatchers" (
	"stepId"	INTEGER NOT NULL,
	"resultEndpoint"	TEXT NOT NULL,
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	PRIMARY KEY("stepId")
);


CREATE TABLE IF NOT EXISTS "PluginEndpoints" (
	"id"	INTEGER NOT NULL,
	"url"	TEXT NOT NULL UNIQUE,
	"type"	VARCHAR(64) NOT NULL DEFAULT 'PluginRunner',
	PRIMARY KEY("id" AUTOINCREMENT)
);

COMMIT;
