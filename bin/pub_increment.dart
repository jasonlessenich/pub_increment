import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml_edit/yaml_edit.dart';

class Version {
  final int major;
  final int minor;
  final int patch;
  final int? build;

  Version({required this.major, required this.minor, required this.patch, this.build});

  static Version? tryParse(String version) {
    final List<String> parts = version.split('.');
    if (parts.length < 3) {
      return null;
    }
    final List<String> patchParts = parts[2].split('+');
    int? build;
    if (patchParts.length > 1) {
      build = int.tryParse(patchParts[1]);
    }
    return Version(
        major: int.tryParse(parts[0]) ?? 0,
        minor: int.tryParse(parts[1]) ?? 0,
        patch: int.tryParse(patchParts[0]) ?? 0,
        build: build);
  }

  Version incrementMajor(bool incrementBuild) =>
      Version(major: major + 1, minor: 0, patch: 0, build: incrementBuild ? (build ?? 0) + 1 : null);
  Version incrementMinor(bool incrementBuild) =>
      Version(major: major, minor: minor + 1, patch: 0, build: incrementBuild ? (build ?? 0) + 1 : null);
  Version incrementPatch(bool incrementBuild) =>
      Version(major: major, minor: minor, patch: patch + 1, build: incrementBuild ? (build ?? 0) + 1 : null);

  @override
  String toString() => '$major.$minor.$patch${build != null ? '+$build' : ''}';
}

enum IncrementType { major, minor, patch }

final ArgParser args = ArgParser()
  ..addOption('path', abbr: 'p', help: 'Path to pubspec.yaml file', defaultsTo: 'pubspec.yaml')
  ..addOption('type',
      abbr: 't',
      help: 'The type of version to increment (major, minor, patch, build)',
      defaultsTo: 'patch',
      allowed: ['major', 'minor', 'patch'])
  ..addFlag('build', abbr: 'b', help: 'Increment build number', defaultsTo: false);

void main(List<String> arguments) {
  final ArgResults results = args.parse(arguments);
  final IncrementType type =
      IncrementType.values.firstWhere((t) => t.name == results['type'], orElse: () => IncrementType.patch);
  final bool incrementBuild = results['build'];

  final File pubspecFile = File(results['path']);
  final YamlEditor editor = YamlEditor(pubspecFile.readAsStringSync());
  Version version = Version.tryParse(editor.parseAt(['version']).value as String) ?? Version(major: 0, minor: 0, patch: 0);
  version = switch (type) {
    IncrementType.major => version.incrementMajor(incrementBuild),
    IncrementType.minor => version.incrementMinor(incrementBuild),
    IncrementType.patch => version.incrementPatch(incrementBuild)
  };
  editor.update(['version'], version.toString());
  pubspecFile.writeAsStringSync(editor.toString());
  print('Incremented version to ${version.toString()}');
}
