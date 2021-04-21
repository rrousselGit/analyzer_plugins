import 'package:analyzer_plugin/analyzer_plugin.dart';

AnalyzerPlugin createPlugin() {
  return _MyAnalyzerPlugin();
}

class _MyAnalyzerPlugin extends AnalyzerPlugin {
  @override
  String get name => '_MyAnalyzerPlugin';
}
