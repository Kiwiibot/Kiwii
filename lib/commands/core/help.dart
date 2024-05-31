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

final helpCommand = ChatCommand(
  'help',
  'Help command',
  id('help', (ChatContext ctx, [ChatCommand? command]) async {
    if (command == null) {
      final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
      final embed = EmbedBuilder(fields: [])
        ..title = 'Help'
        ..description = 'Use `${ctx is MessageChatContext ? ctx.prefix : '/'}help <command>` to get more information about a command.'
        ..color = DiscordColor(0x00ff00)
        ..footer = EmbedFooterBuilder(
          text: 'Kiwii',
          iconUrl: (await ctx.client.user.get()).avatar.url,
        );

      for (final command in commands) {
        embed.fields!.add(EmbedFieldBuilder(
          name: command.fullName,
          value: command.description,
          isInline: false,
        ));
      }

      await ctx.respond(MessageBuilder(embeds: [embed]));
      return;
    }
    final embed = EmbedBuilder(fields: [])
      ..title = command.fullName
      ..description = command.description
      ..color = DiscordColor.parseHexString('#00ff00')
      ..footer = EmbedFooterBuilder(
        text: 'Kiwii',
        iconUrl: (await ctx.client.user.get()).avatar.url,
      );

    if (command.children.isNotEmpty) {
      embed.fields!.add(EmbedFieldBuilder(
        name: 'Subcommands',
        value: command.children.map((e) => e.fullName).join(', '),
        isInline: false,
      ));
    }
    await ctx.respond(MessageBuilder(embeds: [embed]));
    return;
  }),
);
