import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:xml/xml.dart';

import '../../utils/extensions.dart';
import '../../utils/extensions/iterable.dart';
import 'notifier.dart';
import 'subscription.dart';

final _fetcherClient = http.Client();

final class YoutubeNotifier extends Notifier {
  final StreamController<Map<String, dynamic>> _newVideosController = StreamController.broadcast();

  YoutubeNotifier({required super.guild});

  @override
  Stream<Map<String, dynamic>> get onNewItems => _newVideosController.stream;

  Timer? _pollingTimer;

  static const Duration _pollingInterval = Duration(minutes: 5);

  @override
  Future<void> start() async {
    await checkYoutubeNotifications();

    _pollingTimer = Timer.periodic(_pollingInterval, (_) => checkYoutubeNotifications());
  }

  @override
  Future<void> stop() async {
    _pollingTimer?.cancel();

    await _newVideosController.close();
  }

  Future<void> checkYoutubeNotifications() async {
    final subscriptions = await guild.manager.client.repositories.notifiers.getActiveSubscriptions(SubscriptionType.youtube);

    for (final subscription in subscriptions) {
      final String channelId = subscription['service_id'] as String;
      final String? lastProcessedItemId = subscription['latest_item_id'] as String?;
      final int subscriptionId = subscription['id'] as int;
      final int discordChannelId = subscription['channel_id'] as int;
      final String? webhookUrl = subscription['webhook_url'] as String?;
      final int guildId = subscription['guild_id'] as int;

      final fetchedVideos = await fetchLatestVideosFromFeed(channelId);

      if (fetchedVideos == null) {
        return;
      }

      List<Map<String, dynamic>> newVideos = [];
      if (lastProcessedItemId != null) {
        final lastProcessedIndex = fetchedVideos.indexWhere((video) => video['id'] == lastProcessedItemId);
        if (lastProcessedIndex != -1) {
          newVideos = fetchedVideos.sublist(0, lastProcessedIndex);
        } else {
          if (fetchedVideos.isNotEmpty) {
            newVideos = [fetchedVideos.first];
          }
        }
      } else {
        if (fetchedVideos.isNotEmpty) {
          if ((fetchedVideos.first['publishedAt'] as DateTime).isAfter(DateTime.now().subtract(Duration(days: 1)))) {
            newVideos = [fetchedVideos.first];
          }
        }
      }

      if (newVideos.isNotEmpty) {
        newVideos.sort((a, b) => (a['publishedAt'] as DateTime).compareTo(b['publishedAt'] as DateTime));

        String? newLatestItemId;

        for (var video in newVideos) {
          final String videoId = video['id'] as String;
          final String videoTitle = video['title'] as String;
          final String channelTitle = video['channelTitle'] as String;
          final String videoUrl = video['url'] as String;
          final DateTime publishedAt = video['publishedAt'] as DateTime;
          final String thumbnailUrl = video['thumbnailUrl'] as String;

          _newVideosController.add({
            'type': SubscriptionType.youtube,
            'guildId': Snowflake.parse(guildId),
            'channelRecordId': subscription['notification_channel_id'] as int,
            'discordChannelId': Snowflake.parse(discordChannelId),
            'webhookUrl': webhookUrl,
            'subscriptionId': subscriptionId,
            'itemId': videoId,
            'serviceId': channelId,
            'data': {
              'videoId': videoId,
              'title': videoTitle,
              'channelTitle': channelTitle,
              'url': videoUrl,
              'publishedAt': publishedAt,
              'thumbnailUrl': thumbnailUrl,
            },
          });

          newLatestItemId = videoId;
        }
        if (newLatestItemId != null) {
          await guild.manager.client.repositories.notifiers.updateSubscriptionStatus(
            subscriptionId: subscriptionId,
            lastChecked: DateTime.now(),
            latestItemId: newLatestItemId,
          );
        }
      } else {
        await guild.manager.client.repositories.notifiers.updateSubscriptionStatus(
          subscriptionId: subscriptionId,
          lastChecked: DateTime.now(),
          latestItemId: lastProcessedItemId,
        );
      }
    }
  }
}

Future<List<Map<String, dynamic>>?> fetchLatestVideosFromFeed(String channelId) async {
  final feedUrl = 'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId';

  final response = await _fetcherClient.get(Uri.parse(feedUrl));

  if (response.statusCode == 200) {
    final document = XmlDocument.parse(response.body);

    final videos = <Map<String, dynamic>>[];

    for (final entry in document.findAllElements('entry')) {
      final videoIdElement = entry.findAllElements('videoId', namespace: 'http://www.youtube.com/xml/schemas/2015').firstOrNull;
      final titleElement = entry.findAllElements('title').firstOrNull;
      final publishedElement = entry.findAllElements('published').firstOrNull;
      final authorNameElement = entry.findAllElements('author').firstOrNull?.findAllElements('name').firstOrNull;
      final thumbnailLinkElement = entry.findAllElements('thumbnail', namespace: 'http://search.yahoo.com/mrss/').firstOrNull;
      final linkElement = entry.findAllElements('link').firstWhereOrNull((e) => e.getAttribute('rel') == 'alternate');

      if (videoIdElement != null && titleElement != null && publishedElement != null && linkElement != null) {
        final String videoId = videoIdElement.innerText;
        final String videoTitle = titleElement.innerText;
        final DateTime publishedAt = DateTime.parse(publishedElement.innerText);
        final String videoUrl = linkElement.getAttribute('href') ?? 'https://www.youtube.com/watch?v=$videoId'; // Fallback URL
        final String channelTitle = authorNameElement?.innerText ?? 'Unknown Channel';
        final String thumbnailUrl = thumbnailLinkElement?.getAttribute('url') ?? 'https://i4.ytimg.com/vi/$videoId/hqdefault.jpg';

        videos.add({
          'id': videoId,
          'title': videoTitle,
          'publishedAt': publishedAt,
          'channelTitle': channelTitle,
          'url': videoUrl,
          'thumbnailUrl': thumbnailUrl,
        });
      }
    }
    return videos;
  }

  return null;
}
