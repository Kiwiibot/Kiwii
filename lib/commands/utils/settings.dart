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
import 'package:option/option.dart';

import '../../kiwii.dart';
import '../../plugins/base.dart';
import '../../plugins/localization.dart';
import '../../src/converters/converters.dart';
import '../../src/models/guild.dart';
import '../../translations.g.dart';

const settingsCommandName = 'settings';
const settingsCommandDescription = 'Manage the settings of the bot for this server';

final settingsCommand = ChatGroup(
  settingsCommandName,
  settingsCommandDescription,
  localizedNames: {Locale.enGb: settingsCommandName, Locale.enUs: settingsCommandName, Locale.fr: 'paramètres'},
  localizedDescriptions: {
    Locale.enGb: settingsCommandDescription,
    Locale.enUs: settingsCommandDescription,
    Locale.fr: 'Gère les paramètres du bot pour ce serveur',
  },
  checks: [GuildCheck.all(), PermissionsCheck(Permissions.manageGuild, allowsOverrides: false)],
  children: [
    ChatGroup(
      'set',
      'Set settings',
      children: [
        ChatCommand(
          'locale',
          'Set the locale of the bot',
          id('settings-locale', (ChatContext ctx, AppLocale locale) async {
            await localization.setLocale(locale, ctx.guild!.id);
            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.set.locale(locale: stringifyLocale(locale))));
          }),
        ),
        ChatCommand(
          'mod-logs',
          'Set the mod channel',
          id('settings-modchannel', (ChatContext ctx, GuildTextChannel channel) async {
            await ctx.client.repositories.guilds.createOrEdit(EditableGuild(guildId: ctx.guild!.id, modLogChannelId: Some(channel.id)));

            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.set.modChannel(channel: channel.mention)), level: ResponseLevel.hint);
          }),
          checks: [PermissionsCheck(Permissions.manageChannels, allowsOverrides: false)],
        ),
        ChatCommand(
          'appeals',
          'Sets the appeals channel',
          id('settings-appealschannel', (ChatContext ctx, GuildTextChannel channel) async {
            await ctx.client.repositories.guilds.createOrEdit(EditableGuild(guildId: ctx.guild!.id, appealChannelId: Some(channel.id)));

            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.set.appealsChannel(channel: channel.mention)), level: ResponseLevel.hint);
          }),
        ),
        ChatCommand(
          'logs',
          'Set the log channel',
          id('settings-logchannel', (ChatContext ctx, GuildTextChannel channel) async {
            final webhook = await ctx.client.webhooks.create(
              WebhookBuilder(name: (await ctx.client.user.get()).username, channelId: channel.id),
              auditLogReason: ctx.guild.t.settings.webhookCreateReason,
            );

            await ctx.client.repositories.guilds.createOrEdit(EditableGuild(guildId: ctx.guild!.id, guildLogWebhookId: Some(webhook.id)));

            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.set.logsChannel(channel: channel.mention)), level: ResponseLevel.hint);
          }),
        ),
      ],
    ),
    ChatGroup(
      'module',
      'Settings to manage guild-related modules',
      children: [
        ChatCommand(
          'load',
          'Loads the specified module',
          id('settings-module-load', (ChatContext ctx, @Name('module-name') BasePlugin module) async {
            await module.onLoad(ctx.client, guild: ctx.guild!);
            final guild = await ctx.client.repositories.guilds.get(ctx.guild!.id);

            await ctx.client.repositories.guilds.edit(EditableGuild(guildId: guild.guildId, enabledModules: [...guild.enabledModules, module.name]));

            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.modules.loaded(module: module.name)));
          }),
        ),
        ChatCommand(
          'unload',
          'Unloads the specified module',
          id('settings-module-unload', (ChatContext ctx, @Name('module-name') BasePlugin module) async {
            await module.onUnload(ctx.client, guild: ctx.guild!);
            ctx.guild!.modules.remove(module.name);
            final guild = await ctx.client.repositories.guilds.get(ctx.guild!.id);
            guild.enabledModules.remove(module.name);
            await ctx.client.repositories.guilds.edit(EditableGuild(guildId: guild.guildId, enabledModules: guild.enabledModules));
            await ctx.respond(MessageBuilder(content: ctx.guild.t.settings.modules.unloaded(module: module.name)));
          }),
        ),
      ],
    ),
  ],
);

final _permissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.manageChannels;
final _clientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

final starboardSettingsCommand = ChatGroup(
  'starboard',
  'Manages settings for the starboard',
  checks: [BasePermissionsCheck(_permissions), BaseSelfPermissionsCheck(_clientPermissions)],
  options: KiwiiCommandOptions(permissions: _permissions, clientPermissions: _clientPermissions, usage: '{prefix}starboard ', examples: []),
  children: [
    ChatCommand(
      'channel',
      'Sets the starboard channel to the given channel.',
      id('starboard-channel', (ChatContext ctx, GuildTextChannel channel) async {
        await ctx.client.repositories.connection.execute(
          r'INSERT INTO starboard (guild, channel_id) VALUES ($1, $2) ON CONFLICT (guild) DO UPDATE SET channel_id = $2;',
          parameters: [ctx.guild!.id.value, channel.id.value],
        );

        await ctx.respond(MessageBuilder(content: 'Yeah, done ig.'));
      }),
      options: KiwiiCommandOptions(usage: '[channel]', examples: [(command: '#feet-pics', description: 'Sets the starboard to the channel #feet-pics')]),
    ),
    ChatGroup(
      'emoji',
      'Set settings about emojis here',
      children: [
        ChatCommand(
          'threshold',
          'Sets the threshold to trigger a starboard message',
          id('starboard-emoij-threshold', (ChatContext ctx, int threshold) async {
            await ctx.client.repositories.connection.execute(r'UPDATE starboard SET threshold = $1 WHERE id = $2', parameters: [threshold, ctx.guild!.id]);

            await ctx.respond(MessageBuilder(content: 'Set the threshld to `$threshold`'));
          }),
        ),
      ],
    ),
  ],
);
