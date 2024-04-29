import 'dart:isolate';

import 'package:nyxx/nyxx.dart';
import 'package:sentry/sentry_io.dart';

final traceExceptions = TraceExceptions();

/// A plugin that prevents errors from crashing the program, instead logging them to the console.
class TraceExceptions extends NyxxPlugin {
  @override
  String get name => 'TraceExceptions';

  /// The logger used to report the errors.
  @override
  Logger get logger => Logger('TraceExceptions');

  static int _clients = 0;
  ReceivePort? _errorPort;

  void _listenIfNeeded() {
    if (_errorPort != null) {
      return;
    }

    _errorPort = ReceivePort();
    _errorPort!.listen((err) async {
      final stackTrace = err[1] != null ? StackTrace.fromString(err[1] as String) : null;
      final message = err[0] as String;

      logger.shout('Unhandled exception was thrown', message, stackTrace);

      await Sentry.captureException(
        Exception(message),
        stackTrace: stackTrace,
      );
    });

    Isolate.current.setErrorsFatal(false);
    Isolate.current.addErrorListener(_errorPort!.sendPort);
  }

  void _stopListeningIfNeeded() {
    if (_clients > 0) {
      return;
    }

    _stopListening();
  }

  void _stopListening() {
    Isolate.current.removeErrorListener(_errorPort!.sendPort);
    Isolate.current.setErrorsFatal(true);

    _errorPort?.close();
  }

  @override
  void afterConnect(Nyxx client) {
    _clients++;
    _listenIfNeeded();
  }

  @override
  void afterClose() {
    _clients--;
    _stopListeningIfNeeded();
  }
}
