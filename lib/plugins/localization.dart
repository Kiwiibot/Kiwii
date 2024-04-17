import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../database.dart';
import '../translations.g.dart' show AppLocale, Translations, LocaleSettings;
import '../utils/constants.dart';

final guildLocales = <Snowflake, AppLocale>{};

final localization = LocalizationPlugin();

AppLocale? convertDiscordLocale(Locale locale) => discordLocaleToAppLocale[locale];

AppLocale? convertLocale(String locale) => locales[locale];

class LocalizationPlugin extends NyxxPlugin<NyxxGateway> {
  late final NyxxGateway client;

  @override
  String get name => 'Localization';

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    client = await super.doConnect(apiOptions, clientOptions, connect);
    final db = GetIt.I.get<AppDatabase>();
    client.on<GuildCreateEvent>((event) async {
      final guild = event.guild;
      final data = (await (db.select(db.guildTable)
                ..where((e) => e.guildId.equals(guild.id.value))
                ..limit(1))
              .get())
          .first;
      final locale = convertLocale(data.locale);
      final appLocale = locale ?? AppLocale.enGb;
      guildLocales[guild.id] = appLocale;
    });

    return client;
  }

  Future<void> setLocale(AppLocale locale, Snowflake guildId) {
    final db = GetIt.I.get<AppDatabase>();
    guildLocales[guildId] = locale;
    return db.into(db.guildTable).insertOnConflictUpdate(
          GuildTableCompanion.insert(
            guildId: guildId.value,
            locale: '${locale.languageCode}-${locale.countryCode}',
          ),
        );
  }
}
extension LocaleGuild on Guild? {
  Translations get t => this != null ? LocaleSettings.instance.translationMap[guildLocales[this!.id]] ?? AppLocale.enGb.build() : AppLocale.enGb.build();
}
