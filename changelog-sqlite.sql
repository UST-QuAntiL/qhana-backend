-- liquibase formatted sql

-- changeset fabianbuehler:qhana-backend-baseline-1 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "Experiment" (
	"experimentId"	INTEGER NOT NULL,
	"name"	VARCHAR(500) NOT NULL COLLATE NOCASE,
	"description"	TEXT NOT NULL,
	PRIMARY KEY("experimentId" AUTOINCREMENT)
);

-- changeset fabianbuehler:qhana-backend-baseline-2 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_experiment" ON "Experiment" (
	"experimentId"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-3 labels:v0 context:all
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

-- changeset fabianbuehler:qhana-backend-baseline-4 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_experiment_data" ON "ExperimentData" (
	"dataId"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-5 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_data_to_experiment" ON "ExperimentData" (
	"experimentId"
);

-- changeset fabianbuehler:qhana-backend-baseline-6 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_data_name" ON "ExperimentData" (
	"name"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-7 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_data_version" ON "ExperimentData" (
	"version"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-8 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_data_type" ON "ExperimentData" (
	"type"
);

-- changeset fabianbuehler:qhana-backend-baseline-9 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_data_contenttype" ON "ExperimentData" (
	"contentType"
);

-- changeset fabianbuehler:qhana-backend-baseline-10 labels:v0 context:all
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
	"pStart"	REAL,
	"pTarget"	REAL,
	"pValue"	REAL,
	"pUnit"	VARCHAR(500),
	"notes"	TEXT,
	FOREIGN KEY("experimentId") REFERENCES "Experiment"("experimentId"),
	CONSTRAINT "ux_experiment_step" UNIQUE("experimentId","sequence"),
	PRIMARY KEY("stepId" AUTOINCREMENT)
);

-- changeset fabianbuehler:qhana-backend-baseline-11 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_experiment_step" ON "TimelineStep" (
	"stepId"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-12 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_step_to_experiment" ON "TimelineStep" (
	"experimentId"
);

-- changeset fabianbuehler:qhana-backend-baseline-13 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_step_sequence" ON "TimelineStep" (
	"sequence"
);

-- changeset fabianbuehler:qhana-backend-baseline-14 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_step_processor" ON "TimelineStep" (
	"processorName"
);

-- changeset fabianbuehler:qhana-backend-baseline-15 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "StepData" (
	"id"	INTEGER NOT NULL,
	"stepId"	INTEGER NOT NULL,
	"dataId"	INTEGER NOT NULL,
	"relationType"	VARCHAR(50) NOT NULL COLLATE NOCASE,
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	FOREIGN KEY("dataId") REFERENCES "ExperimentData"("dataId"),
	PRIMARY KEY("id" AUTOINCREMENT)
);

-- changeset fabianbuehler:qhana-backend-baseline-16 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_step_data" ON "StepData" (
	"id"	ASC
);

-- changeset fabianbuehler:qhana-backend-baseline-17 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_to_step" ON "StepData" (
	"stepId"
);

-- changeset fabianbuehler:qhana-backend-baseline-18 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_to_data" ON "StepData" (
	"dataId"
);

-- changeset fabianbuehler:qhana-backend-baseline-19 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_step_data_relation" ON "StepData" (
	"relationType"
);

-- changeset nicolaikrebs:qhana-backend-baseline-20 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "TimelineSubstep" (
	"stepId"	INTEGER NOT NULL,
	"substepNr"	INTEGER NOT NULL,
	"substepId"	VARCHAR(500) NOT NULL,
	"href"	TEXT NOT NULL,
	"hrefUi"	TEXT,
	"cleared"	INTEGER DEFAULT 0 CHECK(cleared=0 or cleared=1),
	"parameters"	TEXT,
	"parametersContentType"	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	PRIMARY KEY("stepId","substepNr")
);

-- changeset nicolaikrebs:qhana-backend-baseline-21 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_substep_to_step" ON "TimelineSubstep" (
	"stepId"	ASC
);

-- changeset nicolaikrebs:qhana-backend-baseline-22 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_substep_nr" ON "TimelineSubstep" (
	"substepNr"	ASC
);

-- changeset nicolaikrebs:qhana-backend-baseline-23 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_substep_id" ON "TimelineSubstep" (
	"substepId"	ASC
);

-- changeset nicolaikrebs:qhana-backend-baseline-24 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "SubstepData" (
	"id"	INTEGER NOT NULL,
	"stepId"	INTEGER NOT NULL,
	"substepNr"	INTEGER NOT NULL,
	"dataId"	INTEGER NOT NULL,
	"relationType"	VARCHAR(50) NOT NULL COLLATE NOCASE,
	FOREIGN KEY("stepId", "substepNr") REFERENCES "TimelineSubstep"("stepId", "substepNr"),
	FOREIGN KEY("dataId") REFERENCES "ExperimentData"("dataId"),
	PRIMARY KEY("id" AUTOINCREMENT)
);

-- changeset nicolaikrebs:qhana-backend-baseline-25 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_pk_substep_data" ON "SubstepData" (
	"id"	ASC
);

-- changeset nicolaikrebs:qhana-backend-baseline-26 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_to_step" ON "SubstepData" (
	"stepId", "substepNr"
);

-- changeset nicolaikrebs:qhana-backend-baseline-27 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_to_data" ON "SubstepData" (
	"dataId"
);

-- changeset nicolaikrebs:qhana-backend-baseline-28 labels:v0 context:all
CREATE INDEX IF NOT EXISTS "ix_fk_substep_data_relation" ON "SubstepData" (
	"relationType"
);

-- changeset fabianbuehler:qhana-backend-baseline-29 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "ResultWatchers" (
	"stepId"	INTEGER NOT NULL,
	"resultEndpoint"	TEXT NOT NULL,
	FOREIGN KEY("stepId") REFERENCES "TimelineStep"("stepId"),
	PRIMARY KEY("stepId")
);

-- changeset fabianbuehler:qhana-backend-baseline-30 labels:v0 context:all
CREATE TABLE IF NOT EXISTS "PluginEndpoints" (
	"id"	INTEGER NOT NULL,
	"url"	TEXT NOT NULL UNIQUE,
	"type"	VARCHAR(64) NOT NULL DEFAULT 'PluginRunner',
	PRIMARY KEY("id" AUTOINCREMENT)
);

-- changeset fabianbuehler:qhana-backend-baseline-31 labels:v0 context:all
INSERT INTO PluginEndpoints (url, type) VALUES ("http://localhost:5005", "PluginRunner");