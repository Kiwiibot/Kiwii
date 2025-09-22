import 'package:nyxx/nyxx.dart';
import 'package:sentry/sentry.dart';

/// A [HttpHandler] that uses Sentry for error reporting.
class SentryHttpHandler extends HttpHandler {
  @override
  SentryHttpClient get httpClient => SentryHttpClient();

  SentryHttpHandler(super.client);
}
