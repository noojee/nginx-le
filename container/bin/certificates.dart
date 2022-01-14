import 'package:nginx_le_container/src/commands/internal/certificates.dart';

/// In container entry point to run certbot
///
/// The cli certificates command calls this command which does the
///  actual listing of certificates
/// within the container.

void main(List<String> args) {
  certificates(args);
}
