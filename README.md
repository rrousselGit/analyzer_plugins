An example of a plugin mechanism using code-generation

This contains:

- `analyzer_plugin`, an interface for custom analysis plugins
- `my_analyzer_plugin`, a custom analyzer plugin that emits a warning if a dart file doesn't contain a `void element()` function.
- `another_plugin`, a plugin which throws an error (that is then reported to the cli)
- `plugin`, a package that implements the "generates a main file that combines all the plugin" logic.
- `mydartanalyzer`, which combines `plugin` and `analyzer_plugin`
  into a custom command `dart analyze` command line which has a plugin mechanism

## Demo

```sh
cd packages/mydartanalyzer
dart pub global activate -s path .

cd ../flutter_app_core
flutter pub get

mydartanalyzer
```

This would output

```
$ mydartanalyzer
Searching for plugins...               0.1s
Found 2 plugins
- my_analyzer_plugin
- another_plugin

Running `dart pub get` in the generated project... 0.9s

warning • All libraries must contain a global function named `example`
/Users/remirousselet/dev/analysis/packages/flutter_app_core/lib/main.dart

The plugin AnotherExample crashed with the following exception:

Bad state: Fake error to simulate exceptions in plugins
#0      _AnotherPlugin.run (package:another_plugin/another_plugin.dart:14:5)
#1      start (package:mydartanalyzer/mydartanalyzer.dart:31:41)
<asynchronous suspension>
```