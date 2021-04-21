import 'package:analyzer_plugin/analyzer_plugin.dart';
import 'package:analyzer/dart/element/element.dart';

AnalyzerPlugin createPlugin() {
  return _AnotherPlugin();
}

class _AnotherPlugin extends AnalyzerPlugin {
  String get name => 'another_plugin';

  @override
  List<Diagnostics> run(LibraryElement result) {
    throw StateError('Fake error to simulate exceptions in plugins');
  }
}
