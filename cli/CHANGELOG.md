# 8.3.5

# 8.3.2
- Added default_server directive to default_conf so a server isn't selected at random.
- change the docker hub repository to onepub.
- added copy right notices.

# 8.2.6

# 8.2.2

# 8.2.0
Added support for hostless fqdn.

# 8.1.1
- second attempt at 8.1 release
# 8.1.0
- improved the acquisition blocked message.
- add support for a domain certificate e.g. onepub.doc rather than www.onepub.doc
  set the HOSTNAME environment var to blank and DOMAIN to the domain name (e.g. onepub.doc)

# 8.0.7

# 8.0.6

# 8.0.4
Fixed dependancy issue cause by release process.
# 8.0.1
migrated to lint hard 

# 8.0.0
- Upgraded packages as part of release process

# 7.1.4
- Upgraded packages as part of release process

# 7.1.3
- Upgraded packages as part of release process

# 7.1.1
Upgraded packages as part of release process

# 7.0.2
Improved documentation.

# 7.0.1
upgraded to dcli 1.7.1 and docker2.

# 6.3.2
Fixed missing reload of nginx after certificate renewal.


# 6.3.0
## Fixes
- Fixed a dead lock issue with the log group future.
- Fixed a bug where after a renewal we were not reloading nginx.

## Improvements
- upgraded dcli version.
- removed the deprecated flag --manual-public-ip-logging-ok  which is now treated as a noop.
- Added critical_test pre_hook to install the needed cerbot hooks.
- replaced Settings().verbose with verbose(() to improve logging performance.

# 6.2.5

# 6.2.2
Upgraded packages as part of release process

# 6.2.1
Upgraded packages as part of release process

# 6.2.0
Upgraded packages as part of release process

# 5.0.69
Upgraded packages as part of release process

# 5.0.68
Upgraded packages as part of release process

# 5.0.67
Upgraded packages as part of release process

# 5.0.66
Upgraded packages as part of release process

# 5.0.64
Upgraded packages as part of release process

# 5.0.63
Upgraded packages as part of release process

# 5.0.62
Upgraded packages as part of release process

# 5.0.60
Upgraded packages as part of release process

# 5.0.58
Upgraded packages as part of release process

# 5.0.56
Upgraded packages as part of release process

# 5.0.55
Upgraded packages as part of release process

# 5.0.54
Upgraded packages as part of release process

# 5.0.53
Upgraded packages as part of release process

# 5.0.52
Upgraded packages as part of release process

# 5.0.51

# 5.0.50

# 5.0.49

# 5.0.48

# 5.0.47
Upgraded packages as part of release process

# 5.0.46
Upgraded packages as part of release process

# 5.0.45

# 5.0.44
Upgraded packages as part of release process

# 5.0.42
Upgraded packages as part of release process

# 5.0.37

# 5.0.34
Upgraded packages as part of release process

# 5.0.33
Upgraded packages as part of release process

# 5.0.32

# 5.0.31

# 5.0.30
Upgraded packages as part of release process

# 5.0.22

# 5.0.21

# 5.0.21
Reduced noisy loggers.
When revoking a certificate the path must point to the pem file not a directory.
Reduced logging when looking for expired certificates.
Improved formatting when outputing a certbot error.

# 5.0.20

# 5.0.16

# 5.0.15

# 5.0.12

# 5.0.11
Added message when nginx shutsdown cleanly.

# 5.0.10
Improved the acquistion managers blocked message.
Fixed a stack overflow.
added member to Certbot blockedUntil which reports the time until which acquistions are blocked.

# 5.0.9
Stopped the acquistion manager trying to reload nginx before it has started.
Added logic to stop the system trying to send an email when no smtp server has been set.
change certificate load logging from print to verbose.
Added documenation to service.dart

# 5.0.8

# 5.0.7

# 5.0.6

# 5.0.5

# 5.0.3
simplified/fixed the symlink logic
added release hooks to automatically toggle between public and local dependency for shared.

# 5.0.2

# 5.0.1

# 5.0.0

# 4.0.15

# 4.0.14

# 4.0.13
# 4.0.12
# 4.0.11
# 4.0.10
# 4.0.9
# 4.0.8
# 4.0.7
# 4.0.6
# 4.0.5
# 4.0.4
# 4.0.3
# 4.0.2
# 4.0.1
Fixed the renewal logic as it was failing to deploy the renewed certificates
# 3.0.2
# 3.0.1
# 2.7.10
# 2.7.9
# 2.7.8
# 2.7.7
# 2.7.6
# 2.7.4
# 2.7.3
# 2.7.2
# 2.7.1
# 2.7.0
# 2.6.1
# 2.6.0
# 2.5.4
# 2.5.2
# 2.5.0
# 2.4.5
# 2.4.4
# 2.4.3
# 2.4.2
# 2.4.0
Upgraded to dcli 0.27.1
# 2.3.5
# 2.3.4
# 2.3.3
# 2.3.2
# 2.3.1
# 2.3.0
# 2.1.2
First working release
# 2.1.1
# 2.0.3
# 2.0.2
# 2.0.1
# 1.4.16
# 1.4.15
# 1.4.14
# 1.4.13
# 1.4.12
# 1.4.11
Fixed wild card cert paths.
# 1.4.10
# 1.4.9
# 1.4.8
# 1.4.7
# 1.4.6
# 1.4.4
# 1.4.3
# 1.4.2
# 1.4.1
Updated doco on environment variables.
Rationalised some of the environment variable names.
# 1.4.0
# 1.3.1
# 1.3.0
# 1.2.0
# 1.1.4
# 1.1.3
# 1.1.2
# 1.1.1
# 1.1.0
# 1.0.10
Added missing consts for namecheap
# 1.0.9
Completed work on centralising all environment var access.
# 1.0.7
fixed bug in auto acquire in shared lib.
# 1.0.5
Updated to support a number of content providers including tomcat.
# 1.0.3
Upgraded to dcli 1.11.0 and fixed breaking changes.
# 1.0.2
Upgraded to dcli 1.11.0 and fixed breaking changes.
# 1.0.1
Fixed: default certificate type was ignoring the currently selected certificate type.
# 1.0.0
First release
# 0.5.6
# 0.5.6
# 0.5.5
fixed include paths.
# 0.5.4
synchronized released with shared.
# 0.5.3
# 0.5.2
added a 'cli' method to the container.
# 0.5.1
Now asks for image even when in docker-compose mode.
# 0.5.0
# 0.4.5
# 0.4.4
# 0.4.3
# 0.4.2
# 0.4.1
# 0.4.0
# 0.3.16
# 0.3.15
# 0.3.14
# 0.3.13
fixed bug in Container splittFullName
# 0.3.12
# 0.3.11
Added better prompts for config.
# 0.3.10
color coded prompts
# 0.3.9
# 0.3.8
# 0.3.7
# 0.3.6
# 0.3.5
# 0.3.4
# 0.3.3
# 0.3.2
# 0.3.1
# 0.3.0
# 0.2.0
First mostly working release
# 0.1.1
Added executables statement to pubspec.yaml
# 0.1.0
Initial release

