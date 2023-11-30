# Installation
```sh
`dart pub global activate flutterflow_cli`
```

# How to use

Base command with required flags:
```sh
`flutterflow export-code --project <project id> --dest <output folder> --[no-]include-assets --token <token> --[no-]fix --[no]-parent-folder`
```

# Setting API Token as an Environment Variable

Your API Token can be added as an environment variable `FLUTTERFLOW_API_TOKEN` which will mean you don't have to manually pass the `--token` flag. 

See your corresponding operating system guide:
* (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.4#saving-environment-variables-with-the-system-control-panel)[Windows]