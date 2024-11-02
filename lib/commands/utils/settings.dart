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
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../plugins/base.dart';
import '../../plugins/load_modules.dart';
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
      'Sets the appeals channel',
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
    ChatCommand(
      'logchannel',
      'Set the log channel',
      id(
        'settings-logchannel',
        (ChatContext ctx, GuildTextChannel channel) async {
          final webhook = await ctx.client.webhooks.create(
            WebhookBuilder(name: (await ctx.client.user.get()).username, channelId: channel.id),
            auditLogReason: ctx.guild.t.general.settings.webhookCreateReason,
          );

          await ctx.client.db.into(ctx.client.db.guildTable).insert(
                GuildTableCompanion.insert(
                  guildId: Value(ctx.guild!.id),
                  guildLogWebhookId: Value(webhook.id),
                ),
                onConflict: DoUpdate(
                  (tbl) => GuildTableCompanion(
                    guildLogWebhookId: Value(webhook.id),
                  ),
                ),
              );

          await ctx.respond(MessageBuilder(content: 'Log channel set to ${channel.mention}'), level: ResponseLevel.hint);
        },
      ),
    ),
    ChatGroup(
      'module',
      'Settings to manage guild-related modules',
      children: [
        ChatCommand(
          'load',
          'Loads the specified module',
          id(
            'settings-module-load',
            (ChatContext ctx, @Autocomplete(autocompleteModuleLoad) @Name('module-name') String mod) async {
              var module = ctx.guild!.modules[mod];

              if (module != null) {
                return ctx.respond(MessageBuilder(content: 'Module `${module.name}` already loaded'));
              }

              module = ctx.guild!.modules[mod] ??= modules[mod]!;
              await module.onLoad(ctx.client, guild: ctx.guild!);
              await ctx.respond(MessageBuilder(content: 'Module `${module.name}` loaded'));
            },
          ),
        ),
        ChatCommand(
          'unload',
          'Unloads the specified module',
          id(
            'settings-module-unload',
            (ChatContext ctx, @Autocomplete(autocompleteModuleUnload) @Name('module-name') String mod) async {
              final module = ctx.guild!.modules[mod];

              if (module == null) {
                return ctx.respond(MessageBuilder(content: 'Module `$mod` not found'));
              }

              await module.onUnload(ctx.client, guild: ctx.guild!);
              ctx.guild!.modules.remove(module.name);
              await ctx.respond(MessageBuilder(content: 'Module `${module.name}` unloaded'));
            },
          ),
        ),
      ],
    ),
  ],
);

Iterable<CommandOptionChoiceBuilder<String>> autocompleteModuleLoad(AutocompleteContext ctx) => autocompleteModules()(ctx);
Iterable<CommandOptionChoiceBuilder<String>> autocompleteModuleUnload(AutocompleteContext ctx) => autocompleteModules(unload: true)(ctx);

Iterable<CommandOptionChoiceBuilder<String>> Function(AutocompleteContext) autocompleteModules({bool unload = false}) => (ctx) {
      final current = ctx.currentValue.toLowerCase();
      final filtered = (unload ? ctx.guild!.modules : modules).values.where((module) => module.name.toLowerCase().contains(current));

      return (filtered.isEmpty ? (unload ? ctx.guild!.modules : modules).values : filtered).map((e) => CommandOptionChoiceBuilder(name: e.name, value: e.name));
    };
