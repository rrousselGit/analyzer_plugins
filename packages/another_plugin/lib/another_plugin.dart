import 'package:analyzer_plugin/analyzer_plugin.dart';

AnalyzerPlugin createPlugin() {
  return _AnotherPlugin();
}

class _AnotherPlugin extends AnalyzerPlugin {
  @override
  String get name => 'AnotherExample';
}
