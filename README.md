# FlutterFlow CLI

FlutterFlow CLI client. Currently it only allows exporting code from FlutterFlow.

## API Token

API access is available only to users with active subscriptions. Visit https://app.flutterflow.io/account to generate your API token.

## Installation

`dart pub global activate flutterflow_cli`

## Usage

`flutterflow export-code --project <project id> --dest <output folder> --[no-]include-assets --token <token>`

Alternatively, instead of passing `--token` you can set `FLUTTERFLOW_API_TOKEN` environment variable.

## Issues

Please file any issues in [this repository](https://github.com/flutterflow/flutterflow-issues).
