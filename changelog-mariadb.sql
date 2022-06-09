-- liquibase formatted sql
-- ignoreLines:start
-- Copyright 2022 University of Stuttgart
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
-- ignoreLines:end

-- changeset fabianbuehler:qhana-backend-baseline-1 labels:v0
CREATE TABLE IF NOT EXISTS `Experiment` (
	`experimentId`	INTEGER NOT NULL AUTO_INCREMENT,
	`name`	VARCHAR(500) NOT NULL,
	`description`	TEXT NOT NULL,
	PRIMARY KEY (`experimentId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `Experiment`;

-- changeset fabianbuehler:qhana-backend-baseline-2 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_experiment` ON `Experiment` (
	`experimentId`	ASC
);
-- rollback DROP INDEX `ix_pk_experiment` ON `Experiment`;

-- changeset fabianbuehler:qhana-backend-baseline-3 labels:v0
CREATE TABLE IF NOT EXISTS `ExperimentData` (
	`dataId`	INTEGER NOT NULL AUTO_INCREMENT,
	`experimentId`	INTEGER NOT NULL,
	`name`	VARCHAR(500) NOT NULL,
	`version`	INTEGER NOT NULL,
	`location`	TEXT NOT NULL,
	`type`	VARCHAR(500) NOT NULL,
	`contentType`	VARCHAR(500) NOT NULL,
	CONSTRAINT `ux_name_and_version` UNIQUE(`experimentId`,`name`,`version`),
	FOREIGN KEY(`experimentId`) REFERENCES `Experiment`(`experimentId`),
	PRIMARY KEY(`dataId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-4 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_experiment_data` ON `ExperimentData` (
	`dataId`	ASC
);
-- rollback DROP INDEX `ix_pk_experiment_data` ON `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-5 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_data_to_experiment` ON `ExperimentData` (
	`experimentId`
);
-- rollback DROP INDEX `ix_fk_data_to_experiment` ON `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-6 labels:v0
CREATE INDEX IF NOT EXISTS `ix_data_name` ON `ExperimentData` (
	`name`	ASC
);
-- rollback DROP INDEX `ix_data_name` ON `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-7 labels:v0
CREATE INDEX IF NOT EXISTS `ix_data_version` ON `ExperimentData` (
	`version`	ASC
);
-- rollback DROP INDEX `ix_data_version` ON `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-8 labels:v0
CREATE INDEX IF NOT EXISTS `ix_data_type` ON `ExperimentData` (
	`type`
);
-- rollback DROP INDEX `ix_data_type` ON `ExperimentData`;

-- changeset fabianbuehler:qhana-backend-baseline-9 labels:v0
CREATE INDEX IF NOT EXISTS `ix_data_contenttype` ON `ExperimentData` (
	`contentType`
);
-- rollback DROP INDEX `ix_data_contenttype` ON `ExperimentData`;

-- ignoreLines:1
-- `start`	DATETIME NOT NULL DEFAULT `strftime('%Y-%m-%dT%H:%M:%S', 'now')`, (does not work in sqlite, preserved here for later)
-- changeset fabianbuehler:qhana-backend-baseline-10 labels:v0
CREATE TABLE IF NOT EXISTS `TimelineStep` (
	`stepId`	INTEGER NOT NULL AUTO_INCREMENT,
	`experimentId`	INTEGER NOT NULL,
	`sequence`	INTEGER NOT NULL,
	`start`	DATETIME NOT NULL,
	`end`	DATETIME,
	`status`	VARCHAR(50) DEFAULT 'PENDING',
	`resultQuality`	VARCHAR(50) NOT NULL DEFAULT 'UNKNOWN',
	`resultLog`	TEXT,
	`processorName`	VARCHAR(500) NOT NULL,
	`processorVersion`	VARCHAR(150),
	`processorLocation`	TEXT,
	`parametersContentType`	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	`parameters`	TEXT NOT NULL,
	`pStart`	REAL,
	`pTarget`	REAL,
	`pValue`	REAL,
	`pUnit`	VARCHAR(500),
	`notes`	TEXT,
	FOREIGN KEY(`experimentId`) REFERENCES `Experiment`(`experimentId`),
	CONSTRAINT `ux_experiment_step` UNIQUE(`experimentId`,`sequence`),
	PRIMARY KEY(`stepId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `TimelineStep`;

-- changeset fabianbuehler:qhana-backend-baseline-11 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_experiment_step` ON `TimelineStep` (
	`stepId`	ASC
);
-- rollback DROP INDEX `ix_pk_experiment_step` ON `TimelineStep`;

-- changeset fabianbuehler:qhana-backend-baseline-12 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_step_to_experiment` ON `TimelineStep` (
	`experimentId`
);
-- rollback DROP INDEX `ix_fk_step_to_experiment` ON `TimelineStep`;

-- changeset fabianbuehler:qhana-backend-baseline-13 labels:v0
CREATE INDEX IF NOT EXISTS `ix_step_sequence` ON `TimelineStep` (
	`sequence`
);
-- rollback DROP INDEX `ix_step_sequence` ON `TimelineStep`;

-- changeset fabianbuehler:qhana-backend-baseline-14 labels:v0
CREATE INDEX IF NOT EXISTS `ix_step_processor` ON `TimelineStep` (
	`processorName`
);
-- rollback DROP INDEX `ix_step_processor` ON `TimelineStep`;

-- changeset fabianbuehler:qhana-backend-baseline-15 labels:v0
CREATE TABLE IF NOT EXISTS `StepData` (
	`id`	INTEGER NOT NULL AUTO_INCREMENT,
	`stepId`	INTEGER NOT NULL,
	`dataId`	INTEGER NOT NULL,
	`relationType`	VARCHAR(50) NOT NULL,
	FOREIGN KEY(`stepId`) REFERENCES `TimelineStep`(`stepId`),
	FOREIGN KEY(`dataId`) REFERENCES `ExperimentData`(`dataId`),
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `StepData`;

-- changeset fabianbuehler:qhana-backend-baseline-16 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_step_data` ON `StepData` (
	`id`	ASC
);
-- rollback DROP INDEX `ix_pk_step_data` ON `StepData`;

-- changeset fabianbuehler:qhana-backend-baseline-17 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_to_step` ON `StepData` (
	`stepId`
);
-- rollback DROP INDEX `ix_fk_step_data_to_step` ON `StepData`;

-- changeset fabianbuehler:qhana-backend-baseline-18 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_to_data` ON `StepData` (
	`dataId`
);
-- rollback DROP INDEX `ix_fk_step_data_to_data` ON `StepData`;

-- changeset fabianbuehler:qhana-backend-baseline-19 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_relation` ON `StepData` (
	`relationType`
);
-- rollback DROP INDEX `ix_fk_step_data_relation` ON `StepData`;

-- changeset nicolaikrebs:qhana-backend-baseline-20 labels:v0
CREATE TABLE `TimelineSubstep` (
	`stepId`	INTEGER NOT NULL,
	`substepNr`	INTEGER NOT NULL,
	`substepId`	VARCHAR(500) NOT NULL,
	`href`	TEXT NOT NULL,
	`hrefUi`	TEXT,
	`cleared`	INTEGER DEFAULT 0 CHECK(cleared=0 or cleared=1),
	`parameters`	TEXT,
	`parametersContentType`	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	FOREIGN KEY(`stepId`) REFERENCES `TimelineStep`(`stepId`),
	PRIMARY KEY(`stepId`,`substepNr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `TimelineSubstep`;

-- changeset nicolaikrebs:qhana-backend-baseline-21 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_substep_to_step` ON `TimelineSubstep` (
	`stepId`	ASC
);
-- rollback DROP INDEX `ix_pk_substep_to_step` ON `TimelineSubstep`;

-- changeset nicolaikrebs:qhana-backend-baseline-22 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_substep_nr` ON `TimelineSubstep` (
	`substepNr`	ASC
);
-- rollback DROP INDEX `ix_pk_substep_nr` ON `TimelineSubstep`;

-- changeset nicolaikrebs:qhana-backend-baseline-23 labels:v0
CREATE INDEX IF NOT EXISTS `ix_substep_id` ON `TimelineSubstep` (
	`substepId`	ASC
);
-- rollback DROP INDEX `ix_substep_id` ON `TimelineSubstep`;

-- changeset nicolaikrebs:qhana-backend-baseline-24 labels:v0
CREATE TABLE IF NOT EXISTS `SubstepData` (
	`id`	INTEGER NOT NULL AUTO_INCREMENT,
	`stepId`	INTEGER NOT NULL,
	`substepNr`	INTEGER NOT NULL,
	`dataId`	INTEGER NOT NULL,
	`relationType`	VARCHAR(50) NOT NULL,
	FOREIGN KEY(`stepId`, `substepNr`) REFERENCES `TimelineSubstep`(`stepId`, `substepNr`),
	FOREIGN KEY(`dataId`) REFERENCES `ExperimentData`(`dataId`),
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `SubstepData`;

-- changeset nicolaikrebs:qhana-backend-baseline-25 labels:v0
CREATE INDEX IF NOT EXISTS `ix_pk_substep_data` ON `SubstepData` (
	`id`	ASC
);
-- rollback DROP INDEX `ix_pk_substep_data` ON `SubstepData`;

-- changeset nicolaikrebs:qhana-backend-baseline-26 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_substep_data_to_step` ON `SubstepData` (
	`stepId`, `substepNr`
);
-- rollback DROP INDEX `ix_fk_substep_data_to_step` ON `SubstepData`;

-- changeset nicolaikrebs:qhana-backend-baseline-27 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_substep_data_to_data` ON `SubstepData` (
	`dataId`
);
-- rollback DROP INDEX `ix_fk_substep_data_to_data` ON `SubstepData`;

-- changeset nicolaikrebs:qhana-backend-baseline-28 labels:v0
CREATE INDEX IF NOT EXISTS `ix_fk_substep_data_relation` ON `SubstepData` (
	`relationType`
);
-- rollback DROP INDEX `ix_fk_substep_data_relation` ON `SubstepData`;

-- changeset fabianbuehler:qhana-backend-baseline-29 labels:v0
CREATE TABLE IF NOT EXISTS `ResultWatchers` (
	`stepId`	INTEGER NOT NULL,
	`resultEndpoint`	TEXT NOT NULL,
	FOREIGN KEY(`stepId`) REFERENCES `TimelineStep`(`stepId`),
	PRIMARY KEY(`stepId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `ResultWatchers`;

-- changeset fabianbuehler:qhana-backend-baseline-30 labels:v0
CREATE TABLE IF NOT EXISTS `PluginEndpoints` (
	`id`	INTEGER NOT NULL AUTO_INCREMENT,
	`url`	VARCHAR(1024) NOT NULL UNIQUE,
	`type`	VARCHAR(64) NOT NULL DEFAULT 'PluginRunner',
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- rollback DROP TABLE `PluginEndpoints`;
