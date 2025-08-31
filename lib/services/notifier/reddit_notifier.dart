import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:nyxx/nyxx.dart';

import '../../src/settings.dart';
import '../../utils/extensions.dart';
import 'notifier.dart';
import 'subscription.dart';

final _fetcherClient = http.Client();

final class RedditNotifier extends Notifier {
  final StreamController<Map<String, dynamic>> _newPostsController = StreamController.broadcast();

  final logger = Logger('Kiwii.RedditNotifier');

  RedditNotifier({required super.guild});

  @override
  Stream<Map<String, dynamic>> get onNewItems => _newPostsController.stream;

  Timer? _pollingTimer;

  static const Duration _pollingInterval = Duration(minutes: 5);

  @override
  Future<void> start() async {
    await checkRedditNotifications();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => checkRedditNotifications());
  }

  @override
  Future<void> stop() async {
    _pollingTimer?.cancel();
    await _newPostsController.close();
  }

  Future<void> checkRedditNotifications() async {
    final subscriptions = await guild.manager.client.repositories.notifiers.getActiveSubscriptions(SubscriptionType.reddit);

    for (final subscription in subscriptions) {
      final String subredditName = subscription['service_id'] as String;
      final String? lastProcessedPostId = subscription['latest_item_id'] as String?;
      final int subscriptionId = subscription['id'] as int;
      final int discordChannelId = subscription['channel_id'] as int;
      final String? webhookUrl = subscription['webhook_url'] as String?;
      final int guildId = subscription['guild_id'] as int;

      final fetchedPosts = await fetchLatestPostsFromSubreddit(subredditName);

      if (fetchedPosts == null) {
        return;
      }

      List<Map<String, dynamic>> newPosts = [];
      if (lastProcessedPostId != null) {
        final lastProcessedIndex = fetchedPosts.indexWhere((post) => post['id'] == lastProcessedPostId);
        if (lastProcessedIndex != -1) {
          newPosts = fetchedPosts.sublist(0, lastProcessedIndex);
        } else {
          if (fetchedPosts.isNotEmpty) {
            newPosts = [fetchedPosts.first];
          }
        }
      } else {
        if (fetchedPosts.isNotEmpty) {
          if ((fetchedPosts.first['createdAt'] as DateTime).isAfter(DateTime.now().subtract(Duration(days: 1)))) {
            newPosts = [fetchedPosts.first];
          }
        }
      }

      if (newPosts.isNotEmpty) {
        newPosts.sort((a, b) => (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));

        String? newLatestPostId;

        for (var post in newPosts) {
          final String postId = post['id'] as String;
          final String postTitle = post['title'] as String;
          final String postUrl = 'https://www.reddit.com/r/$subredditName/comments/$postId/';
          final createdAt = post['createdAt'] as DateTime;
          final String? mediaUrl = post['mediaUrl'] as String?;
          final String author = post['author'] as String;
          final String? text = post['text'] as String?;

          _newPostsController.add({
            'type': SubscriptionType.reddit,
            'guildId': Snowflake.parse(guildId),
            'channelRecordId': subscription['notification_channel_id'] as int,
            'discordChannelId': Snowflake.parse(discordChannelId),
            'webhookUrl': webhookUrl,
            'subscriptionId': subscriptionId,
            'itemId': postId,
            'serviceId': subredditName,
            'data': {
              'postId': postId,
              'title': postTitle,
              'url': postUrl,
              'urlFix': Uri.parse(postUrl).replace(host: 'rxddit.com').toString(),
              'createdAt': createdAt,
              'mediaUrl': mediaUrl,
              'author': author,
              'text': text,
              'subreddit': subredditName,
            },
          });

          newLatestPostId = postId;
        }
        if (newLatestPostId != null) {
          await guild.manager.client.repositories.notifiers.updateSubscriptionStatus(
            subscriptionId: subscriptionId,
            lastChecked: DateTime.now(),
            latestItemId: newLatestPostId,
          );
        }
      } else {
        await guild.manager.client.repositories.notifiers.updateSubscriptionStatus(
          subscriptionId: subscriptionId,
          lastChecked: DateTime.now(),
          latestItemId: lastProcessedPostId,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>?> fetchLatestPostsFromSubreddit(String subredditName) async {
    final url = 'https://old.reddit.com/r/$subredditName/new.json';

    final response = await _fetcherClient.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:139.0) Gecko/20100101 Firefox/139.0', 'Accept': 'application/json', 'Cookie': redditCookie},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final posts = <Map<String, dynamic>>[];

      for (final post in data['data']['children']) {
        if (post['data']['stickied'] == true) {
          continue;
        }

        final postId = post['data']['id'];
        final postTitle = post['data']['title'];
        final createdUtc = post['data']['created_utc'];
        final url = post['data']['url'];

        final String author = post['data']['author'] as String;
        final String text = post['data']['selftext'] as String;
        final String? mediaUrl =
            post['data']['is_video']
                ? await (() async {
                  final response = await http.get(Uri.parse('https://www.reddit.com/${post['permalink']}'));
                  final s = response.body;
                  final i = s.indexOf('packaged-media-json');

                  if (i != -1) {
                    final j = s.indexOf('="', i);
                    if (j != -1) {
                      final k = s.indexOf('}"', j);
                      final rawJson = s
                          .substring(j + 2, k + 1)
                          .replaceAll('&quot;', '"')
                          .replaceAll('&apos;', "'")
                          .replaceAll('&lt;', '<')
                          .replaceAll('&gt', '>')
                          .replaceAll('&amp;', '&');
                      final json = jsonDecode(rawJson);
                      final videos = json['playbackMp4s']?['permutations'];

                      return (videos as List).lastOrNull?['source']?['url'];
                    }
                  }

                  return null;
                })()
                : post['data']['url_overridden_by_dest'];

        posts.add({
          'id': postId,
          'title': postTitle,
          'createdAt': DateTime.fromMillisecondsSinceEpoch((createdUtc as num).toInt() * 1000),
          'url': url,
          'author': author,
          'text': text,
          'mediaUrl': mediaUrl,
        });
      }

      return posts;
    } else {
      logger.warning('Failed to fetch posts from $url Response code: ${response.statusCode}');
      return null;
    }
  }
}
