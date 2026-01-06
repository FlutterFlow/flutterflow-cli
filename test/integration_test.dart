import '../bin/flutterflow_cli.dart';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

String kProjectId = 'app-with-assets-and-custom-fonts-qxwg6o';
String kToken = Platform.environment['FF_TESTER_TOKEN'] ?? 'not-set';

Future<bool> buildProject(String project) async {
  var result = await Process.run('flutter', ['build', 'web'],
      workingDirectory: p.normalize(project), runInShell: true);

  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
  }

  return result.exitCode == 0;
}

bool checkAssets(String project) {
  var assets = [
    'assets/fonts/JetBrainsMonoNerdFont-Bold.ttf',
    'assets/fonts/JetBrainsMonoNerdFont-Italic.ttf',
    'assets/fonts/JetBrainsMonoNerdFont-Regular.ttf',
    'assets/fonts/MartianMonoNerdFont-Bold.ttf',
    'assets/fonts/MartianMonoNerdFont-Medium.ttf',
    'assets/fonts/MartianMonoNerdFont-Regular.ttf',
    'assets/fonts/ProFontIIxNerdFont-Regular.ttf',
    'assets/fonts/ProFontIIxNerdFontMono-Regular.ttf',
    'assets/fonts/ProFontIIxNerdFontPropo-Regular.ttf',
    'assets/images/6740ae761553efad6aa2a5d4.png',
    'assets/images/6740ae76c0adf77347645294.png',
    'assets/images/6740af8ffbd4c3414fcf5728.png',
    'assets/images/6740aff03c7e45b220ed9775.png',
    'assets/images/6740aff0d10e0295e5fe33e6.png',
    'assets/images/6740b3cc6d3624484183520b.png',
    'assets/images/6740b3cca8e014dee9325b5d.png',
    'assets/images/6740b4b494d7239248fa491e.png',
    'assets/images/6740b4b5c0adf773476a5452.png',
    'assets/images/6740b4b5cf7b4fdf95795e2c.png',
    'assets/images/6740bca9c28f22a68495d368.png',
    'assets/images/6740bca9ed26c9a34b1ab1ce.png',
    'assets/images/6744ab4d50d5a3dad758fa39.png',
    'assets/images/6785366c215b774f00c041a3.png',
    'assets/images/6785366c3e83b0072fdc8ef4.png',
    'assets/images/6785366c77c17f02779e160c.png',
    'assets/images/67895d616be6f220ee4ec9c3.png',
    'assets/images/67895d6177fc072b5e166fd1.png',
    'assets/images/67895d61a7af8d11cb9aa957.png',
  ];

  for (var asset in assets) {
    if (fileExists('$project/$asset') == false) {
      return false;
    }
  }

  return true;
}

bool fileExists(path) {
  return File(p.normalize(path)).existsSync();
}

bool fileContains(path, data) {
  return File(p.normalize(path)).readAsStringSync().contains(data);
}

void main() {
  group('export-code', () {
    test('default parameters', () async {
      final project = 'export/app_with_assets_and_custom_fonts';

      await appMain([
        'export-code',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        'export',
      ]);

      // Missing assets
      expect(checkAssets(project), false);

      final buildResult = await buildProject(project);
      expect(buildResult, false);
    });

    test('fix code', () async {
      final project = 'export/fix_code';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--fix',
      ]);

      // Fix will add 'const' to a lot of stuff :-)
      expect(
          fileContains(
              '$project/lib/main.dart', 'localizationsDelegates: const ['),
          true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });

    test('branch', () async {
      final project = 'export/branch';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--branch-name',
        'TestBranch',
      ]);

      expect(
          fileExists(
              '$project/lib/pages/page_only_on_this_branch/page_only_on_this_branch_widget.dart'),
          true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });

    test('commit', () async {
      final project = 'export/commit';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--commit-hash',
        '0jfsCktnCmIcNp02q3yW',
      ]);

      expect(
          fileExists(
              '$project/lib/pages/page_only_on_this_commit/page_only_on_this_commit_widget.dart'),
          true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });

    test('debug', () async {
      final project = 'export/debug';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--as-debug',
      ]);

      // Debug instrumentation added by the flag
      expect(fileContains('$project/lib/main.dart', 'debugLogGlobalProperty'),
          true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });

    test('module', () async {
      final project = 'export/module';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--as-module',
      ]);

      expect(fileContains('$project/pubspec.yaml', 'module:'), true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });

    test('environment', () async {
      final project = 'export/environment';

      await appMain([
        'export-code',
        '--no-parent-folder',
        '--include-assets',
        '--project',
        kProjectId,
        '--token',
        kToken,
        '-d',
        p.normalize(project),
        '--project-environment',
        'Development',
      ]);

      expect(
          fileContains('$project/assets/environment_values/environment.json',
              '"foobar": "barfoo"'),
          true);

      expect(checkAssets(project), true);

      final buildResult = await buildProject(project);
      expect(buildResult, true);
    });
  }, timeout: Timeout(Duration(minutes: 30)));
}
