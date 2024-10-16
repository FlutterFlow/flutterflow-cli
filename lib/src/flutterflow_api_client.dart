import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_util;

const kDefaultEndpoint = 'https://api.flutterflow.io/v1';

/// The `FlutterFlowApi` class provides methods for exporting code from a
/// FlutterFlow project.
class FlutterFlowApi {
  /// Exports the code from a FlutterFlow project.
  ///
  /// * [token] is the FlutterFlow API token for accessing the project.
  /// * [projectId] is the ID of the project to export.
  /// * [destinationPath] is the path where the exported code will be saved.
  /// * [includeAssets] flag indicates whether to include project assets
  /// in the export.
  /// * [endpoint] is the API endpoint to use for exporting the code.
  /// * [branchName] is the name of the branch to export from (optional).
  /// * [unzipToParentFolder] flag indicates whether to unzip the exported code
  /// to the parent folder.
  /// * [fix] flag indicates whether to fix any issues in the exported code.
  /// * [exportAsModule] flag indicates whether to export the code as a module.
  /// * [format] flag indicates whether to format the exported code.
  /// * [exportAsDebug] flag indicates whether to export the code as debug for
  /// local run.
  /// * [environmentName] is the name of the environment to export the code for.
  ///
  /// Returns a [Future] that completes with the path to the exported code, or
  /// throws an error if the export fails.
  static Future<String?> export({
    required String token,
    required String projectId,
    required String destinationPath,
    required bool includeAssets,
    String endpoint = kDefaultEndpoint,
    String? branchName,
    String? environmentName,
    String? commitHash,
    bool unzipToParentFolder = false,
    bool fix = false,
    bool exportAsModule = false,
    bool format = true,
    bool exportAsDebug = false,
  }) =>
      exportCode(
        token: token,
        endpoint: endpoint,
        projectId: projectId,
        destinationPath: destinationPath,
        includeAssets: includeAssets,
        branchName: branchName,
        commitHash: commitHash,
        unzipToParentFolder: unzipToParentFolder,
        fix: fix,
        exportAsModule: exportAsModule,
        format: format,
        exportAsDebug: exportAsDebug,
      );
}

Future<String?> exportCode({
  required String token,
  required String endpoint,
  required String projectId,
  required String destinationPath,
  required bool includeAssets,
  required bool unzipToParentFolder,
  required bool fix,
  required bool exportAsModule,
  bool format = true,
  String? branchName,
  String? environmentName,
  String? commitHash,
  bool exportAsDebug = false,
}) async {
  stdout.write('Downloading code with the FlutterFlow CLI...\n');
  stdout.write('You are exporting project $projectId.\n');
  stdout.write(
      '${branchName != null ? 'Branch: $branchName ' : ''}${environmentName != null ? 'Environment: $environmentName ' : ''}${commitHash != null ? 'Commit: $commitHash' : ''}\n');
  if (exportAsDebug && exportAsModule) {
    throw 'Cannot export as module and debug at the same time.';
  }
  final endpointUrl = Uri.parse(endpoint);
  final client = http.Client();
  String? folderName;
  try {
    final result = await _callExport(
      client: client,
      token: token,
      endpoint: endpointUrl,
      projectId: projectId,
      branchName: branchName,
      environmentName: environmentName,
      commitHash: commitHash,
      exportAsModule: exportAsModule,
      includeAssets: includeAssets,
      format: format,
      exportAsDebug: exportAsDebug,
    );
    // Download actual code
    final projectZipBytes = base64Decode(result['project_zip']);
    final projectFolder = ZipDecoder().decodeBytes(projectZipBytes);

    if (unzipToParentFolder) {
      extractArchiveToDisk(projectFolder, destinationPath);
    } else {
      extractArchiveToCurrentDirectory(projectFolder, destinationPath);
    }

    stdout.write('Successfully downloaded the code!\n');

    folderName = projectFolder.first.name;

    final postCodeGenerationFutures = <Future>[
      if (fix)
        _runFix(
          destinationPath: destinationPath,
          projectFolder: projectFolder,
          unzipToParentFolder: unzipToParentFolder,
        ),
      if (includeAssets)
        _downloadAssets(
          client: client,
          destinationPath: destinationPath,
          assetDescriptions: result['assets'],
          unzipToParentFolder: unzipToParentFolder,
        ),
    ];

    if (postCodeGenerationFutures.isNotEmpty) {
      await Future.wait(postCodeGenerationFutures);
    }
  } finally {
    client.close();
  }
  stdout.write('All done!\n');
  return folderName;
}

// Extract files to the specified directory without a project-named
// parent folder.
void extractArchiveToCurrentDirectory(
  Archive projectFolder,
  String destinationPath,
) {
  for (final file in projectFolder.files) {
    if (file.isFile) {
      final data = file.content as List<int>;
      final filename = file.name;

      // Remove the `<project>` prefix from paths.
      final path = path_util.join(
          destinationPath,
          path_util.joinAll(
            path_util.split(filename).sublist(1),
          ));

      final fileOut = File(path);
      fileOut.createSync(recursive: true);
      fileOut.writeAsBytesSync(data);
    }
  }
}

Future<dynamic> _callExport({
  required final http.Client client,
  required String token,
  required Uri endpoint,
  required String projectId,
  String? branchName,
  String? environmentName,
  String? commitHash,
  required bool exportAsModule,
  required bool includeAssets,
  required bool format,
  required bool exportAsDebug,
}) async {
  final body = jsonEncode({
    'project': {'path': 'projects/$projectId'},
    if (branchName != null) 'branch_name': branchName,
    if (environmentName != null) 'environment_name': environmentName,
    if (commitHash != null) 'commit': {'path': 'commits/$commitHash'},
    'export_as_module': exportAsModule,
    'include_assets_map': includeAssets,
    'format': format,
    'export_as_debug': exportAsDebug,
  });
  return await _callEndpoint(
    client: client,
    token: token,
    url: Uri.https(endpoint.host, '${endpoint.path}/exportCode'),
    body: body,
  );
}

Future<dynamic> _callEndpoint({
  required final http.Client client,
  required String token,
  required Uri url,
  required String body,
}) async {
  final response = await client.post(
    url,
    body: body,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 429) {
    throw 'Too many requests. Please try again later.';
  }

  if (response.statusCode != 200) {
    stderr.write('Unexpected error from the server.\n');
    stderr.write('Status: ${response.statusCode}\n');
    stderr.write('Body: ${response.body}\n');
    throw ('Unexpected error from the server.');
  }

  final parsedResponse = jsonDecode(response.body);
  final success = parsedResponse['success'];
  if (success == null || !success) {
    if (parsedResponse['reason'] != null &&
        parsedResponse['reason'].isNotEmpty) {
      stderr.write('Error: ${parsedResponse['reason']}.\n');
      throw 'Error: ${parsedResponse['reason']}.';
    } else {
      stderr.write('Unexpected server error.\n');
      throw 'Unexpected server error.';
    }
  }

  return parsedResponse['value'];
}

// TODO: limit the number of parallel downloads.
Future _downloadAssets({
  required final http.Client client,
  required String destinationPath,
  required List<dynamic> assetDescriptions,
  required unzipToParentFolder,
}) async {
  final futures = assetDescriptions.map((assetDescription) async {
    String path = assetDescription['path'];

    if (!unzipToParentFolder) {
      path = path_util.joinAll(
        path_util.split(path).sublist(1),
      );
    }
    final url = assetDescription['url'];
    final fileDest = path_util.join(destinationPath, path);
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final file = File(fileDest);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        stderr.write('Error downloading asset $path. This is probably fine.\n');
      }
    } catch (_) {
      stderr.write('Error downloading asset $path. This is probably fine.\n');
    }
  });
  stdout.write('Downloading assets...\n');
  await Future.wait(futures);
}

Future _runFix({
  required String destinationPath,
  required Archive projectFolder,
  required unzipToParentFolder,
}) async {
  try {
    if (projectFolder.isEmpty) {
      return;
    }
    final firstFilePath = projectFolder.files.first.name;
    final directory = path_util.split(firstFilePath).first;

    final workingDirectory = unzipToParentFolder
        ? path_util.join(destinationPath, directory)
        : destinationPath;
    stdout.write('Running flutter pub get...\n');
    final pubGetResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: workingDirectory,
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (pubGetResult.exitCode != 0) {
      stderr.write(
          '"flutter pub get" failed with code ${pubGetResult.exitCode}, stderr:\n${pubGetResult.stderr}\n');
      return;
    }
    stdout.write('Running dart fix...\n');
    final fixDirectory = unzipToParentFolder ? directory : '';
    final dartFixResult = await Process.run(
      'dart',
      ['fix', '--apply', fixDirectory],
      workingDirectory: destinationPath,
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (dartFixResult.exitCode != 0) {
      stderr.write(
          '"dart fix" failed with code ${dartFixResult.exitCode}, stderr:\n${dartFixResult.stderr}\n');
    }
  } catch (e) {
    stderr.write('Error running "dart fix": $e\n');
  }
}

Future firebaseDeploy({
  required String token,
  required String projectId,
  bool appendRules = false,
  String endpoint = kDefaultEndpoint,
}) async {
  final endpointUrl = Uri.parse(endpoint);
  final body = jsonEncode({
    'project': {'path': 'projects/$projectId'},
    'append_rules': appendRules,
  });
  final result = await _callEndpoint(
    client: http.Client(),
    token: token,
    url: Uri.https(
        endpointUrl.host, '${endpointUrl.path}/exportFirebaseDeployCode'),
    body: body,
  );

  // Download actual code
  final projectZipBytes = base64Decode(result['firebase_zip']);
  final firebaseProjectId = result['firebase_project_id'];
  final projectFolder = ZipDecoder().decodeBytes(projectZipBytes);
  Directory? tmpFolder;

  try {
    tmpFolder =
        Directory.systemTemp.createTempSync('${projectId}_$firebaseProjectId');
    extractArchiveToCurrentDirectory(projectFolder, tmpFolder.path);
    final firebaseDir = '${tmpFolder.path}/firebase';

    // Install required modules for deployment.
    await Process.run(
      'npm',
      ['install'],
      workingDirectory: '$firebaseDir/functions',
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    // This directory only exists if there were custom cloud functions.
    if (Directory('$firebaseDir/custom_cloud_functions').existsSync()) {
      await Process.run(
        'npm',
        ['install'],
        workingDirectory: '$firebaseDir/custom_cloud_functions',
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    }

    stdout.write('Initializing firebase...\n');
    await Process.run(
      'firebase',
      ['use', firebaseProjectId],
      workingDirectory: firebaseDir,
      runInShell: true,
    );
    final initHostingProcess = await Process.start(
      'firebase',
      ['init', 'hosting'],
      workingDirectory: firebaseDir,
      runInShell: true,
    );
    final initHostingInputStream = Stream.periodic(
      Duration(milliseconds: 100),
      (count) => utf8.encode('\n'),
    );
    initHostingProcess.stdin.addStream(initHostingInputStream);
    // Make sure hosting is initialized before deploying.
    await initHostingProcess.exitCode;

    final deployProcess = await Process.start(
      'firebase',
      ['deploy', '--project', firebaseProjectId],
      workingDirectory: firebaseDir,
      runInShell: true,
    );
    // There may be a need for the user to interactively provide inputs.
    deployProcess.stdout.transform(utf8.decoder).forEach(print);
    deployProcess.stdin.addStream(stdin);
    final exitCode = await deployProcess.exitCode;
    if (exitCode != 0) {
      stderr.write('Failed to deploy to Firebase.\n');
    }
  } finally {
    tmpFolder?.deleteSync(recursive: true);
  }
}
