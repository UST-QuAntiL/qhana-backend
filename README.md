# QHAna Backend API

[![GitHub license](https://img.shields.io/github/license/UST-QuAntiL/qhana-backend)](https://github.com/UST-QuAntiL/qhana-backend/blob/main/LICENSE)

The QHAna Backend API is implemented in [Ballerina](https://ballerina.io) (swan-lake Beta 2).

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

```bash
# first time only
bash create-sqlite-db.sh

# start qhana backend
bal run
```

The API is available at the configured port in `main.bal` (currently 9090).




## Acknowledgements

Current development is supported by the [Federal Ministry for Economic Affairs and Energy](http://www.bmwi.de/EN) as part of the [PlanQK](https://planqk.de) project (01MK20005N).

## Haftungsausschluss

Dies ist ein Forschungsprototyp.
Die Haftung für entgangenen Gewinn, Produktionsausfall, Betriebsunterbrechung, entgangene Nutzungen, Verlust von Daten und Informationen, Finanzierungsaufwendungen sowie sonstige Vermögens- und Folgeschäden ist, außer in Fällen von grober Fahrlässigkeit, Vorsatz und Personenschäden, ausgeschlossen.

## Disclaimer of Warranty

Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.
You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.
