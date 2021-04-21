import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'package:cli_util/cli_logging.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

abstract class Socket {}

final _log = Logger.standard();

Future<void> startPlugin({
  required List<String> args,
  required String pluginName,
  required String pluginInterfaceName,
  required String mainSource,
}) async {
  final ownerDetails = await _findOwnerPubspec();

  final pubspecFile = File('./pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    _log.stderr(
      'The current folder (${Directory.current.absolute.path}) does not contains a `pubspec.yaml`',
    );
    exit(-1);
  }
  final analyzedPubspec = Pubspec.parse(await pubspecFile.readAsString());

  final progress = _log.progress('Searching for plugins');
  final plugins = await _findPluginsThatDependsOnPackage(
    analyzedPubspec: analyzedPubspec,
    packageName: 'analyzer_plugin',
  ).toList();
  progress.finish(showTiming: true);

  final pluginsBuffer = StringBuffer('Found ${plugins.length} plugins\n');
  for (final plugin in plugins) {
    pluginsBuffer.writeln('- ${plugin.name}');
  }
  _log.stdout(pluginsBuffer.toString());

  await _generateTemporaryProject(
    plugins,
    pluginName: pluginName,
    analyzedPubspec: analyzedPubspec,
    ownerDetails: ownerDetails,
    entrypointSource: mainSource,
    pluginInterfaceName: pluginInterfaceName,
  );

  final process = await Process.start(
    'dart',
    ['run', './.dart_tool/plugin/generated/bin/generated_project.dart'],
  );

  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

Future<_PackageDetails> _findOwnerPubspec() async {
  final mirror = currentMirrorSystem();

  var dir = Directory(
    FileSystemEntity.parentOf(
      mirror.isolate.rootLibrary.uri.toFilePath(),
    ),
  );

  while (!await File('${dir.path}/pubspec.yaml').exists()) {
    dir = dir.parent;
  }

  final pubspecFile = await File('${dir.path}/pubspec.yaml').readAsString();
  final pubspec = Pubspec.parse(pubspecFile);

  return _PackageDetails(name: pubspec.name, path: dir.path, pubspec: pubspec);
}

Future<void> _generateTemporaryProject(
  List<_PackageDetails> plugins, {
  required String pluginName,
  required _PackageDetails ownerDetails,
  required Pubspec analyzedPubspec,
  required String entrypointSource,
  required String pluginInterfaceName,
}) async {
  await _generateTemporaryPubspec(plugins, ownerDetails: ownerDetails);

  final entrypointFile =
      File('./.dart_tool/plugin/generated/bin/entrypoint.dart');
  await entrypointFile.create(recursive: true);
  await entrypointFile.writeAsString(entrypointSource);

  final generatedMainFile =
      File('./.dart_tool/plugin/generated/bin/generated_project.dart');
  await generatedMainFile.create(recursive: true);

  final pluginsImports = [
    for (final plugin in plugins)
      "import 'package:${plugin.name}/${plugin.name}.dart' as ${plugin.name};"
  ].join('\n');

  final pluginDetails = [
    for (final plugin in plugins) "    ${plugin.name}.createPlugin(),"
  ];

  generatedMainFile.writeAsString('''
import './entrypoint.dart' as entrypoint;
import 'package:$pluginName/$pluginName.dart' as $pluginName;
$pluginsImports

void main(List<String> args) {
  final List<$pluginName.${pluginInterfaceName}> plugins = [
${pluginDetails.join('\n')}
  ];
  entrypoint.main(args, plugins);
}
''');
}

Future<void> _generateTemporaryPubspec(
  List<_PackageDetails> plugins, {
  required _PackageDetails ownerDetails,
}) async {
  final generatedPubspecFile =
      File('./.dart_tool/plugin/generated/pubspec.yaml');
  await generatedPubspecFile.create(recursive: true);

  final generatedPubspecBuffer = StringBuffer();

  // TODO: reuse environment from pubspec
  generatedPubspecBuffer.write('''
name: generated_project

environment:
  sdk: ">=2.12.0 <3.0.0"

dependencies:
  ${ownerDetails.name}:
    path: ${ownerDetails.path}
''');

  for (final plugin in plugins) {
    generatedPubspecBuffer.write('''
  ${plugin.name}:
    path: ${plugin.path}
''');
  }

  await generatedPubspecFile.writeAsString(generatedPubspecBuffer.toString());

  final progress =
      _log.progress('Running `dart pub get` in the generated project');
  await Process.run(
    'dart',
    ['pub', 'get'],
    workingDirectory: './.dart_tool/plugin/generated',
  );
  progress.finish(showTiming: true);
}

class _PackageDetails {
  _PackageDetails({
    required this.name,
    required this.path,
    required this.pubspec,
  });

  final String name;
  final String path;
  final Pubspec pubspec;
}

Stream<_PackageDetails> _findPluginsThatDependsOnPackage({
  required String packageName,
  required Pubspec analyzedPubspec,
}) async* {
  final packageConfigFile = File('./.dart_tool/package_config.json');

  if (!packageConfigFile.existsSync()) {
    _log.stderr("""
Dependencies not found.
Make sure to run `dart pub get` first""");
    exit(-1);
  }

  final packageConfig = json.decode(await packageConfigFile.readAsString())
      as Map<String, Object?>;
  final packages =
      (packageConfig['packages'] as List).cast<Map<String, Object?>>();

  final allDirectDependencies = {
    ...analyzedPubspec.dependencies,
    ...analyzedPubspec.devDependencies,
  }.entries;

  for (final dep in allDirectDependencies) {
    final dependencyConfig = packages.firstWhere(
      (e) => e['name'] == dep.key,
      orElse: () {
        _log.stderr("""
Dependencies not found.
Make sure to run `dart pub get` first""");
        exit(-1);
      },
    );

    var uri = dependencyConfig['rootUri'] as String;
    if (uri.startsWith('../')) uri = uri.replaceFirst('../', '');

    final packagePath = Directory.fromUri(Uri.parse(uri)).absolute.path;
    final packagePubspecFile = File('${packagePath}/pubspec.yaml');

    if (!packagePubspecFile.existsSync()) {
      _log.stderr(
        'No pubspec.yaml for package ${dep.key} at ${packagePubspecFile.path}',
      );
      exit(-1);
    }

    final packagePubspec =
        Pubspec.parse(await packagePubspecFile.readAsString());

    if (packagePubspec.dependencies.containsKey(packageName) ||
        packagePubspec.devDependencies.containsKey(packageName))
      yield _PackageDetails(
        name: dep.key,
        path: packagePath,
        pubspec: packagePubspec,
      );
  }
}
