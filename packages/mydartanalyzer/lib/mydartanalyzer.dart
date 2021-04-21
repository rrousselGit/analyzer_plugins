import 'dart:async';
import 'dart:io';

import 'package:analyzer_plugin/analyzer_plugin.dart';
import 'package:cli_util/cli_util.dart';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/context/context_root.dart';

Future<void> start(List<String> args, List<AnalyzerPlugin> plugins) async {
  final driver = _createAnalysisDriver();

  final dirToListen = Directory(Directory('./lib').absolute.uri.toFilePath());

  await dirToListen.list(recursive: true).forEach((element) {
    driver.addFile(element.path);
  });

  await for (final event in driver.results) {
    final packagePath = event.session.uriConverter.pathToUri(event.path!);
    final result = await event.session.getLibraryByUri(packagePath!.toString());

    for (final plugin in plugins) {
      try {
        for (final diagnostic in plugin.run(result)) {
          final label =
              diagnostic.type == DiagnosticsType.error ? 'error' : 'warning';
          print('\n$label • ${diagnostic.message}\n${event.path}');
        }
      } catch (err, stack) {
        print(
          '\nThe plugin ${plugin.name} crashed with the following exception:\n',
        );
        print(err);
        print(stack);
      }
    }
  }

  // TODO: an IDE extension would watch file changess
}

AnalysisDriver _createAnalysisDriver() {
  final logger = PerformanceLog(null);
  var byteStore = MemoryByteStore();

  final scheduler = AnalysisDriverScheduler(logger)..start();

  final defaultSdkPath = getSdkPath();

  final contextBuilder = ContextBuilder(
    PhysicalResourceProvider.INSTANCE,
    DartSdkManager(defaultSdkPath),
    null,
  )
    ..performanceLog = logger
    ..byteStore = byteStore
    ..fileContentOverlay = FileContentOverlay()
    ..analysisDriverScheduler = scheduler;

  final contextRoot = ContextRoot(
    // '',

    '/Users/remirousselet/dev/analysis/packages/flutter_app_core',
    [],
    pathContext: PhysicalResourceProvider.INSTANCE.pathContext,
  );

  final workspace = ContextBuilder.createWorkspace(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    options: ContextBuilderOptions(),
    rootPath: contextRoot.root,
  );

  return contextBuilder.buildDriver(contextRoot, workspace);
}
