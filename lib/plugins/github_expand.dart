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

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../database.dart';
import '../utils/regexes.dart';

class GithubExpand extends NyxxPlugin<NyxxGateway> {
  @override
  String get name => 'GithubExpand';

  @override
  Future<void> afterConnect(client) async {
    final db = GetIt.I.get<AppDatabase>();
    client.on<MessageCreateEvent>((event) async {
      final message = event.message;
      final guild = event.guild;

      final guildData = guild == null ? null : await db.getGuildOrNull(guild.id);

      if (guildData case final data? when !data.enabledModules.contains('github_expand')) {
        return;
      }

      if (!githubLink.hasMatch(message.content)) {
        return;
      }

      var codeblocks = <({String language, String content, String name})>[];

      for (final match in githubLink.allMatches(message.content)) {
        final [fullUrl!, repo, ref!, file, startStr!, ...rest] = match.groups([0, 1, 2, 3, 4, 5, if (match.groupCount > 5) 6]);

        final endStr = rest.isEmpty ? null : rest.first;

        final start = int.parse(startStr);
        final end = endStr == null || endStr.isEmpty ? null : int.parse(endStr);
        final name = '$repo@${ref.length == 40 ? ref.substring(0, 8) : ref} $file L$start${end != null ? '-$end' : ''}';
        final language = Uri.parse(fullUrl).path.split('.').lastOrNull ?? '';

        final response = await http.get(Uri.parse('https://raw.githubusercontent.com/$repo/$ref/$file'));

        if (response.statusCode != 200) {
          continue;
        }

        final content = response.body.split('\n').sublist(start - 1, end ?? start).join('\n');

        codeblocks.add((content: content, language: language, name: name));
      }

      codeblocks = codeblocks.where((c) => c.content.trim().isNotEmpty).toList();

      if (codeblocks.isNotEmpty) {
        await message.edit(MessageUpdateBuilder(suppressEmbeds: true));
        await message.sendReply(
          MessageBuilder(
            embeds: codeblocks
                .map(
                  (block) => EmbedBuilder(
                    description: codeBlock(block.content, block.language),
                    author: EmbedAuthorBuilder(name: block.name),
                    color: DiscordColor(0xa7f3d0),
                  ),
                )
                .toList(),
            allowedMentions: AllowedMentions(
              repliedUser: false,
              roles: [],
              users: [],
            ),
          ),
        );
      }
    });
  }
}
