import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le/src/content_providers/content_provider.dart';
import 'package:nginx_le/src/content_providers/content_providers.dart';
import 'package:nginx_le/src/util/ask_fqdn_validator.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class ConfigCommand extends Command<void> {
  @override
  String get description => 'Allows you to configure your Nginx-LE server';

  @override
  String get name => 'config';

  ConfigCommand() {
    /// argParser.addOption('template')
    argParser.addFlag('debug',
        defaultsTo: false,
        negatable: false,
        abbr: 'd',
        help:
            'Outputs additional logging information and puts the container into debug mode');
  }

  @override
  void run() {
    print('Nginx-LE config Version:$packageVersion');
    var debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();

    selectFQDN(config);
    selectTLD(config);
    selectMode(config);
    selectCertType(config);
    selectAuthProvider(config);
    selectContentProvider(config);
    selectStartMode(config);

    selectEmail(config);
    selectStartMethod(config);

    var containerName = 'nginx-le';

    var image = selectImage(config);

    config.save();
    print('Configuration saved.');

    var provider = ContentProviders().getByName(config.contentProvider)!;

    provider.createLocationFile();
    provider.createUpstreamFile();

    if (config.startMethod != ConfigYaml.startMethodDockerCompose) {
      deleteOldContainers(containerName, image);
      createContainer(image!, config, debug);
    } else {
      selectContainer(config);
    }

    /// save the new container id.
    config.save();
  }

  void deleteOldContainers(String containerName, Image? image) {
    var existing = Containers().findByName(containerName);

    if (existing != null) {
      print(orange('A container with the name $containerName already exists.'));
      if (!confirm(
          'Do you want to delete the older container and create one with the new settings?')) {
        print(orange('Container does not reflect your new settings!'));
        exit(-1);
      } else {
        if (existing.isRunning) {
          print(
              'The old container is running. To delete the container it must be stopped.');
          if (confirm(
              'Do you want the container ${existing.containerid} stopped?')) {
            existing.stop();
          } else {
            printerr(red(
                'Unable to delete container ${existing.containerid} as it is running'));
            printerr(
                'Delete all containers for ${image!.imageid} and try again.');
            exit(1);
          }
        }
        existing.delete();
      }
    }
  }

  void createContainer(Image image, ConfigYaml config, bool debug) {
    print('Creating container from Image ${image.fullname}.');

    var lines = <String>[];
    var progress =
        Progress((line) => lines.add(line), stderr: (line) => lines.add(line));

    var volumes = '';
    var provider = ContentProviders().getByName(config.contentProvider)!;
    for (var volume in provider.getVolumes()) {
      volumes += ' -v ${volume.hostPath}:${volume.containerPath}';
    }

    var authProvider = AuthProviders().getByName(config.authProvider!)!;
    var environments = authProvider.environment;

    var dnsProviderEnvs = '';

    for (var env in environments) {
      dnsProviderEnvs += ' --env=${env.name}=${env.value}';
    }

    var cmd = 'docker create'
        ' --name="nginx-le"'
        ' --env=${Environment().hostnameKey}=${config.hostname}'
        ' --env=${Environment().domainKey}=${config.domain}'
        ' --env=${Environment().tldKey}=${config.tld}'
        ' --env=${Environment().productionKey}=${config.isProduction.toString()}'
        ' --env=${Environment().startPausedKey}=${config.startPaused}'
        ' --env=${Environment().authProviderKey}=${config.authProvider}'
        ' --env=${Environment().emailaddressKey}=${config.emailaddress}'
        ' --env=${Environment().smtpServerKey}=${config.smtpServer}'
        ' --env=${Environment().smtpServerPortKey}=${config.smtpServerPort}'
        ' --env=${Environment().debugKey}=$debug'
        ' --env=${Environment().domainWildcardKey}=${config.domainWildcard}'
        ' --env=${Environment().autoAcquireKey}=true' // be default try to auto acquire a certificate.
        '$dnsProviderEnvs'
        ' --net=host'
        ' --log-driver=journald'
        ' -v certificates:${CertbotPaths().letsEncryptRootPath}'
        '$volumes'
        ' ${config.image!.imageid}';

    cmd.start(nothrow: true, progress: progress);

    if (progress.exitCode != 0) {
      printerr(red('docker create failed with exitCode ${progress.exitCode}'));
      lines.forEach(printerr);
      exit(1);
    } else {
      // only the first 12 characters are actually used to start/stop containers.
      var containerid = lines[0].substring(0, 12);

      if (Containers().findByContainerId(containerid) == null) {
        printerr(red('Docker failed to create the container!'));
        exit(1);
      } else {
        print(green('Container created.'));
        config.containerid = containerid;
      }
    }
    print('');

    var startMethod = ConfigYaml().startMethod;
    if (startMethod == ConfigYaml.startMethodNginxLe) {
      if (confirm('Would you like to start the container:',
          defaultValue: true)) {
        'docker start nginx-le'.run;
      } else {
        print(blue('Use ${orange('nginx-le start')} to start the container.'));
      }
    } else if (startMethod == ConfigYaml.startMethodDockerStart) {
      print(blue('Use your Dockerfile to start nginx-le.'));
    } else {
      // ConfigYaml.START_METHOD_DOCKER_COMPOSE
      print(blue('Use your docker-compose file to start nginx-le.'));
    }
  }

  void selectAuthProvider(ConfigYaml config) {
    var authProviders = AuthProviders().getValidProviders(config);

    var defaultProvider = AuthProviders().getByName(config.authProvider!);
    print('');
    print(green('Select the Auth Provider'));
    var provider = menu<AuthProvider>(
        prompt: 'Content Provider:',
        options: authProviders,
        defaultOption: defaultProvider,
        format: (provider) => provider.summary);

    config.authProvider = provider.name;

    provider.promptForSettings(config);
  }

  void selectCertType(ConfigYaml config) {
    print(green('Only select wildcard if the system has multiple fqdns.'));

    const wildcard = 'Wildcard';
    var domainType = menu(
        prompt: 'Certificate Type',
        options: ['FQDN', wildcard],
        defaultOption: config.domainWildcard ? wildcard : 'FQDN');

    config.domainWildcard = (domainType == wildcard);

    print('');
    print(green('During testing please select "staging"'));
    var certTypes = [
      ConfigYaml.certificateTypeProduction,
      ConfigYaml.certificateTypeStaging
    ];
    config.certificateType ??= ConfigYaml.certificateTypeStaging;
    var certificateType = menu(
        prompt: 'Certificate Type:',
        options: certTypes,
        defaultOption: config.certificateType);
    config.certificateType = certificateType;
  }

  void selectEmail(ConfigYaml config) {
    print('');
    print(green('Errors are notified via email'));
    var emailaddress = ask('Email Address:',
        defaultValue: config.emailaddress,
        validator: Ask.all([Ask.required, Ask.email]));
    config.emailaddress = emailaddress;

    var smtpServer = ask('SMTP Server:',
        defaultValue: config.smtpServer,
        validator: Ask.all([Ask.required, AskFQDNOrLocalhost()]));
    config.smtpServer = smtpServer;

    var smtpServerPort = ask('SMTP Server port:',
        defaultValue: '${config.smtpServerPort}',
        validator:
            Ask.all([Ask.required, Ask.integer, Ask.valueRange(1, 65535)]));
    config.smtpServerPort = int.tryParse(smtpServerPort) ?? 25;
  }

  void selectTLD(ConfigYaml config) {
    print('');
    print(green('The servers top level domain (e.g. com.au)'));

    var tld = ask('TLD:', defaultValue: config.tld, validator: Ask.required);
    config.tld = tld;
  }

  void selectFQDN(ConfigYaml config) {
    print('');
    print(green("The server's FQDN (e.g. www.microsoft.com)"));
    var fqdn = ask('FQDN:',
        defaultValue: config.fqdn, validator: AskFQDNOrLocalhost());
    config.fqdn = fqdn;
  }

  Image? selectImage(ConfigYaml config) {
    print('');
    print(green('Select the image to utilise.'));
    var latest = 'noojee/nginx-le:latest';
    var images = Images()
        .images
        .where(
            (image) => image.repository == 'noojee' && image.name == 'nginx-le')
        .toList();
    var latestImage = Images().findByName(latest);
    Image downloadLatest;
    if (latestImage != null) {
      downloadLatest = Image.fromName(latest);
    } else {
      downloadLatest = Image(
          repositoryAndName: '',
          tag: '',
          imageid: 'Download'.padRight(12),
          created: '',
          size: '');
      images.insert(0, downloadLatest);
    }
    Image? image = menu<Image>(
        prompt: 'Image:',
        options: images,
        format: (image) =>
            '${image.imageid} - ${image.repository}/${image.name}:${image.tag}',
        defaultOption: config.image);
    config.image = image;

    if (image == downloadLatest) {
      print(orange('Downloading the latest image'));
      Images().pull(fullname: image.fullname);

      /// after pulling the image additional information will be available
      /// so replace the image with the fully detailed version.
      image = Images().findByName(latest);
    }
    return image;
  }

  void selectMode(ConfigYaml config) {
    print('');
    print(green('Select the visibility of your Web Server'));
    config.mode ??= ConfigYaml.modePrivate;
    var options = [ConfigYaml.modePublic, ConfigYaml.modePrivate];
    var mode = menu(
      prompt: 'Mode:',
      options: options,
      defaultOption: config.mode,
    );
    config.mode = mode;
  }

  void selectStartMode(ConfigYaml config) {
    print('');
    config.startPaused ??= false;

    config.startPaused = confirm(
        green('Start the container in Paused mode to diagnose problems'),
        defaultValue: config.startPaused);
  }

  void selectStartMethod(ConfigYaml config) {
    config.startMethod ?? ConfigYaml.startMethodNginxLe;
    var startMethods = [
      ConfigYaml.startMethodNginxLe,
      ConfigYaml.startMethodDockerStart,
      ConfigYaml.startMethodDockerCompose
    ];

    print('');
    print(green('Select the method you will use to start Nginx-LE'));
    var startMethod = menu(
      prompt: 'Start Method:',
      options: startMethods,
      defaultOption: config.startMethod,
    );
    config.startMethod = startMethod;
  }

  /// Ask users where the website content is located.
  void selectContentProvider(ConfigYaml config) {
    var contentProviders = ContentProviders().providers;

    var defaultProvider = ContentProviders().getByName(config.contentProvider);
    print('');
    print(green('Select the Content Provider'));
    var provider = menu<ContentProvider>(
        prompt: 'Content Provider:',
        options: contentProviders,
        defaultOption: defaultProvider,
        format: (provider) =>
            '${provider.name.padRight(12)} - ${provider.summary}');

    config.contentProvider = provider.name;

    provider.promptForSettings();
  }

  void selectContainer(ConfigYaml config) {
    /// try for the default container name.
    var containers = Containers()
        .containers()
        .where((container) => container.name == 'nginx-le')
        .toList();

    if (containers.isEmpty) {
      containers = Containers().containers();
    }

    var defaultOption = Containers().findByContainerId(config.containerid!);

    if (containers.isEmpty) {
      if (config.startMethod == ConfigYaml.startMethodDockerCompose) {
        printerr(
            red('Please run docker-compose up before running nginx-le config'));
        exit(-1);
      } else {
        printerr(red(
            "ERROR: something went wrong as we couldn't find the nginx-le docker container"));
        exit(-1);
      }
    } else if (containers.length == 1) {
      config.containerid = containers[0].containerid;
    } else {
      print(green('Select the docker container running nginx-le'));
      var container = menu<Container>(
          prompt: 'Select Container:',
          options: containers,
          defaultOption: defaultOption,
          format: (container) =>
              '${container.name.padRight(30)} ${container.image?.fullname}');
      config.containerid = container.containerid;
    }
  }
}

void showUsage(ArgParser parser) {
  print(parser.usage);
  exit(-1);
}
