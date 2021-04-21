# Issues

## When starting, it's impossible to differentiate "plugin not started" from "plugin crashed" or "badly configured"

- no print on error/start
- having to open the analyzer diagnostic to know if the plugin is connected is unintuitive

ideas:

- have `dart analyze` and/or `flutter doctor` list the installed analysis plugins for the opened project

## Users have to both install a plugin and add it to their analysis_options

Since plugins are added to the pubspec.yaml, there shouldn't be a need to add them to the analysis_options.yaml

## Errors and setup issues are silent

If a plugin crashes or it is badly setup, both users and authors won't know what the problem is.

idea:

- `dart analyze` (and possibly `dart fix`) should behave like a `flutter doctor` for plugins:
  ```sh
  $ dart analyze

  looking for analyzer plugins...
  3 analyzer plugins detected:
  - a
  - b
  - c
  ```

  ```sh
  $ dart analyze

  looking for analyzer plugins...

  The project `my_flutter_app` depends on `my_analyzer_plugin` which depends on `analyzer_plugin`,
  but `my_analyzer_plugin` has no `tools/analyzer_plugin/bin/plugin.dart`. As such, `dart analyze`
  failed to start `my_analyzer_plugin`.
  ```

  Plugins should send an "OK" message even if there's no warning in the analyzed code.
  This would allow the CLI to warning against a connection issue. The documentation
  can then help troubleshoot this specific error

  ```sh
  $ dart analyze

  looking for analyzer plugins...
  1 analyzer plugin detected:
  - `my_analyzer_plugin`

  Starting plugin `my_analyzer_plugin`...
  (This operation seems to be taking longer than expected)
  ```

  ```sh
  $ dart analyze

  looking for analyzer plugins...
  1 analyzer plugin detected:
  - `my_analyzer_plugin`

  Starting plugin `my_analyzer_plugin`... (1 second)
  [my_analyzer_plugin] This is a print
  [my_analyzer_plugin] Unhandled exception:
  Instance of 'Error'
  0      main (file:///Users/remirousselet/dev/analysis/foo.dart:2:3)
  1      _delayEntrypointInvocation.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:283:19)
  2      _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:184:12)
  ```



## Plugin doesn't restart automatically on code update

Updating a plugin requires restarting the IDE to see changes

ideas:

- `dart analyze` should output the result of plugins too
- when using a `path:` dependency for a plugin, watch the source files and restart the IDE plugin on change
- have the IDEs expose a "restart analyzer plugins" command

## Debugging is difficult

No access to print or breakings

ideas:

- the analysis server should read the stdout/stderr of the process of each plugin
- override the Zone to catch errors/prints

We can then:

- send the output to both the IDE and the cli (when `dart analyze` is supported)
  - all logs/errors would render in the "output" tab of vscode
  - when an error is detected, vscode would show a snackbar saying "plugin XX crashed"
    and generate a log file that compiles all the logs
- IDEs should offer a way to correct to the process of a specific plugin


## When a bug is detected by a user, there is no natural way to report the errors to authors

Since there's no intuitive way to know why a plugin isn't working,

## Have to manually start the analyzer

This is too low level. The analyzer_plugin package should take care of this for users

## Have to manually listen for analysis changes

## Have to reimplement `// ignore` and `// ignore_for_file:`

Since plugins define a code, `// ignore:` should work by default by relying on this code.

## Positions are a bit difficult to manipulate

Consider an util to convert elements/ast nodes to offsets

## Have to reimplement "enable/disable" features in the `analysis_options.yaml`

It should be feasible to add custom codes to `lint: rules:` by default

Disabling a rule should also ideally skips the code that produces this warning

## Scaling issue

Plugins all must start their own analysis -> more plugins = slower
Since the analysis result is immutable, why is this necessary?

idea:

- use a build_runner like architecture and have all the plugins in the same process
  Then they can share the analysis result.

## Refactoring options can't request for user input

idea:

```dart
Future<void> myRenameRefactor() async {
  String newName = await plugin.askForInput(
    description: 'The new name',
  );
}
```

On IDE, this would show a snackbar/modal
