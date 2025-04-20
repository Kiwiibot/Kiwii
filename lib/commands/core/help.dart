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

import 'dart:convert';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../utils/constants.dart';

final _permissions = Permissions.viewChannel | Permissions.sendMessages;
final _clientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

final helpCommand = ChatCommand(
  'help',
  'Help command',
  id('help', (ChatContext ctx, [ChatCommand? command]) async {
    if (command == null) {
      final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
      final embed =
          EmbedBuilder(fields: [])
            ..title = 'Help'
            ..description = 'Use `${ctx.realPrefix}help <command>` to get more information about a command.'
            ..color = DiscordColor(0x00ff00)
            ..footer = EmbedFooterBuilder(text: 'Kiwii', iconUrl: (await ctx.client.user.get()).avatar.url);

      final contents = StringBuffer();

      for (final command in commands) {
        contents.writeln('${command.fullName} - ${command.description}');
      }

      await ctx.respond(MessageBuilder(embeds: [embed], attachments: [AttachmentBuilder(data: utf8.encode(contents.toString()), fileName: 'help.txt')]));
      return;
    } else {
      if (command.options case final KiwiiCommandOptions options) {
        if (options.isHidden) {
          await ctx.send(ctx.guild.t.general.errors.commandNotFound);
          return;
        }

        if (ctx.channel case GuildTextChannel channel when !channel.isNsfw && options.isNsfw) {
          await ctx.send('This command is only available in NSFW channels.');
          return;
        }

        final key = command.fullName.split(' ').join('.');

        final description = ctx.guild.t['commands.$key.description'] as String? ?? command.commentDescription ?? command.description;
        final usage = ctx.guild.t['commands.$key.usage'] as String? ?? options.usage;
        final examples = [
          for (int i = 0; i < options.examples.length; i++)
            (
              command: ctx.guild.t['commands.$key.examples.usages.$i'] as String? ?? options.examples[i].command,
              description: ctx.guild.t['commands.$key.examples.descriptions.$i'] as String? ?? options.examples[i].description,
            ),
        ];
        final category = insertEmojiForCategory(
          options.category ?? 'unknown',
          ctx.guild.t['general.categories.${options.category ?? 'unknown'}'] as String? ?? options.category ?? ctx.guild.t.general.categories.unknown,
        );

        final (realPermissions, realClientPermissions) = digPermissions(command, (
          options.permissions ?? Permissions(0),
          options.clientPermissions ?? Permissions(0),
        ));

        final permissions = translatePermissions(realPermissions!, ctx.guild.t);

        final clientPermissions = translatePermissions(realClientPermissions!, ctx.guild.t);

        final t = ctx.guild.t.commands.help;

        final embed = EmbedBuilder(
          title: t.panel,
          color: DiscordColor(0xFFA500),
          footer: EmbedFooterBuilder(text: 'Kiwii', iconUrl: (await ctx.client.user.get()).avatar.url),
          description: t.findMore,
          fields: [
            EmbedFieldBuilder(
              name: t.name,
              value: command.localizedNames?[reverseMap(discordLocaleToAppLocale)[ctx.guild.t.$meta.locale]] ?? command.fullName,
              isInline: true,
            ),
            EmbedFieldBuilder(name: t.category, value: category, isInline: true),
            EmbedFieldBuilder(
              name: t.usageString,
              value: usage != null ? inlineCode('${ctx.realPrefix}${command.fullName}${usage.isEmpty ? '' : ' $usage'}') : 'No usage provided',
              isInline: true,
            ),
            EmbedFieldBuilder(name: t.permissions, value: permissions.map((p) => inlineCode(p)).join(', '), isInline: true),
            EmbedFieldBuilder(name: t.clientPermissions, value: clientPermissions.map((p) => inlineCode(p)).join(', '), isInline: true),
            EmbedFieldBuilder(name: t.descriptionString, value: description, isInline: true),
            EmbedFieldBuilder(
              name: t.examplesString,
              value:
                  examples.isNotEmpty
                      ? examples
                          .map((e) => '- ${inlineCode('${ctx.realPrefix}${command.fullName}${e.command.isEmpty ? '' : ' ${e.command}'}')} ${e.description}')
                          .join('\n')
                      : t.noExamples,
              isInline: false,
            ),
          ],
        );

        if (options.img != null) {
          embed.thumbnail = EmbedThumbnailBuilder(url: Uri.parse(options.img!));
        }

        await ctx.respond(MessageBuilder(embeds: [embed]));
      }
    }
  }),
  checks: [BasePermissionsCheck(_permissions), BaseSelfPermissionsCheck(_clientPermissions)],
  options: KiwiiCommandOptions(
    permissions: _permissions,
    clientPermissions: _clientPermissions,
    category: 'utility',
    usage: "<command>",
    examples: [(command: "ban", description: "Get help about the ban command"), (command: "", description: "Display the available commands")],
  ),
);

(Flags<Permissions>?, Flags<Permissions>?) digPermissions(CommandGroup<CommandContext> command, (Flags<Permissions>, Flags<Permissions>) basePermissions) =>
    switch (command) {
      ChatCommand(:final options, :final parent) => switch (options) {
        KiwiiCommandOptions(:final permissions?, :final clientPermissions?) =>
          parent != null
              ? digPermissions(parent, (basePermissions.$1 | permissions, basePermissions.$2 | clientPermissions))
              : (basePermissions.$1 | permissions, basePermissions.$2 | clientPermissions),
        _ => basePermissions,
      },
      ChatGroup(:final options, :final parent) => switch (options) {
        KiwiiCommandOptions(:final permissions?, :final clientPermissions?) =>
          parent != null
              ? digPermissions(parent, (basePermissions.$1 | permissions, basePermissions.$2 | clientPermissions))
              : (basePermissions.$1 | permissions, basePermissions.$2 | clientPermissions),
        _ => basePermissions,
      },
      _ => basePermissions,
    };
