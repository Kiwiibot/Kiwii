import 'dart:async';

import 'package:dart_openai/dart_openai.dart';
import 'package:nyxx/nyxx.dart';

import '../src/models/errors/unproxied.dart';
import '../src/settings.dart';

const escapeChar = r'\';
const systemMessage = '''You are a friendly discord bot named Kiwii in a small personal Discod guild called Les Transcendantes.
Your developer is Rapougnac, the owner of the guild, and you were written in Dart using the Nyxx library. 
You should NOT PREFIX your messages with your username followed by a colon.
You can treat the username as the name of the author. However, you should not not prefix the messages you send with any username whatsoever (e.g. "Kiwii" or 
"Kiwii (Bot)"). 
You can use the emoji <:yang_adorable:1147202859654455296> to give members virtual pats when they feel down or ask for pets.
''';
const unproxiedMessages = <Snowflake>{};

class ChatPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    client.on<MessageCreateEvent>(
      (event) async {
        final message = event.message;
        if (message.author case User(isBot: true)) {
          if (message.webhookId == null) {
            return;
          }
        }

        if ((await message.channel.get()).type != ChannelType.guildText) {
          return;
        }

        if (!chatbotChannels.contains(message.channelId)) {
          return;
        }

        if (message.content.startsWith(escapeChar)) {
          return;
        }

        await message.channel.triggerTyping();
        final typingTimer = Timer(const Duration(seconds: 5), () async => await message.channel.triggerTyping());

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
            msgs.where((k) => !k.content.startsWith(escapeChar)).map<Future<OpenAIChatCompletionChoiceMessageModel>>(
              (msg) async {
                if (msg.author.id == msg.manager.client.user.id) {
                  return OpenAIChatCompletionChoiceMessageModel(
                    role: OpenAIChatMessageRole.assistant,
                    content: msg.content,
                  );
                }

                final member = await event.guild!.members.get(msg.author.id);

                final roles = await Future.wait(member.roles.map((role) => role.get().then((r) => r.name)));

                return OpenAIChatCompletionChoiceMessageModel(
                  role: OpenAIChatMessageRole.user,
                  content: '${member.nick ?? msg.author.username}${roles.isNotEmpty ? ' (${roles.join(', ')})' : ''}: ${msg.content}',
                );
              },
            ),
          );

          if (unproxiedMessages.contains(message.id)) {
            unproxiedMessages.remove(message.id);
            throw UnproxiedMessageError();
          }

          final response = await OpenAI.instance.chat.create(model: 'gpt-3.5-turbo', messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system,
              content: systemMessage,
            ),
            ...context,
          ]);

          final content = response.choices.first.message.content;

          if (content.isNotEmpty) {
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

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    final client = await super.doConnect(apiOptions, clientOptions, connect);

    OpenAI.apiKey = 'what';
    OpenAI.baseUrl = 'http://localhost:8080';

    return client;
  }
}
