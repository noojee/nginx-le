@Timeout(Duration(minutes: 20))
import 'package:dcli/dcli.dart' hide equals;

import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import 'mock_cerbot_paths.dart';

void main() {
  test('acquisition manager ...', () async {
    setup();

    expect(AcquisitionManager.inAcquisitionMode, equals(false));

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(false));

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(false));
  });

  test('Renew certificate', () {
    setup();

    Certbot().clearBlockFlag();

    AcquisitionManager.acquistionCheck(reload: false);

    Certbot().renew(force: true);

//    'test/src/util/mock_deploy_hook'.run;
  });

  test('acquire certificate ...', () async {
    setup();

    Certbot().clearBlockFlag();

    if (Certbot().hasValidCertificate()) {
      Certbot().revoke(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          emailaddress: emailAddress);
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));

    /// tell the AcquisitionManager isolate that it needs to call the mock functions.
    // env['MOCK_ACQUISITION_MANAGER'] = 'true';

    AcquisitionManager.acquistionCheck(reload: false);

    expect(AcquisitionManager.inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedTo(
            hostname: hostname, domain: domain, wildcard: wildcard),
        equals(true));
  });

  test('isdeployed...', () {
    setup();
    var certificate =
        join(CertbotPaths().nginxCertPath, CertbotPaths().FULLCHAIN_FILE);
    var privatekey =
        join(CertbotPaths().nginxCertPath, CertbotPaths().PRIVATE_KEY_FILE);

    if (!exists(dirname(certificate))) {
      createDir(dirname(certificate), recursive: true);
    }
    if (!exists(dirname(privatekey))) {
      createDir(dirname(privatekey), recursive: true);
    }

    if (exists(certificate)) {
      delete(certificate);
    }

    expect(Certbot().isDeployed(), equals(false));

    if (exists(privatekey)) {
      delete(privatekey);
    }

    expect(Certbot().isDeployed(), equals(false));

    touch(privatekey, create: true);

    expect(Certbot().isDeployed(), equals(false));

    touch(certificate, create: true);

    expect(Certbot().isDeployed(), equals(true));

    delete(certificate);
    delete(privatekey);
  });
}

final hostname = 'auditor';
final domain = 'noojee.com.au';
final tld = 'com.au';
final wildcard = false;
final emailAddress = 'support@noojeeit.com.au';
final production = false;

void setup() {
  var paths = MockCertbotPaths();

  paths.wire();

  config_mock_deploy_hook();
}

void config_mock_deploy_hook() {
  var path = 'test/src/util/mock_deploy_hook';
  if (!exists(path)) {
    var script = Script.fromFile('$path.dart');
    script.compile();
  }

  Environment().certbotDeployHookPath = path;
}
