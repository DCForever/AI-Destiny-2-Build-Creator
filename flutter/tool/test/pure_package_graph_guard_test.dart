import 'dart:io';

import 'package:test/test.dart';

// Import tool libraries via relative paths (tool is not a pub package).
import '../pure_package_graph_guard.dart';
import '../pure_packages.dart';

void main() {
  group('isForbiddenRuntimeDependency', () {
    test('flags exact and prefixed forbidden names', () {
      expect(isForbiddenRuntimeDependency('http'), isTrue);
      expect(isForbiddenRuntimeDependency('flutter'), isTrue);
      expect(isForbiddenRuntimeDependency('flutter_riverpod'), isTrue);
      expect(isForbiddenRuntimeDependency('drift'), isTrue);
      expect(isForbiddenRuntimeDependency('drift_dev'), isTrue);
      expect(isForbiddenRuntimeDependency('jaspr'), isTrue);
      expect(isForbiddenRuntimeDependency('path_provider'), isTrue);
      expect(isForbiddenRuntimeDependency('dio'), isTrue);
    });

    test('allows pure / unknown / empty names', () {
      expect(isForbiddenRuntimeDependency(''), isFalse);
      expect(isForbiddenRuntimeDependency('collection'), isFalse);
      expect(isForbiddenRuntimeDependency('destiny2_sandbox_data'), isFalse);
      expect(isForbiddenRuntimeDependency('meta'), isFalse);
    });
  });

  group('parseRuntimeDependencyNames', () {
    test('empty map yields no names', () {
      const yaml = '''
name: example
dependencies: {}
dev_dependencies:
  test: ^1.0.0
''';
      expect(parseRuntimeDependencyNames(yaml), isEmpty);
    });

    test('parses multi-line dependency keys', () {
      const yaml = '''
name: example
dependencies:
  http: ^1.0.0
  collection: any
dev_dependencies:
  test: ^1.0.0
''';
      expect(
        parseRuntimeDependencyNames(yaml),
        containsAll(['http', 'collection']),
      );
    });

    test('ignores nested sdk keys under a dependency', () {
      const yaml = '''
name: example
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.0.0
''';
      final names = parseRuntimeDependencyNames(yaml);
      expect(names, containsAll(['flutter', 'path_provider']));
      expect(names, isNot(contains('sdk')));
    });

    test('stops at next top-level key', () {
      const yaml = '''
dependencies:
  dio: 5.0.0
dev_dependencies:
  lints: any
''';
      expect(parseRuntimeDependencyNames(yaml), ['dio']);
    });
  });

  group('scanPubspecContent', () {
    test('clean empty deps produces no violations', () {
      const yaml = '''
name: destiny2_domain
dependencies: {}
dev_dependencies:
  test: ^1.25.0
  lints: ^5.0.0
''';
      final v = scanPubspecContent(
        packageDir: 'packages/domain',
        pubspecPath: 'packages/domain/pubspec.yaml',
        contents: yaml,
      );
      expect(v, isEmpty);
    });

    test('forbidden http dependency is reported', () {
      const yaml = '''
name: destiny2_domain
dependencies:
  http: ^1.2.0
''';
      final v = scanPubspecContent(
        packageDir: 'packages/domain',
        pubspecPath: 'packages/domain/pubspec.yaml',
        contents: yaml,
      );
      expect(v, hasLength(1));
      expect(v.single.dependencyName, 'http');
    });

    test('forbidden flutter sdk dep is reported', () {
      const yaml = '''
name: bad
dependencies:
  flutter:
    sdk: flutter
''';
      final v = scanPubspecContent(
        packageDir: 'packages/domain',
        pubspecPath: 'x',
        contents: yaml,
      );
      expect(v.any((e) => e.dependencyName == 'flutter'), isTrue);
    });
  });

  group('findWorkspaceRoot', () {
    test('resolves flutter/ workspace from dart workspace cwd', () {
      final workspace = findWorkspaceRoot(Directory.current);
      expect(isDartWorkspaceRoot(workspace), isTrue);
      expect(
        File('${workspace.path}/packages/domain/pubspec.yaml').existsSync(),
        isTrue,
        reason: 'workspace root was ${workspace.path}',
      );
    });

    test('resolves flutter/ workspace from monorepo root parent', () {
      final dartRoot = findWorkspaceRoot(Directory.current);
      final monorepo = dartRoot.parent;
      // Monorepo root has package.json + nested flutter/ after DART-069.
      expect(File('${monorepo.path}/package.json').existsSync(), isTrue);
      final fromMono = findWorkspaceRoot(monorepo);
      expect(
        fromMono.resolveSymbolicLinksSync(),
        dartRoot.resolveSymbolicLinksSync(),
      );
    });
  });

  group('live pure packages', () {
    test('workspace pure packages pass the graph guard', () {
      // When run via `dart test` from flutter/, CWD is Dart workspace root.
      // findWorkspaceRoot also accepts monorepo root (parent with flutter/).
      final workspace = findWorkspaceRoot(Directory.current);
      final result = scanPurePackages(workspace);
      expect(
        result.packagesScanned,
        containsAll(purePackageDirs),
        reason: 'workspace root was ${workspace.path}',
      );
      expect(
        result.violations,
        isEmpty,
        reason: result.violations.map((e) => e.toString()).join('\n'),
      );
    });
  });
}
