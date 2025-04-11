import 'package:nyxx/nyxx.dart' hide Connection, Guild;
import 'package:option/option.dart';

import '../guild.dart';
import 'repositories.dart';

final class GuildRepository extends Repository {
  final List<Guild> guilds = [];

  final logger = Logger('Kiwii.Repositories.GuildRepository');

  GuildRepository({required super.connection});

  Future<Guild> get(Snowflake guildId) async {
    final result = await connection.execute(r'SELECT * FROM guild_table WHERE id = $1;', parameters: [guildId.value]).then((r) => r.single);

    return Guild.fromRow(result.toColumnMap());
  }

  Future<Guild?> getOrNull(Snowflake guildId) async {
    final result = await connection.execute(r'SELECT * FROM guild_table WHERE id = $1;', parameters: [guildId.value]).then((r) => r.singleOrNull);

    if (result == null) {
      return null;
    }

    return Guild.fromRow(result.toColumnMap());
  }

  Future<Guild> create(EditableGuild guild) async {
    final entries = <String, Option<Object?>>{
      'id': Some<Snowflake>(guild.guildId),
      'locale': guild.locale != null ? Some('${guild.locale!.languageCode}-${guild.locale!.countryCode}') : const None(),
      'auto_mod_threshold': Option<double>.fromNullable(guild.autoModThreshold),
      'report_type_tags': guild.reportTypeTags == null ? const None() : Some(guild.reportTypeTags!.map((t) => t.value).toList()),
      'report_status_tag': guild.reportStatusTags == null ? const None() : Some(guild.reportStatusTags!.map((t) => t.value).toList()),
      'appeal_channel_id': guild.appealChannelId?.isSome == true ? guild.appealChannelId! : const None(),
      'mod_log_channel_id': guild.modLogChannelId?.isSome == true ? guild.modLogChannelId! : const None(),
      'report_channel_id': guild.reportChannelId?.isSome == true ? guild.reportChannelId! : const None(),
      'log_ignore_channels': guild.logIgnoreChannels == null ? const None() : Some(guild.logIgnoreChannels!.map((t) => t.value).toList()),
      'enabled_modules': guild.enabledModules == null ? const None() : Some(guild.enabledModules!),
      'guild_log_webhook_id': guild.guildLogWebhookId?.isSome == true ? guild.guildLogWebhookId! : const None(),
    };

    final buffer = StringBuffer('INSERT INTO guild_table (');

    final toInsert = entries.entries.where((e) => e.value.isSome);

    buffer.write(toInsert.map((e) => e.key).join(', '));

    buffer.write(') ');
    buffer.write('VALUES (');
    buffer.write(toInsert.indexed.map((i) => '\$${i.$1 + 1}').join(', '));
    buffer.write(') RETURNING *;');

    final args =
        toInsert
            .map(
              (e) => switch (e.value.unwrap()) {
                Snowflake(:final value) => value,
                final List<Snowflake> list => list.map((e) => e.value).toList(),
                final value => value,
              },
            )
            .toList();

    final result = await connection.execute(buffer.toString(), parameters: args);

    return Guild.fromRow(result.single.toColumnMap());
  }

  Future<void> edit(EditableGuild guild) async {
    final entries = <String, Option<Object?>>{
      'locale': guild.locale != null ? Some('${guild.locale!.languageCode}-${guild.locale!.countryCode}') : const None(),
      'auto_mod_threshold': Option<double>.fromNullable(guild.autoModThreshold),
      'report_type_tags': guild.reportTypeTags == null ? const None() : Some(guild.reportTypeTags!.map((t) => t.value).toList()),
      'report_status_tag': guild.reportStatusTags == null ? const None() : Some(guild.reportStatusTags!.map((t) => t.value).toList()),
      'appeal_channel_id': guild.appealChannelId?.isSome == true ? guild.appealChannelId! : const None(),
      'mod_log_channel_id': guild.modLogChannelId?.isSome == true ? guild.modLogChannelId! : const None(),
      'report_channel_id': guild.reportChannelId?.isSome == true ? guild.reportChannelId! : const None(),
      'log_ignore_channels': guild.logIgnoreChannels == null ? const None() : Some(guild.logIgnoreChannels!.map((t) => t.value).toList()),
      'enabled_modules': guild.enabledModules == null ? const None() : Some(guild.enabledModules!),
      'guild_log_webhook_id': guild.guildLogWebhookId?.isSome == true ? guild.guildLogWebhookId! : const None(),
    };

    final buffer = StringBuffer('UPDATE guild_table SET ');

    final toUpdate = entries.entries.where((e) => e.value.isSome);

    int guildIdIndex = 0;

    buffer.write(toUpdate.indexed.map((i) => '${i.$2.key} = \$${guildIdIndex = i.$1 + 1}').join(', '));

    buffer.write(' WHERE id = \$${guildIdIndex + 1}');

    final args =
        toUpdate
            .map(
              (e) => switch (e.value.unwrap()) {
                Snowflake(:final value) => value,
                final List<Snowflake> list => list.map((e) => e.value).toList(),
                final value => value,
              },
            )
            .toList();

    final stmt = buffer.toString();

    final realArgs = [...args, guild.guildId.value];

    logger.fine('Executing "$stmt" with $realArgs');

    await connection.execute(stmt, parameters: realArgs);
  }

  Future<void> createOrEdit(EditableGuild guild) async {
    final dbGuild = await getOrNull(guild.guildId);

    if (dbGuild == null) {
      await create(guild);
    } else {
      await edit(guild);
    }
  }
}
