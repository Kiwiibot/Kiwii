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

import '../../plugins/localization.dart';
import '../../src/checks/checks.dart';
import '../../src/command.dart';
import '../../src/moderation/utils/generate.dart';
import '../../utils/utils.dart';

Future<void> lookupCommandFunc(CommandContext ctx, Member member, User user) async {
  final embed = cutEmbed(
    await generateHistory((member: member, user: user), ctx.guild!.id, ctx.guild.t, HistoryType.case_),
  );

  await ctx.respond(MessageBuilder(embeds: [embed]), level: ResponseLevel.hint);
}

final _permissions = Permissions.manageMessages | Permissions.viewChannel | Permissions.sendMessages;
final _clientPermissions = Permissions.manageMessages | Permissions.viewChannel | Permissions.sendMessages;

final lookupCommand = ChatCommand(
  'lookup',
  'Lookup the moderation history of a user.',
  id(
    'lookup',
    (ChatContext ctx, Member member) async {
      await lookupCommandFunc(ctx, member, await ctx.client.users.get(member.id));
    },
  ),
  checks: [
    GuildCheck.all(),
    BasePermissionsCheck(_permissions),
    SelfPermissionsCheck(_clientPermissions),
  ],
  options: KiwiiCommandOptions(
    category: 'moderation',
    usage: 'lookup [member]',
    examples: [
      (command: 'lookup @user', description: 'Lookup the moderation history of @user.'),
    ],
    permissions: _permissions,
    clientPermissions: _clientPermissions
  )
);

final userLookupCommand = UserCommand(
  'Lookup',
  id(
    'user-lookup',
    (UserContext ctx) async {
      final member = await ctx.guild!.members.get(ctx.targetUser.id);

      await lookupCommandFunc(ctx, member, ctx.targetUser);
    },
  ),
  checks: [
    GuildCheck.all(),
    BasePermissionsCheck(_permissions),
    SelfPermissionsCheck(_clientPermissions),
  ],
);
