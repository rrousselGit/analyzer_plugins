import 'package:plugin/plugin.dart';

Future<void> main(List<String> args) async {
  await startPlugin(
    args: args,
    pluginName: 'analyzer_plugin',
    pluginInterfaceName: 'AnalyzerPlugin',
    mainSource: r'''
import 'package:analyzer_plugin/analyzer_plugin.dart';
import 'package:mydartanalyzer/mydartanalyzer.dart';

Future<void> main(
  List<String> args,
  List<AnalyzerPlugin> plugins
) {
  return start(args, plugins);
}  
''',
  );
}
