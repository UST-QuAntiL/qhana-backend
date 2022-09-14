# QHAna Backend API

[![GitHub license](https://img.shields.io/github/license/UST-QuAntiL/qhana-backend)](https://github.com/UST-QuAntiL/qhana-backend/blob/main/LICENSE)

The QHAna Backend API is implemented in [Ballerina](https://ballerina.io) (swan-lake Beta 3).

Please use the following resources to make yourself familiar with Ballerina:

  * [Installation instructions](https://ballerina.io/learn/user-guide/getting-started/setting-up-ballerina/)
  * [Hello world](https://ballerina.io/learn/user-guide/getting-started/writing-your-first-ballerina-program/)
  * [General documentation](https://ballerina.io/learn/)
  * [Video introduction fo language features](https://www.youtube.com/watch?v=My_uqtHvXV8&list=PL7JOecNWBb0KX8RGAjF-oRknb_YIYN-dR)

VSCode is the recommended editor for Ballerina projects.

## Development

Install Ballerina using the instructions linked above.
Then use the `bal` cli or vscode to run the project.
Before the first run create a sqlite database with the provided schema.

:warning: When updating from `slbeta2` it can happen that the dependency resolution of ballerina fails.
In these cases try deleting the ballerina repository cache in the folder `~/.ballerina/repositories/`.

:waring: When updating to the swan-lake release from a beta release please follow <https://ballerina.io/downloads/swan-lake-release-notes/2201-0-0-swan-lake/> closely!

Install [Liquibase](https://www.liquibase.org/download) following the instructions in the link. 

```bash
# create or update the sqlite db 
bash update-sqlite-db.sh

# start qhana backend
bal run
```

The API is available at the configured port in `main.bal` (currently 9090).

## DB schema changes
Schema changes need to be added as changesets in the respective changelogs for sqlite and mariadb. For more information, visit [Liquibase](https://www.liquibase.org/get-started/quickstart). To apply all changes in the dev environment, you can run:
```bash
liquibase update
```

## Troubleshooting
- Running ballerina in a directory with a space in its name currently does not work and results in the following error:  
  ```
  Unrecognized option: -
  Error: Could not create the Java Virtual Machine.
  Error: A fatal exception has occurred. Program will exit.
  ```
  The issue should be resolved soon.

## Configuration

(See also <https://github.com/ballerina-platform/ballerina-spec/blob/master/configurable/spec.md>)

The backend can be configured by supplying a `toml` configuration file.
Any variable marked as `configurable` can be changed in that config.
The configuration should be specified in a file `Config.toml` (though the file location and name can be changed by providing an environment variable).
A config template that can be copied and renamed is provided under the name `Config-template.toml`.

### MariaDB

To use a MariaDB database change `qhana.qhana_backend.database.dbType` to `"mariadb"` in the config and provide the right config values for your database.

### CORS

For the frontend to be able to communicate normally with the backend the backend must include the domain of the frontend in its CORS header.
This can be configured with `qhana.qhana_backend.corsDomains`.


## Building the Docker image

You can build a Docker image for the QHAna backend with this command: `docker build -t qhana-backend .`


## Starting a Docker container

Run a container with this image and bind it to port 9090 with `docker run -p 9090:9090 qhana-backend` if you want to run the container detached add the flag `-d`.


### Configuration Handling

The QHAna backend can be configured using a toml config file or with environment variables.
See `Config-template.toml` for how the backend can be configured using a toml file.
The file has to be named `Config.toml` and must be in the current working directory the backend is started from.

Environment variables to configure the backend with:

| Variable | Example | Explanation |
|:---------|:--------|:------------|
| QHANA_DB_TYPE | `sqlite`\|`mariadb`\|`mysql` | The type of DB to connect to. |
| QHANA_DB_PATH | `qhana-backend.db` | The path to the sqlite DB. |
| QHANA_DB_HOST | `localhost:3306` | The host of a mysql or mariadb DB. |
| QHANA_DB_NAME | `QHAnaBackend` | The mysql or mariadb database name to use. |
| QHANA_DB_USER | `dbuser` | The mysql or mariadb user. |
| QHANA_DB_PASSWORD | `****` | The mysql or mariadb password. |
| QHANA_STORAGE_LOCATION | `experimentData` | The path where experiment data is stored by the backend. |
| QHANA_PORT | `9090` | The port where the backend listens. |
| QHANA_HOST | `http://localhost:9090` | The host base url of the backend including protocol and port. |
| QHANA_CORS_DOMAINS | `http://localhost:4200` | Domains for which cors requests are allowed. Entries are separated by any whitespace. |
| QHANA_WATCHER_INTERVALLS | `1 10 10 5 60` | Configuration for the result watcher intervalls. Event entries are intervalls (in seconds) and odd entries specify after how many iterations the next intervall in the list is used. |
| QHANA_URL_MAPPING | `{"(?<=^\|https?://)localhost(:[0-9]+)?": "host.docker.internal$1"}` | A map of rewrite rules for plugin result URLs. The map is a JSON object whose keys are regex patterns and whose values are the replacement strings for these patterns. All rules are applied to an URL without a guaranteed order. |
| QHANA_PLUGINS | `["http://localhost:5005/plugins/hello-world@v0-1-0/", "http://localhost:5005/plugins/entity-filter@v0-1-0/"]` | A list (JSON list/array) of plugin URLs. |
| QHANA_PLUGIN_RUNNERS | `["http://localhost:5005"]` | The list (JSON list/array) of plugin runner URLs. |


## Acknowledgements

Current development is supported by the [Federal Ministry for Economic Affairs and Climate Action (BMWK)] as part of the [PlanQK] project (01MK20005N).

   [Federal Ministry for Economic Affairs and Climate Action (BMWK)]: https://www.bmwk.de/EN
   [PlanQK]: https://planqk.de

## Haftungsausschluss

Dies ist ein Forschungsprototyp. Die Haftung für entgangenen Gewinn, Produktionsausfall, Betriebsunterbrechung,
entgangene Nutzungen, Verlust von Daten und Informationen, Finanzierungsaufwendungen sowie sonstige Vermögens- und
Folgeschäden ist, außer in Fällen von grober Fahrlässigkeit, Vorsatz und Personenschäden, ausgeschlossen.

## Disclaimer of Warranty

Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its
Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including,
without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work
and assume any risks associated with Your exercise of permissions under this License.
