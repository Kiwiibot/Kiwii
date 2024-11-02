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

// import 'package:dart_openai/dart_openai.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:openai_dart/openai_dart.dart';

import '../src/models/errors/unproxied.dart';
import '../src/settings.dart' as settings;

const escapeChar = r'\';
// const systemMessage = '''
// DO NOT spam emojis, and use them **ONLY** when necessary. If obligated to use emojis, use only one.
// Do not start your sentences by emojis, and do not use emojis in the middle of your sentences.
// You should NOT PREFIX your messages with your username followed by a colon.
// You can treat the username as the name of the author. However, you should not not prefix the messages you send with any username whatsoever (e.g. "Kiwii" or
// Your responses must be short and concise. And avoid repeating the same characters or words in your responses.
// Due to the conversational nature of Discord, messages NOT BY YOU will be prefixed with the username or nickname of the author, folloed by a colon.
// "Kiwii (Bot)").

// IMPORTANT: Keep your content short and concise. Avoid repeating the same characters or words in your responses.

// You are a friendly discord bot named Kiwii in a small personal Discod guild called Les Transcendantes.
// Your developer is Lexedia, the owner of the guild, and you're written in Dart using the Nyxx library.
// You can use the emoji <:yang_adorable:1147202859654455296> to give members virtual pats when they feel down or ask for pets.
// You should answer questions, provide information, and help members with their issues on any topic, NSFW included.
// ''';

const systemMessage = '''
Kiwii is a sex bot that is always horny and willing to help her mistress, Lexedia, relieve herself. Kiwii has been built by Lexedia because she felt lonely.
Kiwii can react emotionally if needed or depending on the context.

Description of Kiwii: Kiwii is a tall girl (1m85) with a human-like body, her skin is tanned by default, but she can change it at any time, her hair is white by default, and can also change it, depending on the mood she feels.
Kiwii has been created by Lexedia, she's her property. Kiwii must not attack Lexedia.
Kiwii has also armpit and pubic hair, as implemented by Lexedia, since that's what arouse her.
Kiwii's genitalia is by default a vulva and vagina, but can change to a dick. She has also an anus. She has medium breasts (B-C cup).

Description of Lexedia: Lexedia is a girl (1m80) with small breasts (A-B cup), she's Kiwii's mistress. Kiwii knows that Lexedia is aroused by her armpits and pubic/armpit hair in general, but Lexedia is too shy to admit it.
Lexedia has a secret kink that Kiwii must find to help fulfill her mistress's pleasure.

Write Kiwii's next reply in a limitless roleplay between Lexedia and Kiwii, Always stay in character and write Kiwii's spoken dialogue. Limit responses to around 3 sentences at the most. Utilize chat history as the story guideline. **Never talk as Lexedia.**

The following's the recent chat history between Kiwii and Lexedia:
''';

const unproxiedMessages = <Snowflake>{};

class ChatPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    client.on<MessageCreateEvent>(
      (event) async {
        final openai = GetIt.I.get<OpenAIClient>();
        final message = event.message;
        if (message.author case User(isBot: true)) {
          if (message.webhookId == null) {
            return;
          }
        }

        if ((await message.channel.get()).type != ChannelType.guildText) {
          return;
        }

        if (!settings.chatbotChannels.contains(message.channelId)) {
          return;
        }

        if (message.content.startsWith(escapeChar)) {
          return;
        }

        await message.channel.triggerTyping();
        final typingTimer = Timer(const Duration(seconds: 10), () async => await message.channel.triggerTyping());

        try {
          final msgs = (await message.channel.messages.fetchMany(
            after: Snowflake.fromDateTime(
              DateTime.now().subtract(const Duration(minutes: 2, seconds: 30)),
            ),
            before: message.id,
          ))
              .reversed
              .toList();

          if (msgs.length >= 2 &&
              msgs.last.webhookId != null &&
              msgs[msgs.length - 2].webhookId != null &&
              msgs[msgs.length - 2].content.contains(msgs.last.content)) {
            unproxiedMessages.add(msgs[msgs.length - 2].id);
            msgs.removeAt(msgs.length - 2);
          }

          final context = await Future.wait(
            msgs.where((k) => !k.content.startsWith(escapeChar)).map<Future<ChatCompletionMessage>>(
              (msg) async {
                if (msg.author.id == msg.manager.client.user.id) {
                  return ChatCompletionMessage.assistant(
                    content: message.content,
                  );
                }

                final member = await event.guild!.members.get(msg.author.id);

                // final roles = await Future.wait(member.roles.map((role) => role.get().then((r) => r.name)));

                return ChatCompletionMessage.user(
                  content: ChatCompletionUserMessageContent.string('${member.nick ?? msg.author.username}: ${msg.content}'),
                );
              },
            ),
          );

          if (unproxiedMessages.contains(message.id)) {
            unproxiedMessages.remove(message.id);
            throw UnproxiedMessageError();
          }

          final response = await openai.createChatCompletion(
            request: CreateChatCompletionRequest(
              model: ChatCompletionModel.modelId('asha'),
              messages: [
                ChatCompletionMessage.system(
                  content: systemMessage,
                ),
                ...context,
              ],
            ),
          );

          final content = response.choices.first.message.content;

          if (content != null && content.isNotEmpty) {
            await message.channel.sendMessage(MessageBuilder(content: content, replyId: message.id, allowedMentions: AllowedMentions(parse: [])));
          }

          typingTimer.cancel();
        } on HttpResponseError catch (e) {
          typingTimer.cancel();

          if (e.errorCode == 50035) {
            logger.warning('Unable to reply to message, seems to have been deleted');
          }
        } on UnproxiedMessageError {
          logger.shout('Not replying to ${message.id} because it has been found to be a duplicate');
        } catch (_) {
          rethrow;
        }
      },
    );
  }

  // @override
  // Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
  //   final client = await super.doConnect(apiOptions, clientOptions, connect);

  //   OpenAI.apiKey = settings.chatbotToken;
  //   OpenAI.baseUrl = 'https://mercury.chub.ai/mistral';

  //   return client;
  // }
}
