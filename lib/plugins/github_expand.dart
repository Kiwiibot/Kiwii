import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../utils/regexes.dart';

class GithubExpand extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    client.on<MessageCreateEvent>((event) async {
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
