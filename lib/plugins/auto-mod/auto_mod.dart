import 'package:nyxx/nyxx.dart';
import 'package:perspective_api/perspective_api.dart';

import '../../src/settings.dart' as settings;
import '../../translations.g.dart';
import '../localization.dart';

final autoModerationPlugin = AutoModerationPlugin();

final mappings = {
  AppLocale.enGb: Language.english,
  AppLocale.frFr: Language.french,
};

class AutoModerationPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  String get name => 'AutoModeration';

  final perspective = PerspectiveApi(apiKey: settings.perspectiveApiKey);

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    final client = await super.doConnect(apiOptions, clientOptions, connect);

    client.on<MessageCreateEvent>((event) async {
      final message = event.message;
      final guild = await event.guild?.get();

      final analyzed = await perspective.analyzeComment(
        message.content,
        requestedAttributes: {
          RequestedAttribute.toxicity,
          RequestedAttribute.threat,
        },
        languages: {
          mappings[guild.t.$meta.locale]!,
        },
      );

      final attributes = analyzed.attributeScores;

      // ignore: unused_local_variable
      final highestScore = attributes.fold<double>(0, (previousValue, element) => element.summaryScore > previousValue ? element.summaryScore : previousValue);

      // if (highestScore > )
    });

    return client;
  }
}
