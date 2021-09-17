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

USE QHAnaExperiments;

START TRANSACTION;

CREATE TABLE IF NOT EXISTS `Experiment` (
	`experimentId`	INTEGER NOT NULL AUTO_INCREMENT,
	`name`	VARCHAR(500) NOT NULL,
	`description`	TEXT NOT NULL,
	PRIMARY KEY (`experimentId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX IF NOT EXISTS `ix_pk_experiment` ON `Experiment` (
	`experimentId`	ASC
);

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
CREATE INDEX IF NOT EXISTS `ix_pk_experiment_data` ON `ExperimentData` (
	`dataId`	ASC
);
CREATE INDEX IF NOT EXISTS `ix_fk_data_to_experiment` ON `ExperimentData` (
	`experimentId`
);
CREATE INDEX IF NOT EXISTS `ix_data_name` ON `ExperimentData` (
	`name`	ASC
);
CREATE INDEX IF NOT EXISTS `ix_data_version` ON `ExperimentData` (
	`version`	ASC
);
CREATE INDEX IF NOT EXISTS `ix_data_type` ON `ExperimentData` (
	`type`
);
CREATE INDEX IF NOT EXISTS `ix_data_contenttype` ON `ExperimentData` (
	`contentType`
);

-- `start`	DATETIME NOT NULL DEFAULT `strftime('%Y-%m-%dT%H:%M:%S', 'now')`, (does not work in sqlite, preserved here for later)
CREATE TABLE IF NOT EXISTS `TimelineStep` (
	`stepId`	INTEGER NOT NULL AUTO_INCREMENT,
	`experimentId`	INTEGER NOT NULL,
	`sequence`	INTEGER NOT NULL,
	`start`	DATETIME NOT NULL,
	`end`	DATETIME,
	`status`	VARCHAR(50) DEFAULT 'PENDING',
	`resultLog`	TEXT,
	`processorName`	VARCHAR(500) NOT NULL,
	`processorVersion`	VARCHAR(150),
	`processorLocation`	TEXT,
	`parameters`	TEXT NOT NULL,
	`parametersContentType`	VARCHAR(500) NOT NULL DEFAULT 'application/x-www-form-urlencoded',
	`parametersDescriptionLocation`	TEXT,
	`notes`	TEXT,
	FOREIGN KEY(`experimentId`) REFERENCES `Experiment`(`experimentId`),
	CONSTRAINT `ux_experiment_step` UNIQUE(`experimentId`,`sequence`),
	PRIMARY KEY(`stepId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX IF NOT EXISTS `ix_pk_experiment_step` ON `TimelineStep` (
	`stepId`	ASC
);
CREATE INDEX IF NOT EXISTS `ix_fk_step_to_experiment` ON `TimelineStep` (
	`experimentId`
);
CREATE INDEX IF NOT EXISTS `ix_step_sequence` ON `TimelineStep` (
	`sequence`
);
CREATE INDEX IF NOT EXISTS `ix_step_processor` ON `TimelineStep` (
	`processorName`
);

CREATE TABLE IF NOT EXISTS `StepData` (
	`id`	INTEGER NOT NULL AUTO_INCREMENT,
	`stepId`	INTEGER NOT NULL,
	`dataId`	INTEGER NOT NULL,
	`relationType`	VARCHAR(50) NOT NULL,
	FOREIGN KEY(`stepId`) REFERENCES `TimelineStep`(`stepId`),
	FOREIGN KEY(`dataId`) REFERENCES `ExperimentData`(`dataId`),
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX IF NOT EXISTS `ix_pk_step_data` ON `StepData` (
	`id`	ASC
);
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_to_step` ON `StepData` (
	`stepId`
);
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_to_data` ON `StepData` (
	`dataId`
);
CREATE INDEX IF NOT EXISTS `ix_fk_step_data_relation` ON `StepData` (
	`relationType`
);

CREATE TABLE IF NOT EXISTS `ResultWatchers` (
	`stepId`	INTEGER NOT NULL,
	`resultEndpoint`	TEXT NOT NULL,
	FOREIGN KEY(`stepId`) REFERENCES `TimelineStep`(`stepId`),
	PRIMARY KEY(`stepId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `PluginEndpoints` (
	`id`	INTEGER NOT NULL AUTO_INCREMENT,
	`url`	TEXT NOT NULL UNIQUE,
	`type`	VARCHAR(64) NOT NULL DEFAULT 'PluginRunner',
	PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

COMMIT;
