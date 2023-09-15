<img alt="RestTestGen's Logo" src="https://static.corradinidavi.de/img/rtg/rtg-logo-light.svg" style="width: 500px;"/>

# RestTestGen: a tool and framework for automated black-box testing of RESTful APIs.

> **Citing our work:** bibtex entries for our papers are available in the [CITE.md](CITE.md) file.

RestTestGen is a robust tool and framework designed for automated black-box testing of RESTful web APIs. As a testing tool, it incorporates various testing strategies that prove valuable in identifying bugs and vulnerabilities within the API being tested. Operating exclusively as a black-box end-to-end testing tool, it interacts with the API solely through HTTP, without necessitating access to the source code. The only requirement is an OpenAPI specification of the API being tested.

In addition to its role as a testing tool, RestTestGen also serves as a framework, offering multiple components and features to assist researchers, practitioners, and developers in implementing custom testing strategies. This framework empowers users to tailor their testing approach to specific requirements and explore innovative methods to enhance their API testing endeavors.

## Included testing strategies
- Nominal and error testing: performs nominal and error testing of the selected API. This is the default strategy.
- Mass assignment security testing: tests the selected API for mass assignment vulnerabilities.
- NLP-based enhancement of OpenAPI specifications: enhances the OpenAPI specification of the selected API by extracting constraints and example values from textual descriptions in natural language. Requires Rule Extraction service to be running at [http://localhost:4000/](). Download and deploy the Rule Extractor service from the [NLP2REST repository](https://github.com/codingsoo/nlp2rest/).

## Framework features
- Custom parser for OpenAPI (v3) specifications (JSON and YAML).
- Operation Dependency Graph (ODG) to model data dependencies among operations.
- Dictionaries to store values observed at testing time for future use.
- Smart parameter management using hierarchical data structures.
- Several way to generate or retrieve valid parameter values.
- Mutation operators (type, missing required, constraint violation).
- Response processors to elaborate responses.
- Operations sorters to provide customized operations testing orders (random, ODG-based).
- Oracles to evaluate test executions (status code oracles, security oracles).
- Writers to output test cases and test results to file (reports, JUnit + REST-assured).
- Coverage measurements (path, operations, status codes, parameters, parameter values).

---

## Changelog

### v23.09
- Fixed export of OpenAPI specifications, which caused some specifications to be invalid.
- Added support for export of combined schemas (e.g., `allOf`, `oneOf`, etc.) in exported specifications.
- Parameter value providers can be configured with a so-called "source class", allowing to specify the source of parameter values (this feature is working but not 100% precise in the current version):
  - `SELF`: values are sourced from the particular instance of the parameter.
  - `SAME_NAME`: values are sourced from all the parameters with the same name in the API. For instance, example values are source from all the parameters with the same name, potentially increasing the amount of valid values for the parameter.
  - `SAME_NORMALIZED_NAME`: values are sourced from all the parameters with the same normalized name (according to RestTestGen's normalization algorithm) in the API.
- New method to set values to parameter with providers, that stores the provider with which the value was gathered.
- Added new narrow random parameter value provider which chooses random values from narrower boundaries. E.g., not MIN_INT~MAX_INT, but 0~120.
- Parameter value providers are now instantiated through a cached factory which caches previous instances for optimization purposes.
- Fixed `TestRunner` that did not execute test interactions if 429 was not among the invalid status codes. 
- All responses containing JSON bodies are processed, independently of the declared response content-type. Previously, only responses with `application/json` as content type were processed, causing the loss of processing of potentially useful if the API responded with an inappropriate content-type (very common behavior, also in mainstream API).
- Improved log messages.

For the changelog of past versions, please see the [CHANGELOG.md](CHANGELOG.md) file.

---

## <a id="getting-started"></a> Getting started

### Prepare your API
As a testing tool and framework, RestTestGen requires interacting with a deployed instance of a REST API through HTTP. Make sure your API is reachable from the machine on which RestTestGen will be executed.

#### Configure the API in RestTestGen
RestTestGen requires some knowledge about the API under test. This includes details such as the location of its OpenAPI specification, and the authentication process, among others. All of this information must be provided within the designated *API directory*.

To create an API directory for your specific API, navigate to the `apis/` directory and create a subdirectory with a name of your choice, typically the API name. For instance, if you're working with the Book Store API, the API directory would be located at `apis/bookstore/`. Take a look at the Book Store API directory we provide out-of-the-box as an example of how to structure an API directory correctly.

The API directory can contain an API configuration file (`api-config.yml`) in which you can specify:
- `name`: the API name, solely for display purposes (takes the API directory name by default, e.g., `bookstore`).
- `specificationFileName`: the name of the specification file located in the `specifications/` subdirectory. (Default: `openapi.json`).
- ~~`host`: the address or name of the host at which the API is reachable. Overrides the server address specified in the OpenAPI specification of the API.~~ (Planned for next release).
- `authenticationCommands`: a map `<label, command>` listing authentication commands that when called will return authentication information to RestTestGen. See [Authentication](#auth) section for further details. (None by default).
- ~~`resetCommand`: a command that when called will reset the state of the API. (None by default).~~ (Planned for next release).
- ~~`resetBeforeTesting`: if set to `true`, RestTestGen will call the reset script before launching the testing strategy. (Default: `false`).~~ (Planned for next release).

You only need to specify the settings that you wish to override from their default values.

Example of API configuration:
```
name: Spotify
specificationFileName: spotify.json
host: "http://localhost:8080/"
authenticationCommands:
  default: "echo {\"name\": \"apikey\", \"value\": \"davide\", \"in\": \"query\", \"duration\": 6000}"
  admin: "python /path/to/script"
resetCommand: "python /path/to/script"
resetBeforeTesting: false
```

The API directory must contain a `specifications/` subdirectory in which is contained the OpenAPI specification of the API under test named as `openapi.json`, or with the custom name provided in the API configuration.

It is recommended to place authentication and reset scripts in the `scripts/` subdirectory.

Upon executing RestTestGen, a `results/` subdirectory will be automatically generated. This subdirectory will store the test results and output data of each testing session.

### Configuration
You can define preferences for RestTestGen itself, unrelated to the API under test, by specifying them in the `rtg-config.yaml` file located in the root directory. This configuration file is especially valuable for specifying the API to be tested and selecting the desired testing strategy.

The available preferences are:
- `logVerbosity`: the verbosity of the log in the standard output. Can be `DEBUG`, `INFO`, `WARN`, or `ERROR` (default: `INFO`).
- `testingSessionName`: the name of the testing session printed in the report files (default: `test-session-CURRENT_TIME`).
- `resultsLocation`: `local` or `global`, specifies whether the test results are going to be written in the API directory or in the root directory (default: `local`).
- `strategyClassName`: the name of the testing strategy class to be run (default: `NominalAndErrorStrategy`).
- `qualifiableNames`: list of parameter names to be qualified. E.g., `id` -> `bookId`, `name` -> `userName` (default: `['id', 'name']`).
- `odgFileName`: output file name for the operation dependency graph (default: `odg.dot`).

You only need to specify the settings that you wish to override from their default values.

Example of basic RestTestGen configuration to run the mass assignment security testing strategy on the VAmPI API:
```
apiUnderTest: vampi
strategyClassName: MassAssignmentSecurityTestingStrategy
```

### Building and running RestTestGen
You can build and run RestTestGen in three ways: either within a Docker container, on your machine with Gradle, or on your machine within the IntelliJ IDEA IDE. 

#### Docker

Requirements: Docker. For further information see the [REQUIREMENTS.md](REQUIREMENTS.md) file.

To build and run RestTestGen with Docker, follow these steps:
1. Build the image with: `docker build -t rtg .`
2. Run the container from the image with: `docker run -v ./:/app --network="host" rtg`

> The Docker container will only include Java 11 and Gradle 7.6.2, without Python. If your authentication or reset scripts rely on Python, we recommend running RestTestGen directly on your machine using Gradle. However, in upcoming versions of RestTestGen, we aim to provide a more comprehensive container that includes additional dependencies, such as Python, to better support authentication and reset scripts.

#### Gradle

Requirements: Java 11. For further information see the [REQUIREMENTS.md](REQUIREMENTS.md) file.

To build and run RestTestGen with Gradle, follow these steps:
1. Make sure the Gradle Wrapper file is executable. You can make it executable with `sudo chmod +x gradlew`
2. Build the project using Gradle wrapper: `./gradlew build`
3. Run the application: `./gradlew run`

#### IntelliJ IDEA

Requirements: Java 11 and IntelliJ IDEA. For further information see the [REQUIREMENTS.md](REQUIREMENTS.md) file.

If you prefer using IntelliJ IDEA, you can follow these steps to run RestTestGen:
1. Open IntelliJ IDEA and import the RestTestGen Gradle project.
2. Locate the `io.resttestgen.boot.cli.App` class.
3. Look for the `main` method in the `App` class.
4. Click the play icon next to the main method to run RestTestGen (the play icon will appear only after IntelliJ successfully indexed the project files).

### <a id="auth"></a>Authentication
> (skip this step if your REST API does not require authentication)

RestTestGen offers support for authenticated REST APIs. In order to collect authentication information, RestTestGen executes authentication commands (if provided in the API configuration) and expects the standard output of these command to be in the form of JSON objects. These objects represent authentication parameters and include four attributes: `name`, `value`, `in` (header, query, etc.), and `duration` (which determines when the authentication commands should be re-executed to obtain a new token after expiration).

An example of an authentication command could be `python3 /path/to/auth.py`, which executes the Python script located in the `auth.py` file. This user-provided script is responsible for performing the authentication process, such as obtaining the auth token, by interacting with the API via HTTP. It then prints the authentication information in the supported format by RestTestGen to the standard output, for example:
```
{
  "name": "Authorization",
  "value": "Bearer [TOKEN]",
  "in": "header",
  "duration": 600
}
```

The API configuration file allows you to define multiple authentication commands for various purposes, users, and roles. Each authentication command is labelled. RestTestGen currently supports only one command at a time, and it will use either the command labeled as `default` or, if no command is labeled as `default`, the first command in the list.

## Test results
Test results are located in the `results/` subdirectory of the API directory. This directory contains a list of the executed testing sessions for the API. The specific data included may vary depending on the chosen testing strategy. Typically, you will find the following:
- the Operation Dependency Graph (ODG) in dot format, stored in the `odg.dot` file.
- test reports located in the `report/` folder. These reports are JSON files that provide information about the executed HTTP test sequences and their corresponding results (pass/fail).
- JUnit + REST-assured test cases that allow for replaying the generated test cases.
- strategy-specific data, such as the enhanced specification generated by the NLP-based strategy.

## Contribution guidelines

We welcome contributions from researchers, practitioners, and developers.

If you wish to extend RestTestGen framework and its core components, please contribute to the `io.resttestgen.core` package. For those developing a novel testing strategy, we encourage contributions to the `io.resttestgen.implementation` package.

To submit your contribution, please create a pull request. Thank you for your support!