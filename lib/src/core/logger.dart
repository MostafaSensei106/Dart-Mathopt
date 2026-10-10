import 'package:logging/logging.dart';

/// Central logger for `dart_mathopt`.
///
/// Wraps `package:logging`. Call [initMathOptLogging] once at startup
/// if you want console output; otherwise records are silently dropped
/// unless the host app attaches its own listener.
final Logger mathOptLog = Logger('dart_mathopt');

/// Attaches a simple console listener to the root logger.
///
/// Set [level] to control verbosity. Calling this more than once is safe:
/// previous subscriptions created by this helper are cancelled first.
void Function() initMathOptLogging({Level level = Level.WARNING}) {
  Logger.root.level = level;
  final sub = Logger.root.onRecord.listen((record) {
    // Keep output compact and greppable.
    // ignore: avoid_print
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });
  return sub.cancel;
}
