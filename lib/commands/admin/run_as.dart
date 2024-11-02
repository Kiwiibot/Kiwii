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

final runAsCommand = ChatCommand(
  'runas',
  'Run a command as another user',
  id(
    'runas',
    (MessageChatContext ctx, User who, ChatCommand command) async {
      if (command.options.type == CommandType.slashOnly) {
        return ctx.send('Cannot run slash commands with runas');
      }

      final member = await ctx.guild?.members.get(who.id);
      final rawArguments = ctx.rawArguments.split(' ').skip(2 + command.fullName.split(' ').length).join(' ');
      final newCtx = MessageChatContext(
        message: ctx.message,
        prefix: ctx.prefix,
        rawArguments: rawArguments,
        command: command,
        user: who,
        member: member,
        guild: ctx.guild,
        channel: ctx.channel,
        commands: ctx.commands,
        client: ctx.client,
      );

      await command.invoke(newCtx);
    },
  ),
  options: KiwiiCommandOptions(
    type: CommandType.textOnly,
    category: 'admin',
    usage: '{prefix}runas <user> <command> [arguments]',
  ),
  checks: [
    BasePermissionsCheck(Permissions.administrator),
  ],
);
