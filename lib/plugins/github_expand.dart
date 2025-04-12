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

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../utils/regexes.dart';
import 'base.dart';

final indentationRegex = RegExp(r'\s+');

final class GithubExpand extends BasePlugin {
  @override
  String get name => 'GithubExpand';

  late final Map<Snowflake, StreamSubscription<MessageCreateEvent>> _subscriptions = {};

  @override
  String helpText(self) => '''
A module to display lines when a github link has been detected.
''';

  @override
  Future<void> onLoad(self, {required guild}) async {
    _subscriptions[guild.id] = self.on<MessageCreateEvent>((event) async {
      final message = event.message;

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

        var res = response.body.split('\n').sublist(start - 1, end ?? start);
        if (indentationRegex.hasMatch(res.first)) {
          final match = indentationRegex.firstMatch(res.first);
          final indentation = match!.group(0)!;
          res = res.map((s) => s.replaceFirst(indentation, '')).toList();
        }

        final content = res.join('\n');

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

  @override
  Future<void> onUnload(self, {required guild}) async {
    await _subscriptions[guild.id]?.cancel();
  }
}
