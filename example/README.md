## Installation
```sh
dart pub global activate flutterflow_cli
```

## How to use

Base command with required flags:
```sh
flutterflow export-code --project ProjectID --token APIToken
```
See [README](https://pub.dev/packages/flutterflow_cli) for the full list of available flags.

## Setting API Token Variable

Your API Token can be added as the environment variable `FLUTTERFLOW_API_TOKEN`. This means you don't have to manually pass the `--token` flag. 

See your corresponding operating system guide:

* [MacOS](https://support.apple.com/en-gb/guide/terminal/apd382cc5fa-4f58-4449-b20a-41c53c006f8f/mac)
* [Linux](https://linuxize.com/post/how-to-set-and-list-environment-variables-in-linux/#persistent-environment-variables)
* [Windows](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.4#saving-environment-variables-with-the-system-control-panel)