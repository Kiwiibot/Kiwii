import 'package:nyxx/nyxx.dart';

import '../../../services/notifier/subscription.dart';
import 'repositories.dart';

final class NotifierRepository extends Repository {
  NotifierRepository({required super.connection});

  Future<int?> addNotificationChannel({
    required Snowflake guildId,
    required SubscriptionType serviceType,
    required Snowflake channelId,
    String? webhookUrl,
  }) async {
    final result = await connection.execute(
      r'''
      INSERT INTO notification_channels (guild_id, service_type, channel_id, webhook_url)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (guild_id, service_type, channel_id) DO UPDATE SET webhook_url = $4 RETURNING id;
      ''',
      parameters: [guildId.value, serviceType.index, channelId.value, webhookUrl],
    );

    return result.isNotEmpty ? result.first[0] as int : null;
  }

  Future<List<Map<String, dynamic>>> getNotificationChannels(Snowflake guildId) async {
    final result = await connection.execute(r'SELECT * FROM notification_channels WHERE guild_id = $1 AND enabled = TRUE', parameters: [guildId.value]);
    return result.map((r) => r.toColumnMap()).toList();
  }

  Future<int?> addServiceSubscription({required Snowflake notificationChannelId, required String serviceId}) async {
    final result = await connection.execute(
      r'''
      INSERT INTO service_subscriptions (notification_channel_id, service_id)
      VALUES ($1, $2)
      ON CONFLICT (notification_channel_id, service_id) DO NOTHING RETURNING id;
      ''',
      parameters: [notificationChannelId.value, serviceId],
    );

    return result.isNotEmpty ? result.first[0] as int : null;
  }

  Future<List<Map<String, dynamic>>> getActiveSubscriptions(SubscriptionType serviceType) async {
    final result = await connection.execute(
      r'''
      SELECT ss.*, nc.guild_id, nc.channel_id, nc.webhook_url
      FROM service_subscriptions ss
      INNER JOIN notification_channels nc ON ss.notification_channel_id = nc.id
      WHERE ss.enabled = TRUE AND nc.enabled = TRUE AND nc.service_type = $1;
      ''',
      parameters: [serviceType.index],
    );

    return result.map((r) => r.toColumnMap()).toList();
  }

  Future<void> updateSubscriptionStatus({required int subscriptionId, required DateTime lastChecked, String? latestItemId}) async {
    await connection.execute(
      r'''
      UPDATE service_subscriptions
      SET last_checked = $1, latest_item_id = $2
      WHERE id = $3;
      ''',
      parameters: [lastChecked, latestItemId, subscriptionId],
    );
  }

  Future<void> logNotification({
    required int subscriptionId,
    required String itemId,
    required String notificationMessage,
    required String status,
    String? errorMessage,
  }) async {
    await connection.execute(
      r'''
      INSERT INTO notification_logs (subscription_id, item_id, notification_message, status, error_message)
      VALUES ($1, $2, $3, $4, $5);
      ''',
      parameters: [subscriptionId, itemId, notificationMessage, status, errorMessage],
    );
  }

  Future<Map<String, dynamic>?> getDefaultNotificationTemplate(Snowflake guildId, SubscriptionType serviceType) async {
    final result = await connection.execute(
      r'''
      SELECT template_content FROM notification_templates
      WHERE guild_id = $1 AND service_type = $2 AND is_default = TRUE;
      ''',
      parameters: [guildId.value, serviceType.index],
    );
    if (result.isNotEmpty) {
      return {'template_content': result.first[0] as String};
    }
    return null;
  }

  Future<Map<String, dynamic>?> getNotificationTemplate(Snowflake guildId, SubscriptionType serviceType, String serviceId) async {
    final result = await connection.execute(
      r'''
      SELECT template_content FROM notification_templates
      WHERE guild_id = $1 AND service_type = $2 AND service_id = $3;
      ''',
      parameters: [guildId.value, serviceType.index, serviceId],
    );
    if (result.isNotEmpty) {
      return {'template_content': result.first[0] as String};
    }
    return null;
  }
}
