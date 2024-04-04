import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml_edit/yaml_edit.dart';

enum IncrementType { major, minor, patch, none }

class Version {
  final int major;
  final int minor;
  final int patch;
  final int build;

  Version({required this.major, required this.minor, required this.patch, this.build = 0});

  static Version? tryParse(String version, {int? buildOverride}) {
    final List<String> parts = version.split('.');
    if (parts.length < 3) {
      return null;
    }
    final List<String> patchParts = parts[2].split('+');
    int? build = buildOverride;
    if (build == null && patchParts.length == 2) {
      build = int.tryParse(patchParts[1]);
    }
    return Version(
        major: int.tryParse(parts[0]) ?? 0,
        minor: int.tryParse(parts[1]) ?? 0,
        patch: int.tryParse(patchParts[0]) ?? 0,
        build: build ?? 0);
  }

  Version copyWith({int? major, int? minor, int? patch, int? build}) {
    return Version(
      major: major ?? this.major,
      minor: minor ?? this.minor,
      patch: patch ?? this.patch,
      build: build ?? this.build,
    );
  }

  Version increment(IncrementType type, {bool incrementBuild = true}) {
    Version version = Version(major: major, minor: minor, patch: patch, build: incrementBuild ? (build + 1) : 0);
    if (type == IncrementType.major) {
      version = version.copyWith(major: major + 1, minor: 0, patch: 0);
    } else if (type == IncrementType.minor) {
      version = version.copyWith(minor: minor + 1, patch: 0);
    } else if (type == IncrementType.patch) {
      version = version.copyWith(patch: patch + 1);
    }
    return version;
  }

  @override
  String toString() => '$major.$minor.$patch+$build';
}

final ArgParser args = ArgParser()
  ..addOption('path', abbr: 'p', help: 'Path to pubspec.yaml file', defaultsTo: 'pubspec.yaml')
  ..addOption('type',
      abbr: 't',
      help: 'The type of version to increment (major, minor, patch, build)',
      defaultsTo: 'none',
      allowed: ['major', 'minor', 'patch', 'none'])
  ..addOption('version', abbr: 'v', help: 'Version to set')
  ..addFlag('no-build-increment', help: '', defaultsTo: false);

void main(List<String> arguments) {
  final ArgResults results = args.parse(arguments);

  final IncrementType type =
      IncrementType.values.firstWhere((t) => t.name == results['type'], orElse: () => IncrementType.patch);
  final bool incrementBuild = results['no-build-increment'];
  final String? versionString = results['version'];

  final File pubspecFile = File(results['path']);
  final YamlEditor editor = YamlEditor(pubspecFile.readAsStringSync());
  final Version? currentVersion = Version.tryParse(editor.parseAt(['version']).value);

  final Version version =
      ((versionString != null ? Version.tryParse(versionString, buildOverride: currentVersion?.build) : currentVersion) ??
              Version(major: 0, minor: 0, patch: 0))
          .increment(type, incrementBuild: !incrementBuild);
  editor.update(['version'], version.toString());
  pubspecFile.writeAsStringSync(editor.toString());
  print('Incremented version to ${version.toString()} (was ${currentVersion?.toString() ?? '0.0.0'})');
}
