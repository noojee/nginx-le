import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:nginx_le_container/src/util/renewal_manager.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../util/log_manager.dart';

/// The main service thread that runs within the docker container.
void startService() {
  print('Nginx-LE starting Version:$packageVersion');

  /// These environment variables are set when the container is
  /// created via nginx-le config or by docker-compose.
  ///
  /// NOTE: you can NOT change these by setting an environment var before you call nginx-le start
  /// They can only be changed by re-running nginx-le config and recreating the container.
  ///
  ///

  var startPaused = Environment().startPaused;

  if (startPaused) {
    print(orange(
        'Nginx-LE is paused. Run "nginx-le cli" to attached and explore the Nginx-LE container'));
    while (true) {
      sleep(10);
    }
  } else {
    try {
      _start();
    } catch (e, s) {
      print('Nginx-LE encounted an unexpected problem and is shutting down.');
      print('Exception: ${e.runtimeType} ${e.toString()}');
      print('Stacktrace: ${s.toString()}');
    } finally {
      print(orange('Nginx-le has shutdown'));
    }
  }
}

void _start() {
  var debug = Environment().debug;
  Settings().setVerbose(enabled: debug);

  dumpEnvironmentVariables();

  var hostname = Environment().hostname!;
  verbose(() => '${Environment().hostnameKey}=$hostname');
  var domain = Environment().domain!;
  verbose(() => '${Environment().domainKey}=$domain');
  var tld = Environment().tld;
  verbose(() => '${Environment().tldKey}=$tld');

  var wildcard = Environment().domainWildcard;
  verbose(() => '${Environment().domainWildcardKey}=$wildcard');

  var emailaddress = Environment().emailaddress;
  verbose(() => '${Environment().emailaddressKey}=$emailaddress');

  var production = Environment().production;
  verbose(() => '${Environment().productionKey}=$production');

  var autoAcquire = Environment().autoAcquire;
  verbose(() => '${Environment().autoAcquireKey}=$autoAcquire');

  var certbotAuthProvider = Environment().authProvider;
  verbose(() => '${Environment().authProviderKey}=$certbotAuthProvider');

  _clearLocks();

  LogManager().start();

  /// In case the host, domain or wildard settings have changed.
  /// Also cleans up an old expired certificates

  /// We originally revoked certificates but decided it was safer
  /// to just delete them in case a bug causes us to revoke
  /// a live certificate. By deleting the certs we can recover
  /// them from backup.
  Certbot().deleteInvalidCertificates(
      hostname: hostname,
      domain: domain,
      wildcard: wildcard,
      production: production);

  RenewalManager().start();

  AcquisitionManager().start();

  print('Starting nginx daemon.');

  try {
    /// run nginx in the foreground.
    /// As such this call won't return until nginx shutsdown.
    "nginx -g 'daemon off;'".start();
  } finally {
    print('Nginx has shutdown');
  }
}

/// under docker after a crash NamedLock mis-behaves as docker uses the
/// same pid no. (1) each time we start so NamedLocks thinks the lock is still
/// held.
void _clearLocks() {
  var lockPath = join(rootPath, Directory.systemTemp.path, 'dcli', 'locks');

  if (exists(lockPath)) {
    deleteDir(lockPath);
  }
}

void dumpEnvironmentVariables() {
  printEnv(Environment().debugKey, Environment().debug.toString());
  printEnv(Environment().hostnameKey, Environment().hostname);
  printEnv(Environment().domainKey, Environment().domain);
  printEnv(Environment().tldKey, Environment().tld);
  printEnv(Environment().emailaddressKey, Environment().emailaddress);
  printEnv(Environment().productionKey, Environment().production.toString());
  printEnv(
      Environment().domainWildcardKey, Environment().domainWildcard.toString());
  printEnv(Environment().autoAcquireKey, Environment().autoAcquire.toString());
  printEnv(Environment().smtpServerKey, Environment().smtpServer);
  printEnv(
      Environment().smtpServerPortKey, Environment().smtpServerPort.toString());
  printEnv(Environment().startPausedKey, Environment().startPaused.toString());
  printEnv(Environment().authProviderKey, Environment().authProvider);
  printEnv(Environment().certbotIgnoreBlockKey,
      Environment().certbotIgnoreBlock.toString());

  if (Environment().authProvider == null) {
    printerr(red(
        'No Auth Provider has been set. Check ${Environment().authProviderKey} as been set'));
    exit(1);
  }

  var authProvider = AuthProviders().getByName(Environment().authProvider!);
  if (authProvider == null) {
    printerr(red(
        'No Auth Provider has been set. Check ${Environment().authProviderKey} as been set'));
    exit(1);
  }
  authProvider.dumpEnvironmentVariables();

  print('Internal environment variables');
  printEnv(Environment().certbotRootPathKey, Environment().certbotRootPath);
  printEnv(Environment().logfileKey, Environment().logfile);
  printEnv(Environment().nginxCertRootPathOverwriteKey,
      Environment().nginxCertRootPathOverwrite);
}

void printEnv(String key, String? value) {
  print('ENV: $key=$value');
}
