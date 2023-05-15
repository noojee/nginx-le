#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

void main() {
  final project = DartProject.fromPath('.');

  final projectRoot = project.pathToProjectRoot;

  final certBotHookPath = join(projectRoot, 'bin', 'certbot_hooks');

  'dmailhog'.start();

  DartScript.fromFile(join(certBotHookPath, 'auth_hook.dart'))
      .compile(install: true, overwrite: true);
  DartScript.fromFile(join(certBotHookPath, 'cleanup_hook.dart'))
      .compile(install: true, overwrite: true);
  DartScript.fromFile(join(certBotHookPath, 'deploy_hook.dart'))
      .compile(install: true, overwrite: true);
}
