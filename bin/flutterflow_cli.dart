import 'dart:io';

import 'package:args/args.dart';
import 'package:flutterflow_cli/flutterflow_cli.dart';

const kDefaultEndpoint = 'https://api.flutterflow.io/v1';

Future<void> appMain(List<String> args) async {
  final parsedArguments = _parseArgs(args);
  late Map<String,String> projectInfo;

  if (parsedArguments.command?.name != 'cleanup-files') {
    projectInfo=getProjectInfo(parsedArguments);
  }

  try {
    switch (parsedArguments.command?.name) {
      case 'export-code':
        await exportCode(
          token: projectInfo['token']!,
          endpoint: projectInfo['endpoint']!,
          projectId: projectInfo['project']!,
          destinationPath: parsedArguments.command!['dest'],
          includeAssets: parsedArguments.command!['include-assets'],
          branchName: parsedArguments.command!['branch-name'],
          commitHash: parsedArguments.command!['commit-hash'],
          unzipToParentFolder: parsedArguments.command!['parent-folder'],
          fix: parsedArguments.command!['fix'],
          exportAsModule: parsedArguments.command!['as-module'],
          exportAsDebug: parsedArguments.command!['as-debug'],
          environmentName: parsedArguments.command!['project-environment'],
        );
        break;
      case 'deploy-firebase':
        await firebaseDeploy(
          token: projectInfo['token']!,
          endpoint: projectInfo['endpoint']!,
          projectId: projectInfo['project']!,
          appendRules: parsedArguments.command!['append-rules'],
        );
        break;
      case 'cleanup-files':
        await cleanupFiles(
            autoDelete: parsedArguments.command!['auto-delete'],
            folderPath: parsedArguments.command!['path']);
        break;
      default:
    }
  } catch (e) {
    stderr.write('Error running the application: $e\n');
    exit(1);
  }
}

ArgResults _parseArgs(List<String> args) {
  final exportCodeCommandParser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Project id')
    ..addOption(
      'dest',
      abbr: 'd',
      help: 'Destination directory',
      defaultsTo: '.',
    )
    ..addOption(
      'branch-name',
      abbr: 'b',
      help: '(Optional) Specify a branch name',
    )
    ..addOption(
      'commit-hash',
      abbr: 'c',
      help: '(Optional) Specify a commit hash',
    )
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
    )
    ..addFlag(
      'as-module',
      negatable: true,
      help: 'Generate the project as a Flutter module.',
      defaultsTo: false,
    )
    ..addFlag(
      'as-debug',
      negatable: true,
      help: 'Generate the project with debug logging to be able to use '
          'FlutterFlow Debug Panel inside the DevTools.',
      defaultsTo: false,
    )
    ..addOption(
      'project-environment',
      help: '(Optional) Specify a project environment name.',
    );

  final firebaseDeployCommandParser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Project id')
    ..addFlag(
      'append-rules',
      abbr: 'a',
      help: 'Append to rules, instead of overwriting them.',
      defaultsTo: false,
    );

  final cleanupFilesCommandParser = ArgParser()
    ..addOption('path', help: 'Project path', defaultsTo: '')
    ..addFlag('auto-delete',
        abbr: 'd',
        help: 'Automatically delete unused files',
        negatable: true,
        defaultsTo: false);

  final parser = ArgParser()
    ..addOption('endpoint', abbr: 'e', help: 'Endpoint', hide: true)
    ..addOption('environment', help: 'Environment', hide: true)
    ..addOption('token', abbr: 't', help: 'API Token')
    ..addFlag('help', negatable: false, abbr: 'h', help: 'Help')
    ..addCommand('export-code', exportCodeCommandParser)
    ..addCommand('deploy-firebase', firebaseDeployCommandParser)
    ..addCommand('cleanup-files', cleanupFilesCommandParser);

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

  return parsed;
}

/// Retrieves API Token, Project ID, and Endpoint
Map<String, String> getProjectInfo(ArgResults parsedArguments) {
  final token = parsedArguments['token'] ?? Platform.environment['FLUTTERFLOW_API_TOKEN'];
  final project = parsedArguments.command?['project'] ?? Platform.environment['FLUTTERFLOW_PROJECT'];

  if (project == null || project.isEmpty) {
    stderr.writeln('Error: Either --project option or FLUTTERFLOW_PROJECT environment variable must be set.');
    exit(1);
  }

  if (token == null || token.isEmpty) {
    stderr.writeln('Error: Either --token option or FLUTTERFLOW_API_TOKEN environment variable must be set.');
    exit(1);
  }

  String endpoint = kDefaultEndpoint;
  if (parsedArguments['endpoint'] != null && parsedArguments['environment'] != null) {
    stderr.writeln('Error: Only one of --endpoint and --environment options can be set.');
    exit(1);
  } else if (parsedArguments['endpoint'] != null) {
    endpoint = parsedArguments['endpoint'];
  } else if (parsedArguments['environment'] != null) {
    endpoint = "https://api-${parsedArguments['environment']}.flutterflow.io/v1";
  }

  return {'token': token, 'project': project, 'endpoint': endpoint};
}

void main(List<String> args) async {
  await appMain(args);
}
