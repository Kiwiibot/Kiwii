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
import 'package:string_similarity/string_similarity.dart';

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../utils/constants.dart';

final helpCommand = ChatCommand(
  'help',
  'Help command',
  id('help', (ChatContext ctx, [ChatCommand? command]) async {
    //   if (command == null) {
    //     final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
    //     final embed = EmbedBuilder(fields: [])
    //       ..title = 'Help'
    //       ..description = 'Use `${ctx is MessageChatContext ? ctx.prefix : '/'}help <command>` to get more information about a command.'
    //       ..color = DiscordColor(0x00ff00)
    //       ..footer = EmbedFooterBuilder(
    //         text: 'Kiwii',
    //         iconUrl: (await ctx.client.user.get()).avatar.url,
    //       );

    //     for (final command in commands) {
    //       embed.fields!.add(EmbedFieldBuilder(
    //         name: command.fullName,
    //         value: command.description,
    //         isInline: false,
    //       ));
    //     }

    //     await ctx.respond(MessageBuilder(embeds: [embed]));
    //     return;
    //   }
    //   final embed = EmbedBuilder(fields: [])
    //     ..title = command.fullName
    //     ..description = command.description
    //     ..color = DiscordColor.parseHexString('#00ff00')
    //     ..footer = EmbedFooterBuilder(
    //       text: 'Kiwii',
    //       iconUrl: (await ctx.client.user.get()).avatar.url,
    //     );

    //   if (command.children.isNotEmpty) {
    //     embed.fields!.add(EmbedFieldBuilder(
    //       name: 'Subcommands',
    //       value: command.children.map((e) => e.fullName).join(', '),
    //       isInline: false,
    //     ));
    //   }
    //   await ctx.respond(MessageBuilder(embeds: [embed]));
    //   return;

    if (command != null) {
      final betchMatch = command.fullName.bestMatch(ctx.commands.walkCommands().whereType<ChatCommand>().map((c) => c.fullName).toList());
      final possible = betchMatch.bestMatch.target;

      if (possible == null) {
        await ctx.send(ctx.guild.t.general.errors.commandNotFound);
        return;
      }

      if (command.options case final KiwiiCommandOptions options) {
        if (options.isHidden) {
          await ctx.send(ctx.guild.t.general.errors.commandNotFound);
          return;
        }

        if (ctx.channel case GuildTextChannel channel when !channel.isNsfw && options.isNsfw) {
          await ctx.send('This command is only available in NSFW channels.');
          return;
        }

        final description = ctx.guild.t['commands.${command.fullName}.description'] as String? ?? command.description;
        final usage = ctx.guild.t['commands.${command.fullName}.usage'] as String? ?? options.usage;
        final examples = [
          for (int i = 0; i < options.examples.length; i++)
            (
              command: ctx.guild.t['commands.${command.fullName}.examples.usages.$i'] as String? ?? options.examples[i].command,
              description: ctx.guild.t['commands.${command.fullName}.examples.descriptions.$i'] as String? ?? options.examples[i].description
            ),
        ];
        final category = insertEmojiForCategory(
          options.category ?? 'unknown',
          ctx.guild.t['general.categories.${options.category ?? 'unknown'}'] as String? ?? options.category ?? ctx.guild.t.general.categories.unknown,
        );

        final permissions = translatePermissions(options.permissions!, ctx.guild.t);

        final clientPermissions = translatePermissions(options.clientPermissions!, ctx.guild.t);

        final embed = EmbedBuilder(
          title: 'Help panel',
          color: DiscordColor(0xFFA500),
          footer: EmbedFooterBuilder(
            text: 'Kiwii',
            iconUrl: (await ctx.client.user.get()).avatar.url,
          ),
          description: 'Find more information about this command below.',
          fields: [
            EmbedFieldBuilder(
              name: 'Name',
              value: command.localizedNames?[reverseMap(discordLocaleToAppLocale)[ctx.guild.t.$meta.locale]] ?? command.fullName,
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: 'Category',
              value: category,
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: 'Usage',
              value: usage != null ? inlineCode('${ctx.realPrefix}${command.fullName} $usage') : 'No usage provided',
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: 'Permissions',
              value: permissions.map((p) => inlineCode(p)).join(', '),
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: "Bot's permissions",
              value: clientPermissions.map((p) => inlineCode(p)).join(', '),
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: 'Description',
              value: description,
              isInline: true,
            ),
            EmbedFieldBuilder(
              name: 'Examples',
              value: examples.isNotEmpty
                  ? examples.map((e) => '- ${inlineCode('${ctx.realPrefix}${command.fullName} ${e.command}')} ${e.description}').join('\n')
                  : 'No examples provided',
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
);
