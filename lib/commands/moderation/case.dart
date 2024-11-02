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

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/autocomplete/case.dart';
import '../../src/moderation/utils/generate.dart';

final _permissions = Permissions.manageMessages | Permissions.viewChannel | Permissions.sendMessages;
final _clientPermissions = Permissions.manageMessages | Permissions.viewChannel | Permissions.sendMessages;

final caseCommand = ChatCommand(
  'case',
  'Lookup a moderation case.',
  id(
    'case',
    (
      ChatContext ctx,
      @Autocomplete(caseAutoCompleteWithHistory) String phrase, [
      bool hideReply = false,
    ]) async {
      final db = ctx.client.db;
      if (ctx is InteractionChatContext) {
        await ctx.acknowledge(level: hideReply ? ResponseLevel.hint : null);
      }

      final s = phrase.split(';');

      if (s.length != 2) {
        final n = int.tryParse(phrase);

        if (n == null) {
          return;
        }

        final ccase = await db.getCase(n, ctx.guild!.id);

        final guildSettings = await db.getGuild(ctx.guild!.id);

        if (guildSettings.modLogChannelId == null) {
          await ctx.send(ctx.guild.t.general.errors.noModChannel);
        }

        final modChannel = await ctx.client.channels.get(guildSettings.modLogChannelId!);

        final mod = await ctx.client.users.get(ccase.modId!);

        final goTo = ButtonBuilder.link(
          url: Uri.parse(
            messageLink(
              ccase.logMessageId!,
              modChannel.id,
              ctx.guild!.id,
            ),
          ),
          label: ctx.guild.t.moderation.history.cases.goto(
            ccase: ccase.caseId,
          ),
        );

        await ctx.respond(
          MessageBuilder(
            embeds: [
              cutEmbed(
                await generateCaseEmbed(
                  ctx.guild!.id,
                  modChannel.id,
                  ccase,
                  ctx.guild.t,
                  ctx.realPrefix,
                  mod,
                ),
              ),
            ],
            components: [
              ActionRowBuilder(
                components: [goTo],
              ),
            ],
          ),
          level: hideReply ? ResponseLevel.hint : null,
        );
        return;
      }

      final [op, id] = s;

      if (op == 'history') {
        final tuple = (
          member: await ctx.guild!.members.get(
            Snowflake.parse(id),
          ),
          user: await ctx.client.users.get(
            Snowflake.parse(id),
          ),
        );

        final embed = cutEmbed(
          await generateHistory(
            tuple,
            ctx.guild!.id,
            ctx.guild.t,
          ),
        );

        await ctx.respond(
          MessageBuilder(
            embeds: [embed],
          ),
          level: hideReply ? ResponseLevel.hint : null,
        );
      }
    },
  ),
  checks: [
    BasePermissionsCheck(_permissions),
    SelfPermissionsCheck(_clientPermissions),
    GuildCheck.all(),
  ],
  options: KiwiiCommandOptions(
    category: 'moderation',
    usage: '[case number] <hide reply>',
    examples: [
      (command: '123', description: 'Lookup case 123'),
    ],
    permissions: _permissions,
    clientPermissions: _clientPermissions,
  ),
);
