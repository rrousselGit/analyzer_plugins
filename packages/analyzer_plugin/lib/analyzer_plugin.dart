import 'package:analyzer/dart/element/element.dart';

abstract class AnalyzerPlugin {
  String get name;

  List<Diagnostics> run(LibraryElement result);
}

enum DiagnosticsType { warning, error }

class Diagnostics {
  Diagnostics(this.type, this.message);

  final DiagnosticsType type;
  final String message;
}
