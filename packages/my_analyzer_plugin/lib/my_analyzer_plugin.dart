import 'package:analyzer_plugin/analyzer_plugin.dart';
import 'package:analyzer/dart/element/element.dart';

AnalyzerPlugin createPlugin() {
  return _MyAnalyzerPlugin();
}

class _MyAnalyzerPlugin extends AnalyzerPlugin {
  @override
  String get name => 'my_dart_analyzer_plugin';

  @override
  List<Diagnostics> run(LibraryElement libraryElement) {
    final hasElementFunction = libraryElement.topLevelElements
        .any((element) => element.name == 'example');
    return [
      if (!hasElementFunction)
        Diagnostics(
          DiagnosticsType.warning,
          'All libraries must contain a global function named `example`',
        )
    ];
  }
}
