import 'dart:io';

Future<void> cleanupFiles({bool autoDelete=false, String folderPath='lib'}) async {

  print("Running DCM Analyzer for path: $folderPath...\n");

  // Ensure dcm is installed
  ProcessResult checkDcm = await Process.run('dcm', ['--version'], runInShell: true);
  if (checkDcm.exitCode != 0) {
    print("Error: 'dcm' is not installed. Install it using:\n dart pub global activate dcm");
    exit(1);
  }

  // Run dcm check-unused-files
  ProcessResult result = await Process.run('dcm', ['check-unused-files', folderPath], runInShell: true);
  String output = result.stdout.trim();

  // Using the working regex to extract file paths
  RegExp unusedFilePattern = RegExp(r"⚠ unused file\s*\n\s*(.+)");
  List<String> unusedFiles = [];

  for (var match in unusedFilePattern.allMatches(output)) {
    unusedFiles.add(match.group(1)!.trim());
  }

  // Show unused files
  if (unusedFiles.isNotEmpty) {
    print("\nUnused Files Found in '$folderPath':");
    for (var file in unusedFiles) {
      print(" - $file");
    }

    // Auto-delete if flag is set
    if (autoDelete) {
      print("\nAuto-deleting unused files...\n");
      deleteFiles(unusedFiles);
    } else {
      // Ask user for confirmation before deletion
      print("\nDo you want to delete these files? (yes/no)");
      String? response = stdin.readLineSync();

      if (response?.toLowerCase() == 'yes') {
        deleteFiles(unusedFiles);
      } else {
        print("\nDeletion cancelled.");
      }
    }
  } else {
    print("\nNo unused files found in '$folderPath'.");
  }
}

/// Function to delete files and handle errors
void deleteFiles(List<String> files) {
  for (var file in files) {
    File f = File(file);
    if (f.existsSync()) {
      try {
        f.deleteSync();
        print("Deleted: $file");
      } catch (e) {
        print("Failed to delete: $file. Error: $e");
      }
    } else {
      print("File not found: $file");
    }
  }
  print("\nCleanup completed successfully.");
}