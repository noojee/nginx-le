import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';

import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class RevokeCommand extends Command<void> {
  RevokeCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form
    // --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information');
  }

  @override
  String get description =>
      'Revokes the active Lets Encrypt certificate and places the server '
      'into acquire mode.';

  @override
  String get name => 'revoke';

  @override
  void run() {
    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    //var target = containerOrName(argParser, argResults);

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    if (Containers().findByContainerId(config.containerid!)!.isRunning) {
      var cmd = 'docker exec -it ${config.containerid} /home/bin/revoke';
      if (debug) {
        cmd += ' --debug';
      }
      cmd.run;
    } else {
      printerr(
          red("The Nginx-LE container ${config.containerid} isn't running. "
              "Use 'nginx-le start' to start the container."));
    }
  }
}
