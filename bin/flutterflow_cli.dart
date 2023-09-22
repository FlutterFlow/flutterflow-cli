import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_util;

const kDefaultEndpoint = 'https://api.flutterflow.io/v1';

void main(List<String> args) async {
  final parsedArguments = _parseArgs(args);

  final token =
      parsedArguments['token'] ?? Platform.environment['FLUTTERFLOW_API_TOKEN'];

  if (token?.isEmpty ?? true) {
    stderr.write(
        'Either --token option or FLUTTERFLOW_API_TOKEN environment variable must be set.\n');
    exit(1);
  }

  await _exportCode(
    token: token,
    endpoint: parsedArguments['endpoint'] ?? kDefaultEndpoint,
    projectId: parsedArguments.command!['project'],
    destinationPath: parsedArguments.command!['dest'],
    includeAssets: parsedArguments.command!['include-assets'],
    branchName: parsedArguments.command!['branch-name'],
  );
}

ArgResults _parseArgs(List<String> args) {
  final exportCodeCommandParser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Project id')
    ..addOption('dest',
        abbr: 'd', help: 'Destination directory', defaultsTo: '.')
    ..addOption('branch-name',
        abbr: 'b', help: '(Optional) Specifiy a branch name')
    ..addFlag(
      'include-assets',
      negatable: true,
      help: 'Include assets. By default, assets are not included.\n'
          'We recommend setting this flag only when calling this command '
          'for the first time or after updating assets.\n'
          'Downloading code without assets is typically much faster.',
      defaultsTo: false,
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
    stderr.write('Option --project is required\n');
    exit(1);
  }

  return parsed;
}

Future _exportCode({
  required String token,
  required String endpoint,
  required String projectId,
  required String destinationPath,
  required bool includeAssets,
  String? branchName,
}) async {
  final endpointUrl = Uri.parse(endpoint);
  final client = http.Client();
  try {
    final result = await _callExport(
      client: client,
      token: token,
      endpoint: endpointUrl,
      projectId: projectId,
      branchName: branchName,
    );

    // Download actual code
    final projectZipBytes = base64Decode(result['project_zip']);
    final projectFolder = ZipDecoder().decodeBytes(projectZipBytes);
    extractArchiveToDisk(projectFolder, destinationPath);

    // Download assets
    if (includeAssets) {
      await _downloadAssets(
        client: client,
        destinationPath: destinationPath,
        assetDescriptions: result['assets'],
      );
    }
  } finally {
    client.close();
  }
}

Future<dynamic> _callExport({
  required final http.Client client,
  required String token,
  required Uri endpoint,
  required String projectId,
  String? branchName,
}) async {
  final body = jsonEncode({
    'project': {
      'path': 'projects/$projectId',
    },
    'token': token,
    if (branchName != null) 'branch_name': branchName,
  });
  final response = await client.post(
    Uri.https(endpoint.host, '${endpoint.path}/exportCode'),
    body: body,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    stderr.write('Unexpected error from the server.\n');
    stderr.write('Status: ${response.statusCode}\n');
    stderr.write('Body: ${response.body}\n');
    exit(1);
  }

  final parsedResponse = jsonDecode(response.body);
  final success = parsedResponse['success'];
  if (success == null || !success) {
    if (parsedResponse['reason'] != null &&
        parsedResponse['reason'].isNotEmpty) {
      stderr.write('Error: ${parsedResponse['reason']}.\n');
    } else {
      stderr.write('Unexpected server error.\n');
    }
    exit(1);
  }

  return parsedResponse['value'];
}

// TODO: limit the number of parallel downloads.
Future _downloadAssets({
  required final http.Client client,
  required String destinationPath,
  required List<dynamic> assetDescriptions,
}) async {
  final futures = assetDescriptions.map((assetDescription) async {
    final path = assetDescription['path'];
    final url = assetDescription['url'];
    final fileDest = path_util.join(destinationPath, path);
    try {
      final response = await client.get(Uri.parse(url));
      final file = File(fileDest);
      await file.writeAsBytes(response.bodyBytes);
    } catch (_) {
      stderr.write('Error downloading asset $path. This is probably fine.\n');
    }
  });
  await Future.wait(futures);
}
