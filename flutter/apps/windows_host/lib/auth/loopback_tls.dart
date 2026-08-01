import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves PEM material for the OAuth HTTPS loopback server.
///
/// Certs are local-dev only (self-signed for 127.0.0.1 / localhost). Browsers
/// will show a trust warning the first time unless the cert is installed.
class LoopbackTlsMaterial {
  const LoopbackTlsMaterial({
    required this.certificateChainPath,
    required this.privateKeyPath,
  });

  final String certificateChainPath;
  final String privateKeyPath;

  SecurityContext toSecurityContext() {
    final ctx = SecurityContext();
    ctx.useCertificateChain(certificateChainPath);
    ctx.usePrivateKey(privateKeyPath);
    return ctx;
  }
}

/// Locates `certs/loopback-cert.pem` + `loopback-key.pem` under the host package.
LoopbackTlsMaterial? resolveLoopbackTlsMaterial() {
  final candidates = <String>[
    p.join(Directory.current.path, 'certs'),
    p.join(Directory.current.path, 'apps', 'windows_host', 'certs'),
  ];
  try {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    // Debug: .../build/windows/x64/runner/Debug → package root
    candidates.add(p.normalize(p.join(exeDir, '..', '..', '..', '..', '..', 'certs')));
    candidates.add(p.join(exeDir, 'certs'));
  } catch (_) {}

  for (final dir in candidates) {
    final cert = File(p.join(dir, 'loopback-cert.pem'));
    final key = File(p.join(dir, 'loopback-key.pem'));
    if (cert.existsSync() && key.existsSync()) {
      // ignore: avoid_print
      print('loopback_tls: using certs in $dir');
      return LoopbackTlsMaterial(
        certificateChainPath: cert.path,
        privateKeyPath: key.path,
      );
    }
  }
  // ignore: avoid_print
  print('loopback_tls: certs not found (searched ${candidates.length} dirs)');
  return null;
}
