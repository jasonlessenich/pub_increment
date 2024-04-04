import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml_edit/yaml_edit.dart';

class Version {
  final int major;
  final int minor;
  final int patch;

  Version(this.major, this.minor, this.patch);

  factory Version.parse(String version) {
    final List<String> parts = version.split('.');
    return Version(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Version incrementMajor() => Version(major + 1, 0, 0);
  Version incrementMinor() => Version(major, minor + 1, 0);
  Version incrementPatch() => Version(major, minor, patch + 1);

  @override
  String toString() => '$major.$minor.$patch';
}

enum IncrementType { major, minor, patch }

final ArgParser args = ArgParser()
  ..addOption('path', abbr: 'p', help: 'Path to pubspec.yaml file', defaultsTo: 'pubspec.yaml')
  ..addOption('type',
      abbr: 't',
      help: 'The type of version to increment (major, minor, patch)',
      defaultsTo: 'patch',
      allowed: ['major', 'minor', 'patch']);

void main(List<String> arguments) {
  final ArgResults results = args.parse(arguments);
  final IncrementType type =
      IncrementType.values.firstWhere((t) => t.name == results['type'], orElse: () => IncrementType.patch);

  final File pubspecFile = File(results['path']);
  final YamlEditor editor = YamlEditor(pubspecFile.readAsStringSync());
  Version version = Version.parse(editor.parseAt(['version']).value as String);
  version = switch (type) {
    IncrementType.major => version.incrementMajor(),
    IncrementType.minor => version.incrementMinor(),
    IncrementType.patch => version.incrementPatch()
  };
  editor.update(['version'], version.toString());
  pubspecFile.writeAsStringSync(editor.toString());
  print('Incremented version to ${version.toString()}');
}
