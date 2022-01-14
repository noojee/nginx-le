import 'package:dcli/dcli.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'environment.dart';

// ignore: avoid_classes_with_only_static_members
class Email {
  static void sendError({String? subject, String? body}) {
    if (Environment().smtpServer == null || Environment().smtpServer!.isEmpty) {
      printerr('Error not emailed as no ${Environment().smtpServerKey} '
          'environment variable set');
      print('Subject: $subject');
      print('Body: \n$body');
      return;
    }
    final smtpServer = SmtpServer(Environment().smtpServer!,
        port: Environment().smtpServerPort);

    // Use the SmtpServer class to configure an SMTP server:
    // final smtpServer = SmtpServer('smtp.domain.com');
    // See the named arguments of SmtpServer for further configuration
    // options.

    // Create our message.
    final message = Message()
      ..from = Environment().emailaddress
      ..recipients.add(Environment().emailaddress)
      ..subject = subject
      ..text = body
      ..html = '<p>$body</p>';

    try {
      final sendReport = waitForEx<SendReport>(send(message, smtpServer));
      print('Message sent: $sendReport');
    } on MailerException catch (e) {
      printerr('Message not sent.');
      for (final p in e.problems) {
        printerr('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
