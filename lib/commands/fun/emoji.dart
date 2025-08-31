import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';
import '../../src/models/emoji_metadata.dart';

final _emojiCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _emojiCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

final emojiCommand = ChatCommand(
  'emoji',
  'Get information about an emoji or combine two emojis together.',
  id('emoji', (ChatContext ctx, String emoji, [String? combined]) async {
    // if (emoji is GuildEmoji) {
    //   final url = emoji.image.url;

    //   final embed = EmbedBuilder(
    //     fields: [
    //       EmbedFieldBuilder(
    //         name: ':${emoji.name}:',
    //         value: '-# ID: ${emoji.id}\n-# Created: ${emoji.id.timestamp.format(TimestampStyle.relativeTime)}',
    //         isInline: true,
    //       ),
    //     ],
    //     image: EmbedImageBuilder(url: url),
    //   );

    //   await ctx.respond(MessageBuilder(embeds: [embed]));
    //   return;
    // }

    if (combined == null) {
      final emojiDefinition = (await getEmojiDefinitions()).where((e) => e.surrogates == emoji).firstOrNull;

      if (emojiDefinition == null) {
        await ctx.respond(MessageBuilder(content: 'Emoji not found.'));
        return;
      }

      final embed = EmbedBuilder(
        fields: [
          EmbedFieldBuilder(
            name: emojiDefinition.primaryName,
            value:
                '-# Codepoints: `${emojiDefinition.surrogates.runes.map((r) => 'U+${r.toRadixString(16)}'.toUpperCase()).join(' ')}`\n-# Surrogates: `${emojiDefinition.surrogates}`\n-# Category: ${emojiDefinition.category}\n-# Alternate names: ${emojiDefinition.names.join(', ')}',
            isInline: true,
          ),
        ],
      );

      await ctx.respond(MessageBuilder(embeds: [embed]));
      return;
    }

    final emojiData = await getEmojiData(emoji);

    final combination = emojiData.combinations[combined.runes.first.toRadixString(16)]?.where((e) => e.isLatest).firstOrNull;
    if (combination == null) {
      await ctx.respond(MessageBuilder(content: 'Unsupported emoji combination: `$emoji + $combined`'));
      return;
    }

    final embed = EmbedBuilder(image: EmbedImageBuilder(url: Uri.parse(combination.gStaticUrl)));

    await ctx.respond(MessageBuilder(embeds: [embed]));
    return;
  }),
  checks: [BasePermissionsCheck(_emojiCommandPermissions), BaseSelfPermissionsCheck(_emojiCommandClientPermissions)],
  options: KiwiiCommandOptions(
    permissions: _emojiCommandPermissions,
    clientPermissions: _emojiCommandClientPermissions,
    usage: '<emoji> [combined]',
    examples: [(command: '🫂 🤫', description: 'Combines the two emojis')],
  ),
);
