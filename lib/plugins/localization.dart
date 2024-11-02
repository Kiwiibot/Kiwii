/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Lexedia
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../database.dart' hide Guild;
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
          .getSingleOrNull());
      final locale = data?.locale != null ? data!.locale : AppLocale.enGb;
      guildLocales[guild.id] = locale;
    });

    return client;
  }

  Future<void> setLocale(AppLocale locale, Snowflake guildId) {
    final db = GetIt.I.get<AppDatabase>();
    guildLocales[guildId] = locale;
    return db.into(db.guildTable).insert(
          GuildTableCompanion.insert(
            guildId: Value(guildId),
            locale: Value(locale),
          ),
          onConflict: DoUpdate(
            (tbl) => GuildTableCompanion(
              locale: Value(locale),
            ),
          ),
        );
  }
}

extension LocaleGuild on Guild? {
  Translations get t => this != null ? LocaleSettings.instance.translationMap[guildLocales[this!.id]] ?? AppLocale.enGb.build() : AppLocale.enGb.build();
}
