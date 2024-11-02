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
import 'package:stdlibc/stdlibc.dart';

import '../../plugins/localization.dart';
import '../../utils/utils.dart';

final infoCommand = ChatCommand(
  'info',
  'Get information about the bot',
  id(
    'info',
    (ChatContext ctx) async {
      final info = sysinfo();
      final unameInfo = uname();

      final root = ctx.guild.t;
      final nA = root.general.nonAvailable;

      final embed = EmbedBuilder()
        ..title = 'Bot Information'
        ..addField(name: 'OS Name', value: unameInfo?.sysname ?? nA, isInline: true)
        ..addField(name: 'OS Release', value: unameInfo?.release ?? nA, isInline: true)
        ..addField(name: 'OS Version', value: unameInfo?.version ?? nA, isInline: true)
        ..addField(name: 'Machine', value: unameInfo?.machine ?? nA, isInline: true)
        ..addField(name: 'Uptime', value: '${info?.uptime ?? nA} seconds', isInline: true)
        ..addField(name: 'Total RAM', value: formatBytes(info!.totalram), isInline: true)
        ..color = DiscordColor(0x00FF00);

      await ctx.respond(MessageBuilder(embeds: [embed]));
    },
  ),
);
