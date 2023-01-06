# FlutterFlow CLI

FlutterFlow CLI client. Currently it only allows exporting code from FlutterFlow.

## API Token

API access is available only to users with active subscriptions. Visit https://app.flutterflow.io/account to generate your API token.

Add `export FLUTTERFLOW_API_TOKEN='...'` to your `.bashrc` file or equivalent.

## Installation

`dart pub global activate flutterflow_cli`

## Usage

`FLUTTERFLOW_API_TOKEN='...' flutterflow export-code --project <project id> --dest <output folder> --[no-]include-assets`
