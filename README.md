# FlutterFlow CLI

FlutterFlow CLI client: download code from your FlutterFlow project to your device for local running or deployment.

## API Token

API access is available only to users with active subscriptions. Visit https://app.flutterflow.io/account to generate your API token.

## Installation

`dart pub global activate flutterflow_cli`

## Export Code

### Usage

`flutterflow export-code --project <project id> --dest <output folder> --[no-]include-assets --token <token> --[no-]fix --[no-]parent-folder --[no-]as-module --[no-]as-debug --[no-]use-package-asset-paths`

* Instead of passing `--token` you can set `FLUTTERFLOW_API_TOKEN` environment variable.
* Instead of passing `--project` you can set `FLUTTERFLOW_PROJECT` environment variable.

In case you are updating an existing project and you don't want existing files to be changed, you can create a `.flutterflowignore` file at the root of the output folder
with a list of files to be ignored using [globbing syntax](https://pub.dev/packages/glob#syntax).

### Flags

| Flag      | Abbreviation | Usage |
| ----------- | ----------- | ----------- |
| `--project`      | `-p`       | [Required or environment variable] Project ID. |
| `--token`      | `-t`       | [Required or environment variable] API Token. |
| `--dest`   | `-d`        | [Optional] Output folder. Defaults to the current directory if none is specified. |
| `--[no-]include-assets`   | None        | [Optional] Whether to include media assets. Defaults to `false`. |
| `--branch-name`   | `-b`        | [Optional] Which branch to download. Defaults to `main`. |
| `--[no-]fix`   | None        | [Optional] Whether to run `dart fix` on the downloaded code. Defaults to `false`. |
| `--[no-]parent-folder`   | None        | [Optional] Whether to download code into a project-named sub-folder. If true, downloads all project files directly to the specified directory. Defaults to `true`. |
| `--[no-]as-module`   | None        | [Optional] Whether to generate the project as a Flutter module. Defaults to `false`. |
| `--[no-]as-debug`   | None        | [Optional] Whether to generate the project with debug logging to be able to use FlutterFlow Debug Panel inside the DevTools. Defaults to `false`. |
| `--[no-]use-package-asset-paths`   | None        | [Optional] Whether to use package asset paths in the generated code. If enabled, all asset paths will be prepended with 'package/$projectName', making them correctly referenceable when importing this Flutter project as a package. Defaults to `false`. |
| `--project-environment`   | None        | [Optional] Which project environment to be used. If empty, the current environment in the project will be used.|
## Deploy Firebase

### Prerequisites

 `npm` and `firebase-tools` must be installed in order to deploy to Firebase. You can follow the instructions at https://firebase.google.com/docs/cli#install_the_firebase_cli.

### Usage

`flutterflow deploy-firebase --project <project id> --[no]-append-rules --token <token>`

* Instead of passing `--token` you can set `FLUTTERFLOW_API_TOKEN` environment variable.
* Instead of passing `--project` you can set `FLUTTERFLOW_PROJECT` environment variable.

### Flags

| Flag      | Abbreviation | Usage |
| ----------- | ----------- | ----------- |
| `--project`      | `-p`       | [Required or environment variable] Project ID. |
| `--token`      | `-t`       | [Required or environment variable] API Token. |
| `--append-rules`      | `-a`       | Whether to append to existing Firestore rules, instead of overwriting them. |

## Issues

Please file any issues in [this repository](https://github.com/flutterflow/flutterflow-issues).
