# FlutterFlow CLI

FlutterFlow CLI client: download code from your FlutterFlow project to your device for local running or deployment.

## API Token

API access is available only to users with active subscriptions. Visit https://app.flutterflow.io/account to generate your API token.

## Installation

`dart pub global activate flutterflow_cli`

## Usage

`flutterflow export-code --project <project id> --dest <output folder> --[no-]include-assets --token <token> --[no-]fix --[no-]parent-folder --[no-]as-module`

* Instead of passing `--token` you can set `FLUTTERFLOW_API_TOKEN` environment variable.
* Instead of passing `--project` you can set `FLUTTERFLOW_PROJECT` environment variable.

## Flags

| Flag      | Abbreviation | Usage |
| ----------- | ----------- | ----------- |
| `--project`      | `-p`       | [Required or environment variable] Project ID. |
| `--token`      | `-t`       | [Required or environment variable] API Token. |
| `--dest`   | `-d`        | [Optional] Output folder. Defaults to the current directory if none is specified. |
| `--[no-]include-assets`   | None        | [Optional] Whether to include media assets. Defaults to `false`. |
| `--branch-name`   | `-b`        | [Optional] Which branch to download. Defaults to `main`. |
| `--[no-]fix`   | None        | [Optional] Whether to run `dart fix` on the downloaded code. Defaults to `false`. |
| `--[no-]parent-folder`   | None        | [Optional] Whether to download code into a project-named sub-folder. If true, downloads all project files directly to the specified directory. Defaults to `true`. |
| `--[no-]as-module`   | None        | [Optional] Whether to generate the project as a Flutter module |

## Issues

Please file any issues in [this repository](https://github.com/flutterflow/flutterflow-issues).
