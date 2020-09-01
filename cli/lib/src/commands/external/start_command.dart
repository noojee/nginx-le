import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class StartCommand extends Command<void> {
  @override
  String get description => 'starts the ngix server';

  @override
  String get name => 'start';

  StartCommand() {
    argParser.addFlag('debug',
        defaultsTo: false, abbr: 'd', negatable: false, help: 'Outputs additional logging information');

    argParser.addFlag('interactive',
        defaultsTo: false,
        abbr: 'i',
        negatable: false,
        help: 'Starts the container in the foreground so you can see all output');
  }

  @override
  void run() {
    var debug = argResults['debug'] as bool;
    Settings().setVerbose(enabled: debug);

      var interactive = argResults['interactive'] as bool;

    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    var container = Containers().findByContainerId(config.containerid);
    if (container.isRunning) {
      printerr('The container ${config.containerid} is already running. Consider nginx-le restart');
      showUsage(argParser);
    }

    print('Starting nginx container ${config.containerid}');

    container.start(interactive: interactive);

    sleep(3);

    if (!container.isRunning) {
      printerr(red('The container ${config.containerid} failed to start'));
      print(green('Showing docker logs'));
      container.showLogs();
    }
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }

  String checkRequired(String value, String defaultValue, String error) {
    if (value == null) {
      if (defaultValue == null) {
        print(error);
        showUsage(argParser);
      } else {
        value = defaultValue;
      }
    }
    return value;
  }
}
