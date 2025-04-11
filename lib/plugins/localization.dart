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

import 'package:nyxx/nyxx.dart';

import '../src/models/guild.dart' hide Guild;
import '../translations.g.dart' show AppLocale, Translations;
import '../utils/constants.dart';
import '../utils/utils.dart';

final guildLocales = <Snowflake, AppLocale>{};

final defaultBuiltLocale = AppLocale.enGb.buildSync();
final defaultLocale = AppLocale.enGb;

final _locales = {
  AppLocale.enGb: defaultBuiltLocale,
};

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
    client.on<GuildCreateEvent>((event) async {
      final guild = event.guild;
      final data = await client.repositories.guilds.getOrNull(guild.id);
      final locale = data?.locale != null ? data!.locale : AppLocale.enGb;
      guildLocales[guild.id] = locale;
    });

    _locales[AppLocale.frFr] = await AppLocale.frFr.build();

    return client;
  }

  Future<void> setLocale(AppLocale locale, Snowflake guildId) async {
    guildLocales[guildId] = locale;
    var guild = await client.repositories.guilds.getOrNull(guildId);

    if (guild == null) {
      await client.repositories.guilds.create(EditableGuild(guildId: guildId, locale: locale));
    } else {
      await client.repositories.guilds.edit(EditableGuild(guildId: guildId, locale: locale));
    }
  }
}

extension LocaleGuild on Guild? {
  Translations get t => this != null ? _locales[guildLocales[this!.id]] ?? defaultBuiltLocale : defaultBuiltLocale;
}
