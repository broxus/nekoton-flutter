import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart';

Future<void> main(List<String> arguments) async {
  final androidNdkHome = arguments.firstOrNull;

  final currentDirname = dirname(Platform.script.path);
  final flutterProjectDirectory = normalize('$currentDirname/../');
  final rustProjectDirectory = normalize('$currentDirname/../rust');
  final jsProjectDirectory = normalize('$currentDirname/../js');

  Future<int> execute({
    required String executable,
    required List<String> arguments,
    Map<String, String>? environment,
    required String workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
      workingDirectory: workingDirectory,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  int exitCode;

  await execute(
    executable: 'make',
    arguments: ['init'],
    workingDirectory: rustProjectDirectory,
  );

  exitCode = await execute(
    executable: 'make',
    arguments: ['all'],
    environment: {
      'ANDROID_NDK_HOME': androidNdkHome ?? '',
    },
    workingDirectory: rustProjectDirectory,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }

  exitCode = await execute(
    executable: 'npm',
    arguments: ['install'],
    workingDirectory: jsProjectDirectory,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }

  exitCode = await execute(
    executable: 'npm',
    arguments: ['run', 'build'],
    workingDirectory: jsProjectDirectory,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }

  exitCode = await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'ffigen'],
    workingDirectory: flutterProjectDirectory,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }

  await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'build_runner', 'clean'],
    workingDirectory: flutterProjectDirectory,
  );

  exitCode = await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: flutterProjectDirectory,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }

  exit(0);
}
