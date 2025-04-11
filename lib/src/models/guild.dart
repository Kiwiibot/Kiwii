import 'package:nyxx/nyxx.dart' hide Guild, Connection;
// ignore: implementation_imports
import 'package:nyxx/src/utils/parsing_helpers.dart';
import 'package:option/option.dart';
import '../../plugins/localization.dart';
import '../../translations.g.dart';

final class Guild {
  /// The id of this guild.
  final Snowflake guildId;

  /// The locale of this guild.
  final AppLocale locale;

  /// The auto mod threshold before deleting the message.
  final double autoModThreshold;

  /// A [List] of [Snowflake]s that keep track of report tags.
  final List<Snowflake> reportTypeTags;

  final List<Snowflake> reportStatusTags;

  final Snowflake? appealChannelId;

  final Snowflake? modLogChannelId;

  final Snowflake? reportChannelId;

  final List<Snowflake> logIgnoreChannels;

  final Snowflake? guildLogWebhookId;

  final List<String> enabledModules;

  const Guild({
    required this.appealChannelId,
    required this.autoModThreshold,
    required this.enabledModules,
    required this.guildId,
    this.guildLogWebhookId,
    required this.locale,
    required this.logIgnoreChannels,
    required this.modLogChannelId,
    required this.reportChannelId,
    required this.reportStatusTags,
    required this.reportTypeTags,
  });

  Guild copyWith({
    Snowflake? guildId,
    AppLocale? locale,
    double? autoModThreshold,
    List<Snowflake>? reportTypeTags,
    List<Snowflake>? reportStatusTags,
    Option<Snowflake?> appealChannelId = const None(),
    Option<Snowflake?> modLogChannelId = const None(),
    Option<Snowflake?> reportChannelId = const None(),
    List<Snowflake>? logIgnoreChannels,
    Option<Snowflake?> guildLogWebhookId = const None(),
    List<String>? enabledModules,
  }) => Guild(
    appealChannelId: appealChannelId.unwrapOr(this.appealChannelId),
    autoModThreshold: autoModThreshold ?? this.autoModThreshold,
    enabledModules: enabledModules ?? this.enabledModules,
    guildId: guildId ?? this.guildId,
    guildLogWebhookId: guildLogWebhookId.unwrapOr(this.guildLogWebhookId),
    locale: locale ?? this.locale,
    logIgnoreChannels: logIgnoreChannels ?? this.logIgnoreChannels,
    modLogChannelId: modLogChannelId.unwrapOr(this.modLogChannelId),
    reportChannelId: reportChannelId.unwrapOr(this.reportChannelId),
    reportStatusTags: reportStatusTags ?? this.reportStatusTags,
    reportTypeTags: reportTypeTags ?? this.reportTypeTags,
  );

  static Guild fromRow(Map<String, Object?> row) {
    final guildId = Snowflake.parse(row['id']!);

    return Guild(
      appealChannelId: maybeParse(row['appeal_channel_id'], Snowflake.parse),
      autoModThreshold: row['auto_mod_threshold'] as double,
      enabledModules: (row['enabled_modules'] as List).cast<String>().toList(),
      guildId: guildId,
      guildLogWebhookId: maybeParse(row['guild_log_webhook_id'], Snowflake.parse),
      locale: convertLocale(row['locale'] as String)!,
      logIgnoreChannels: parseMany(row['log_ignore_channels'] as List, Snowflake.parse),
      modLogChannelId: maybeParse(row['mod_log_channel_id'], Snowflake.parse),
      reportChannelId: maybeParse(row['report_channel_id'], Snowflake.parse),
      reportStatusTags: parseMany(row['report_status_tags'] as List, Snowflake.parse),
      reportTypeTags: parseMany(row['report_type_tags'] as List, Snowflake.parse),
    );
  }
}

final class EditableGuild {
  /// The id of this guild.
  final Snowflake guildId;

  /// The locale of this guild.
  final AppLocale? locale;

  /// The auto mod threshold before deleting the message.
  final double? autoModThreshold;

  /// A [List] of [Snowflake]s that keep track of report tags.
  final List<Snowflake>? reportTypeTags;

  final List<Snowflake>? reportStatusTags;

  final Option<Snowflake?>? appealChannelId;

  final Option<Snowflake?>? modLogChannelId;

  final Option<Snowflake?>? reportChannelId;

  final List<Snowflake>? logIgnoreChannels;

  final Option<Snowflake?>? guildLogWebhookId;

  final List<String>? enabledModules;

  const EditableGuild({
    this.appealChannelId,
    this.autoModThreshold,
    this.enabledModules,
    required this.guildId,
    this.guildLogWebhookId,
    this.locale,
    this.logIgnoreChannels,
    this.modLogChannelId,
    this.reportChannelId,
    this.reportStatusTags,
    this.reportTypeTags,
  });

  EditableGuild copyWith({
    Snowflake? guildId,
    AppLocale? locale,
    double? autoModThreshold,
    List<Snowflake>? reportTypeTags,
    List<Snowflake>? reportStatusTags,
    Option<Snowflake?> appealChannelId = const None(),
    Option<Snowflake?> modLogChannelId = const None(),
    Option<Snowflake?> reportChannelId = const None(),
    Option<Snowflake?> guildLogWebhookId = const None(),
    List<Snowflake>? logIgnoreChannels,
    List<String>? enabledModules,
  }) => EditableGuild(
    guildId: guildId ?? this.guildId,
    appealChannelId: appealChannelId.isSome ? appealChannelId : this.appealChannelId,
    autoModThreshold: autoModThreshold ?? this.autoModThreshold,
    reportStatusTags: reportStatusTags ?? this.reportStatusTags,
    reportTypeTags: reportTypeTags ?? this.reportTypeTags,
    locale: locale ?? this.locale,
    enabledModules: enabledModules ?? this.enabledModules,
    guildLogWebhookId: guildLogWebhookId.isSome ? guildLogWebhookId : this.guildLogWebhookId,
    logIgnoreChannels: logIgnoreChannels ?? this.logIgnoreChannels,
    modLogChannelId: modLogChannelId.isSome ? modLogChannelId : this.modLogChannelId,
    reportChannelId: reportChannelId.isSome ? reportChannelId : this.reportChannelId,
  );
}
