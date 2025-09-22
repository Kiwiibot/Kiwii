import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../plugins/images_plugin.dart';
import '../../plugins/load_modules.dart';
import '../../plugins/localization.dart';
import '../../plugins/tag/tag.dart';
import '../../plugins/track_presences.dart';
import '../../plugins/tracking.dart';
import '../../utils/commands.dart';
import '../settings.dart' as settings;
import 'sentry_http_handler.dart';

class Kiwii extends NyxxGateway {
  // just shut up the dart analyzer already
  factory Kiwii() => throw UnimplementedError('bruh');

  @override
  SentryHttpHandler get httpHandler => SentryHttpHandler(this);

  static Future<NyxxGateway> connect() async {
    registerCommands();
    registerConverters();
    final status = '${settings.prefix}help ─ ${settings.statuses[Random().nextInt(settings.statuses.length)]}';

    return Nyxx.connectGatewayWithOptions(
      GatewayApiOptions(
        token: settings.token,
        intents: GatewayIntents.all,
        payloadFormat: GatewayPayloadFormat.etf,
        browser: 'Discord Android',
        initialPresence: PresenceBuilder(
          isAfk: false,
          status: CurrentUserStatus.idle,
          activities: [ActivityBuilder(type: ActivityType.custom, name: status, state: status)],
        ),
      ),
      GatewayClientOptions(
        plugins: [
          logging,
          TagPlugin(),
          ModulesPlugin(),
          TrackPresences(),
          ImagesPlugin(),
          tracking,
          cliIntegration,
          commands,
          pagination,
          localization,
          ignoreExceptions,
          guildJoins,
        ],
      ),
    );
  }
}
