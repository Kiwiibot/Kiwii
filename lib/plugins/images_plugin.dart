import 'dart:typed_data';

import 'package:nyxx/nyxx.dart';
import 'package:args/args.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
// ignore: implementation_imports
import 'package:nyxx_commands/src/converters/built_in.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../events/message_log.dart';
import '../kiwii.dart';
import '../src/converters/converters.dart';
import '../utils/api.dart';
import 'tag/tag.dart';

const requiresAtLeast1Image = {
  'petpet',
  'rotate3d',
  'anya-suki',
  'bounce',
  'always',
  'caption',
  'bocchi-draft',
  'jerk-off',
  'funny-mirror',
  'remote-control',
  'think-what',
  'bubble-tea',
  'bite',
};
const requiresAtLeast1Text = {'illegal', 'ace-attorney', 'blamed-mahiro'};

const allImages = {...requiresAtLeast1Image, ...requiresAtLeast1Text, 'eject'};

class ImagesPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  String get name => 'Images';

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    final client = await super.doConnect(apiOptions, clientOptions, connect);

    final commands = client.options.plugins.whereType<CommandsPlugin>().first;

    client.onMessageCreate.listen((event) async {
      final message = event.message;
      if (message.author is WebhookAuthor || (message.author is User && (message.author as User).isBot)) {
        return;
      }
      final view = StringView(message.content);

      // final untouchedView = view.copy();

      final prefix = await commands.prefix?.call(event);

      if (prefix == null) {
        return;
      }

      final matchedPrefix = view.skipPattern(prefix, caseInsensitive: commands.options.caseInsensitiveCommands);

      if (matchedPrefix == null) {
        return;
      }

      final author = message.author as User;

      final image = view.getWord();

      if (!allImages.contains(image)) {
        return;
      }

      final ctx = ContextBaseWithMessage(
        message: message,
        rawMessage: {},
        channel: await message.channel.get() as TextChannel,
        client: client,
        commands: commands,
        guild: await event.guild?.get(),
        member: await event.member?.get(),
        user: message.author as User,
      );

      final arg = view.eof ? null : await convertAnyToPrimitive(view, ctx);

      if (requiresAtLeast1Text.contains(image) && arg is! String) {
        await ctx.channel.sendMessage(MessageBuilder(content: '$image requires at least 1 text'));
        return;
      }
      final url = switch (arg) {
        User(:final avatar) => avatar.get(size: 4096),
        _ => switch (message) {
          Message(:final attachments, :final referencedMessage, :final embeds, :final stickers, :final content) =>
            referencedMessage?.attachments.firstOrNull?.url ??
                referencedMessage?.embeds.where((e) => e.image != null).firstOrNull?.image?.url ??
                (switch (guildEmojiRegex.firstMatch(referencedMessage?.content ?? '')) {
                  final match? => Uri(host: 'cdn.discordapp.com', path: '/emojis/${match[3]}.${match[1]?.isNotEmpty == true ? 'gif' : 'png'}', scheme: 'https'),
                  _ => null,
                }) ??
                (switch (referencedMessage?.stickers.firstOrNull) {
                  final sticker? => Uri(
                    scheme: 'https',
                    host: 'cdn.discordapp.com',
                    path: '/stickers/${sticker.id}.${sticker.formatType == StickerFormatType.gif ? 'gif' : 'png'}',
                  ),
                  _ => null,
                }) ??
                attachments.firstOrNull?.url ??
                embeds.where((e) => e.image != null).firstOrNull?.image?.url ??
                (switch (guildEmojiRegex.firstMatch(content)) {
                  final match? => Uri(host: 'cdn.discordapp.com', path: '/emojis/${match[3]}.${match[1]?.isNotEmpty == true ? 'gif' : 'png'}', scheme: 'https'),
                  _ => null,
                }) ??
                (switch (stickers.firstOrNull) {
                  final sticker? => Uri(
                    scheme: 'https',
                    host: 'cdn.discordapp.com',
                    path: '/stickers/${sticker.id}.${sticker.formatType == StickerFormatType.gif ? 'gif' : 'png'}',
                  ),
                  _ => null,
                }) ??
                referencedMessage?.author.avatar?.get(size: 4096) ??
                author.avatar.get(size: 4096),
        },
      };

      // if (requiresAtLeast1Image.contains(image)) {
      //   await ctx.channel.sendMessage(MessageBuilder(content: '$image requires at least 1 image'));
      //   return;
      // }

      final (name, res) =
          await switch (image) {
            'always' => () async {
              final mode =
                  arg is String
                      ? arg
                      : view.eof
                      ? null
                      : await (stringConverter.convert(view, ctx));
              final (ext, r) = await apiClient.always(url, mode: mode);

              return ('always.$ext', r);
            },
            'bite' => () async {
              final (_, r) = await apiClient.bite(url);

              return ('bite.gif', r);
            },
            'blamed-mahiro' => () async {
              final text =
                  arg is String
                      ? arg
                      : view.eof
                      ? null
                      : await (stringConverter.convert(view, ctx));
              final (_, r) = await apiClient.blamedMahiro(text!);

              return ('blamed-mahiro.gif', r);
            },
            'bocchi-draft' => () async {
              final (_, r) = await apiClient.bocchiDraft(url);

              return ('bocchi-draft.gif', r);
            },
            'jerk-off' => () async {
              final (_, r) = await apiClient.jerkOff(url);

              return ('jerk-off.gif', r);
            },
            'funny-mirror' => () async {
              final (ext, r) = await apiClient.funnyMirror(url);

              return ('funny-mirror.$ext', r);
            },
            'remote-control' => () async {
              final (_, r) = await apiClient.remoteControl(url);

              return ('remote-control.gif', r);
            },
            'think-what' => () async {
              final (ext, r) = await apiClient.thinkWhat(url);

              return ('think-what.$ext', r);
            },
            'bubble-tea' => () async {
              final pos =
                  arg is String
                      ? arg
                      : view.eof
                      ? null
                      : view.getQuotedWord();
              final (ext, r) = await apiClient.bubbleTea(url, position: pos);

              return ('bubble-tea.$ext', r);
            },
            'petpet' => () async {
              final circle =
                  arg is bool
                      ? arg
                      : view.eof
                      ? null
                      : await (boolConverter.convert(view, ctx));

              final (_, r) = await apiClient.petpet(url, circle: circle ?? false);

              return ('petpet.gif', r);
            },
            'rotate3d' => () async {
              final (_, r) = await apiClient.rotate3d(url);

              return ('rotate3d.gif', r);
            },
            'anya-suki' => () async {
              final text =
                  arg is String
                      ? arg
                      : view.eof
                      ? null
                      : await (stringConverter.convert(view, ctx));

              final (mime, r) = await apiClient.anyaSuki(url, text);

              return ('anya-suki.$mime', r);
            },
            'ace-attorney' => () async {
              final character = view.eof ? null : await stringConverter.convert(view, ctx);
              final (_, r) = await apiClient.aceAttorney(arg as String, character: character?.toLowerCase());

              return ('ace-attorney.png', r);
            },
            'bounce' => () async {
              final (_, r) = await apiClient.bounce(url);
              return ('bounce.gif', r);
            },
            'eject' => () async {
              final text =
                  arg is String
                      ? arg
                      : arg is User
                      ? arg.tag
                      : (view.eof ? author.tag : view.getQuotedWord());
              final seed = arg is User ? arg.id : (view.eof ? author.id : null);
              final (_, r) = await apiClient.eject(url, text, seed: seed?.toString());

              return ('eject.gif', r);
            },
            'illegal' => () async {
              final (_, r) = await apiClient.illegal(arg as String);

              return ('illegal.gif', r);
            },
            'caption' => () async {
              final text = switch (arg) {
                final String val => val,
                _ => 'A Caption',
              };
              final font = view.eof ? null : view.getQuotedWord();
              final (ext, r) = await apiClient.caption(url, text, font: font);

              return ('caption.$ext', r);
            },
            _ => () async => ('', Uint8List.fromList([])),
          }();

      if (res.isEmpty) {
        return;
      }

      await ctx.channel.sendMessage(MessageBuilder(attachments: [AttachmentBuilder(data: res, fileName: name)]));
    });

    return client;
  }
}
