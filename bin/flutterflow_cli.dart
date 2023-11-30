import 'dart:io';

import 'package:args/args.dart';
import 'package:flutterflow_cli/src/flutterflow_cli_base.dart';

const kDefaultEndpoint = 'https://api.flutterflow.io/v1';

void main(List<String> args) async {
  final parsedArguments = _parseArgs(args);

  final token =
      parsedArguments['token'] ?? Platform.environment['FLUTTERFLOW_API_TOKEN'];

  final project = parsedArguments.command!['project'] ??
      Platform.environment['FLUTTERFLOW_PROJECT'];

  if (token?.isEmpty ?? true) {
    stderr.write(
        'Either --token option or FLUTTERFLOW_API_TOKEN environment variable must be set.\n');
    exit(1);
  }

  await exportCode(
    token: token,
    endpoint: parsedArguments['endpoint'] ?? kDefaultEndpoint,
    projectId: project,
    destinationPath: parsedArguments.command!['dest'],
    includeAssets: parsedArguments.command!['include-assets'],
    branchName: parsedArguments.command!['branch-name'],
    unzipToParentFolder: parsedArguments.command!['parent-folder'],
    fix: parsedArguments.command!['fix'],
  );
}

ArgResults _parseArgs(List<String> args) {
  final exportCodeCommandParser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Project id')
    ..addOption('dest',
        abbr: 'd', help: 'Destination directory', defaultsTo: '.')
    ..addOption('branch-name',
        abbr: 'b', help: '(Optional) Specify a branch name')
    ..addFlag(
      'include-assets',
      negatable: true,
      help: 'Include assets. By default, assets are not included.\n'
          'We recommend setting this flag only when calling this command '
          'for the first time or after updating assets.\n'
          'Downloading code without assets is typically much faster.',
      defaultsTo: false,
    )
    ..addFlag(
      'fix',
      negatable: true,
      help: 'Run "dart fix" on the downloaded code.',
      defaultsTo: false,
    )
    ..addFlag(
      'parent-folder',
      negatable: true,
      help: 'Download into a sub-folder. By default, project is downloaded \n'
          'into a folder named <project>.\nSetting this flag to false will '
          'download all project code directly into the specified directory, '
          'or the current directory if --dest is not set.',
      defaultsTo: true,
    );

  final parser = ArgParser()
    ..addOption('endpoint', abbr: 'e', help: 'Endpoint', hide: true)
    ..addOption('token', abbr: 't', help: 'API Token')
    ..addFlag('help', negatable: false, abbr: 'h', help: 'Help')
    ..addCommand('export-code', exportCodeCommandParser);

  late ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } catch (e) {
    stderr.write('$e\n');
    stderr.write(parser.usage);
    exit(1);
  }

  if (parsed['help'] ?? false) {
    print(parser.usage);
    if (parsed.command != null) {
      print(parser.commands[parsed.command!.name]!.usage);
    } else {
      print('Available commands: ${parser.commands.keys.join(', ')}.');
    }
    exit(0);
  }

  if (parsed.command == null) {
    print(parser.usage);
    print('Available commands: ${parser.commands.keys.join(', ')}.');
    exit(1);
  }

  if (parsed.command!['project'] == null ||
      parsed.command!['project'].isEmpty) {
    stderr.write(
        'Either --project option or FLUTTERFLOW_PROJECT environment variable must be set.\n');
    exit(1);
  }
  return parsed;
}
