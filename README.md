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

```bash
# first time only
bash create-sqlite-db.sh

# insert localhost plugin runner endpoint
echo 'INSERT INTO PluginEndpoints (url, type) VALUES ("http://localhost:5005", "PluginRunner");' | sqlite3 qhana-backend.db

# start qhana backend
bal run
```

The API is available at the configured port in `main.bal` (currently 9090).

## Troubleshooting
- Running ballerina in a directory with a space in it's name currently doesn't work. Sample stacktrace:  
  ```
  Unrecognized option: -
  Error: Could not create the Java Virtual Machine.
  Error: A fatal exception has occurred. Program will exit.
  ```
  Issue should be resolved soon.

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





## Acknowledgements

Current development is supported by the [Federal Ministry for Economic Affairs and Energy](http://www.bmwi.de/EN) as part of the [PlanQK](https://planqk.de) project (01MK20005N).

## Haftungsausschluss

Dies ist ein Forschungsprototyp.
Die Haftung für entgangenen Gewinn, Produktionsausfall, Betriebsunterbrechung, entgangene Nutzungen, Verlust von Daten und Informationen, Finanzierungsaufwendungen sowie sonstige Vermögens- und Folgeschäden ist, außer in Fällen von grober Fahrlässigkeit, Vorsatz und Personenschäden, ausgeschlossen.

## Disclaimer of Warranty

Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.
You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.
