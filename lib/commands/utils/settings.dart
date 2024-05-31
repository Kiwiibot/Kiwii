/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
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
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../utils/constants.dart';

final settingsCommand = ChatGroup(
  'settings',
  'Manage the settings of the bot for this guild',
  checks: [
    GuildCheck.all(),
    PermissionsCheck(
      Permissions.manageGuild,
      allowsOverrides: false,
    ),
  ],
  children: [
    ChatCommand(
      'locale',
      'Set the locale of the bot',
      id(
        'settings-locale',
        (ChatContext ctx, @Choices(choicesLocale) String locale) async {
          final appLocale = convertLocale(locale);

          if (appLocale == null) {
            return ctx.respond(MessageBuilder(content: 'Invalid locale'));
          }

          await localization.setLocale(appLocale, ctx.guild!.id);
          await ctx.respond(MessageBuilder(content: 'Locale set to `$locale`'));
        },
      ),
    ),
    ChatCommand(
      'modchannel',
      'Set the mod channel',
      id(
        'settings-modchannel',
        (ChatContext ctx, GuildTextChannel channel) async {
          await ctx.client.db.into(ctx.client.db.guildTable).insert(
                GuildTableCompanion.insert(
                  guildId: Value(ctx.guild!.id),
                  modLogChannelId: Value(channel.id),
                ),
                onConflict: DoUpdate(
                  (tbl) => GuildTableCompanion(
                    modLogChannelId: Value(channel.id),
                  ),
                ),
              );

          await ctx.respond(MessageBuilder(content: 'Mod channel set to ${channel.mention}'));
        },
      ),
      checks: [
        PermissionsCheck(
          Permissions.manageChannels,
          allowsOverrides: false,
        ),
      ],
    ),
    ChatCommand(
      'appealschannel',
      'Sets the appeals channeé',
      id(
        'settings-appealschannel',
        (ChatContext ctx, GuildTextChannel channel) async {
          await ctx.client.db.into(ctx.client.db.guildTable).insert(
                GuildTableCompanion.insert(
                  guildId: Value(ctx.guild!.id),
                  appealChannelId: Value(channel.id),
                ),
                onConflict: DoUpdate(
                  (tbl) => GuildTableCompanion(
                    appealChannelId: Value(channel.id),
                  ),
                ),
              );

          await ctx.respond(MessageBuilder(content: 'Appeals channel set to ${channel.mention}'));
        },
      ),
    ),
  ],
);

Iterable<CommandOptionChoiceBuilder<String>> autocompleteModules(AutocompleteContext ctx) {
  final current = ctx.currentValue;
  final filtered = ctx.client.options.plugins.where((plugin) => plugin.name.contains(current));

  return filtered.map((e) => CommandOptionChoiceBuilder(name: e.name, value: e.name));
}
