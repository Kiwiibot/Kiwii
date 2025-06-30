import 'dart:async';

import 'package:nyxx/nyxx.dart';

import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../kiwii.dart';
import '../services/notifier/notifier.dart';
import '../services/notifier/reddit_notifier.dart';
import '../services/notifier/subscription.dart';
import '../services/notifier/youtube_notifier.dart';
import 'base.dart';

final class NotificationsPlugin extends BasePlugin {
  @override
  String get name => 'Notifications';

  late final Map<Guild, List<Notifier>> _notifiers = {};

  @override
  String helpText(self) => '''
A plugin to setup notifications for various services, including Reddit, BlueSky, Twitch and YouTube.
''';

  @override
  Future<void> onLoad(NyxxGateway self, {required Guild guild}) async {
    for (final sub in SubscriptionType.values) {
      final notifier = switch (sub) {
        SubscriptionType.youtube => YoutubeNotifier(guild: guild),
        SubscriptionType.reddit => RedditNotifier(guild: guild),
        _ => null,
      };
      if (notifier == null) continue;
      (_notifiers[guild] ??= []).add(notifier);
      notifier.onNewItems.listen((data) async {
        final type = data['type'] as SubscriptionType;
        final discordChannelId = data['discordChannelId'] as Snowflake;
        final webhookUrl = data['webhookUrl'] as String?;
        final subscriptionId = data['subscriptionId'] as int;
        final guildId = data['guildId'] as Snowflake;
        final itemId = data['itemId'] as String;
        final serviceId = data['serviceId'] as String;
        final templateData =
            (await self.repositories.notifiers.getNotificationTemplate(guildId, type, serviceId)) ??
            (await self.repositories.notifiers.getDefaultNotificationTemplate(guildId, type));
        final template =
            templateData?['template_content'] ??
            switch (type) {
              SubscriptionType.youtube => 'New Video from **{creator.name}**\n{video.title}\n{video.link}',
              SubscriptionType.reddit => 'New Post in **r/{subreddit.name}**\n> [{post.title}]({post.media.url})\n<{post.link}>',
              _ => 'No template available for this subscription type.',
            };

        final notificationMessage = applyTemplate(template: template, subscriptionType: type, data: data['data']);

        try {
          await sendDiscordNotification(client: self, channelId: discordChannelId, message: notificationMessage, webhookUrl: webhookUrl);
          await self.repositories.notifiers.logNotification(
            subscriptionId: subscriptionId,
            itemId: itemId,
            notificationMessage: notificationMessage,
            status: 'sent',
          );
        } catch (e) {
          await self.repositories.notifiers.logNotification(
            subscriptionId: subscriptionId,
            itemId: itemId,
            notificationMessage: notificationMessage,
            status: 'failed_send',
            errorMessage: e.toString(),
          );
        }
      });

      await notifier.start();
    }
  }

  @override
  Future<void> onUnload(NyxxGateway self, {required Guild guild}) async {
    final notifiers = _notifiers[guild];
    if (notifiers != null) {
      for (final notifier in notifiers) {
        await notifier.stop();
      }
    }
    _notifiers.remove(guild);
  }
}

Future<Message> sendDiscordNotification({required NyxxGateway client, required Snowflake channelId, required String message, String? webhookUrl}) async {
  if (webhookUrl != null && webhookUrl.isNotEmpty) {
    final Uri uri = Uri.parse(webhookUrl);
    final List<String> pathSegments = uri.pathSegments;

    if (pathSegments.length >= 4 && pathSegments[pathSegments.length - 3] == 'webhooks') {
      final String webhookId = pathSegments[pathSegments.length - 2];
      final String webhookToken = pathSegments[pathSegments.length - 1];

      final webhook = await client.webhooks.get(Snowflake.parse(webhookId));
      return webhook.execute(MessageBuilder(content: message), token: webhookToken, wait: true) as Future<Message>;
    } else {
      final channel = await client.channels.get(channelId) as TextChannel;
      return channel.sendMessage(MessageBuilder(content: message));
    }
  }
  final channel = await client.channels.get(channelId) as TextChannel;

  return channel.sendMessage(MessageBuilder(content: message));
}

String applyTemplate({required String template, required SubscriptionType subscriptionType, required Map<String, dynamic> data}) => switch (subscriptionType) {
  SubscriptionType.youtube => template
      .replaceAll('{video.title}', data['title'])
      .replaceAll('{video.id}', data['videoId'])
      .replaceAll('{video.link}', data['url'])
      .replaceAll('{video.thumbnail}', data['thumbnailUrl'])
      .replaceAll('{video.uploaded.ago}', (data['publishedAt'] as DateTime).format(TimestampStyle.relativeTime))
      .replaceAll('{video.uploaded.at}', (data['publishedAt'] as DateTime).format(TimestampStyle.longDateTime))
      .replaceAll('{creator.name}', data['channelTitle']),
  SubscriptionType.reddit => template
      .replaceAll('{post.title}', data['title'])
      .replaceAll('{post.link}', data['url'])
      .replaceAll('{post.link.fix}', data['urlFix'])
      .replaceAll('{post.created.at}', (data['createdAt'] as DateTime).format(TimestampStyle.longDateTime))
      .replaceAll('{post.created.ago}', (data['createdAt'] as DateTime).format(TimestampStyle.relativeTime))
      .replaceAll('{post.media.url}', data['mediaUrl'] ?? '')
      .replaceAll('{post.text}', data['text'])
      .replaceAll('{subreddit.name}', data['subreddit'])
      .replaceAll('{author.name}', data['author']),

  _ => template,
};
