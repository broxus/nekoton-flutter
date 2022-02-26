import 'dart:io';

import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  final androidNdkHome = args.firstOrNull;

  final flutterProjectDirectory = Directory.current.absolute.path;
  final rustProjectDirectory = '$flutterProjectDirectory/rust';
  final jsProjectDirectory = '$flutterProjectDirectory/js';

  Future<void> execute({
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

    final exitCode = await process.exitCode;

    if (exitCode != 0) exit(exitCode);
  }

  await execute(
    executable: 'make',
    arguments: ['init'],
    workingDirectory: rustProjectDirectory,
  );

  await execute(
    executable: 'make',
    arguments: ['all'],
    environment: {
      'ANDROID_NDK_HOME': androidNdkHome ?? '',
    },
    workingDirectory: rustProjectDirectory,
  );

  await execute(
    executable: 'npm',
    arguments: ['install'],
    workingDirectory: jsProjectDirectory,
  );

  await execute(
    executable: 'npm',
    arguments: ['run', 'build'],
    workingDirectory: jsProjectDirectory,
  );

  await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'build_runner', 'clean'],
    workingDirectory: flutterProjectDirectory,
  );

  await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: flutterProjectDirectory,
  );

  await execute(
    executable: 'flutter',
    arguments: ['pub', 'run', 'ffigen'],
    workingDirectory: flutterProjectDirectory,
  );
}
