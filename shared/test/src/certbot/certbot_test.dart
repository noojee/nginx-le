#! /usr/bin/env dcli

@Timeout(Duration(minutes: 30))
import 'dart:io';
import 'package:dcli/dcli.dart' hide equals;

import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_auth_provider.dart';
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  group('certbot', () {
    setUpAll(() {
      if (which('auth_hook').notfound) {
        printerr(
            red('Compile and install auth_hook, cleanup_hook and deploy_hook '
                'before running this test'));
        exit(1);
      }
      print('setupall called');
      Environment().hostname = 'slayer';

      Environment().domain = 'noojee.org';
      Environment().tld = 'org';
      Environment().emailaddress = 'bsutton@noojee.com.au';
      Environment().production = false;
      // Environment().certbotDNSAuthHookPath = '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/dns_auth.dart';
      // Environment().certbotDNSCleanupHookPath =
      //     '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/dns_cleanup.dart';
    });

    test('acquire', () {
      prepareCertHooks();

      final authProvider =
          AuthProviders().getByName(NameCheapAuthProvider().name)!;
      print('acquire me');

      print('env ${env['CERTBOT_DNS_AUTH_HOOK_PATH']}');
      print('env ${env['CERTBOT_DNS_CLEANUP_HOOK_PATH']}');

      // // var apiKey = ask('Namecheap api key');
      // // var username = ask('Namecheap api username');
      // // pass the security details down to the createDNSChallenge.dart process
      // authProvider.envUsername = username;
      // authProvider.envToken = apiKey;

      final config = ConfigYaml();
      authProvider
        ..promptForSettings(config)
        ..envToken = authProvider.configToken
        ..envUsername = authProvider.configUsername
        ..acquire();

      var cert = Certificate.find(
        hostname: 'slayer',
        domain: 'noojee.org',
        production: false,
        wildcard: false,
      )!;
      expect(cert, equals(isNotNull));
      cert.revoke();

      authProvider.acquire();

      cert = Certificate.find(
        hostname: 'slayer',
        domain: 'noojee.org',
        production: false,
        wildcard: false,
      )!;
      expect(cert, equals(isNotNull));
      cert.revoke();
    }, timeout: const Timeout(Duration(minutes: 5)), skip: true);

    test(
        'renew - this can take > 10 min as certbot intentionally slows '
        'this call down.', () {
      prepareCertHooks();

      final certificates = Certificate.load();

      for (final cert in certificates) {
        print(cert.toString());
      }

      final authProvider =
          AuthProviders().getByName(NameCheapAuthProvider().name)!;

      print('renew');
      authProvider
        ..promptForSettings(ConfigYaml())
        ..envToken = authProvider.configToken
        ..envUsername = authProvider.configUsername;

      print(orange('calling acquire'));
      authProvider.acquire();

      print(orange('calling revoke'));
      Certificate.find(
              hostname: 'slayer',
              domain: 'noojee.org',
              production: false,
              wildcard: false)!
          .revoke();

      print(orange('calling acquire'));
      authProvider.acquire();

      print(orange('calling renew'));
      Certbot().renew();

      // print(orange('calling revoke'));
      // Certbot().revoke(
      //     hostname: 'slayer',
      //     domain: 'noojee.org',
      //     production: false,
      //     wildcard: false,
      //     emailaddress: Environment().emailaddress);
    }, timeout: const Timeout(Duration(minutes: 15)), tags: ['slow']);

    test('parse', () {
      print('parse');

      withTempDir((path) {
        Environment().certbotRootPath = path;
        createDir(
            join(CertbotPaths().letsEncryptLivePath,
                'robtest18-new.clouddialer.com.au'),
            recursive: true);
        final fqnd001 = join(CertbotPaths().letsEncryptLivePath,
            'robtest18-new.clouddialer.com.au-0001');
        createDir(fqnd001, recursive: true);

        // noojee.org-0001
        // noojee.org-new
        // noojee.org-new-0001
        final latest = CertbotPaths().latestCertificatePath(
            'robtest18-new', 'clouddialer.com.au',
            wildcard: false);
        expect(latest, equals(fqnd001));

        // createDir(join(path, 'robtest18.clouddialer.com.au'));
      });
    });

    test('block flag', () {
      print('');
      //var flag = '/tmp/test.flag';
      //var flag = join(HOME, '.dcli');
      Environment().certbotRootPath = '/tmp';
      const flag = '/tmp/block_acquisitions.flag';

      touch(flag, create: true);
      final flagStat = stat(flag);
      print(flagStat.changed);
      print(flagStat.changed.add(const Duration(minutes: 15)));
      print(flagStat.changed
          .add(const Duration(minutes: 15))
          .isAfter(DateTime.now()));

      print('isblocked ${Certbot().isBlocked}');
    });
  });
}
