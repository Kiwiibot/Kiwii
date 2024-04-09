// import 'dart:async';

// import 'package:get_it/get_it.dart';
// import 'package:kiwii/database.dart';
// import 'package:kiwii/utils/extensions.dart';
// import 'package:nyxx/nyxx.dart';

// import './module.dart';

// /// A starboard module.
// ///
// /// There are two ways to make use of this module, the first is reacting to a message with one of the starboard emojis, the second is using the `star` command
// /// with the given message id.
// class StarboardModule extends Module {
//   @override
//   final String name = 'Starboard';

//   final Map<Snowflake, Message> _messageCache = {};
//   final Set<Snowflake> _aboutToBeDeleted = {};
//   final Set<Snowflake> _staleStarGivers = {};
//   final AppDatabase db = GetIt.I.get<AppDatabase>();

//   StarboardModule(super.guildId, super.client) {
//     _cleanMessageCache();
//   }

//   Future<StarboardData> getStarboard() async {
//     final starboard = await (db.select(db.starboard)..where((tbl) => tbl.id.equals(guildId.value))).getSingle();
//     return starboard;
//   }

//   Future<void> starMessage(
//     /* GuildTextChannel|GuildVoiceChannel|Thread*/ TextChannel channel,
//     Snowflake messageId,
//     Snowflake starrerId,
//   ) async {
//     final starboard = await getStarboard();

//     if (channel case GuildTextChannel() || GuildVoiceChannel() || Thread()) {
//       throwIf(starboard.channelId == null, 'Starboard channel is not set up.');
//       final starboardChannel = await client.channels.get(starboard.channelId!.snowflake) as GuildTextChannel;
//       throwIf(starboard.locked, 'Starboard is locked.');
//       throwIf(
//         (channel is Thread ? (await channel.parent?.get() as GuildTextChannel?)?.isNsfw == true : (channel as GuildChannel).isNsfw) && !starboardChannel.isNsfw,
//         'Cannot star NSFW content in a non-NSFW starboard.',
//       );

//       if (channel.id == starboardChannel.id) {
//         return;
//       }

//       // if (starboardChannel.per)
//     } else {
//       return;
//     }
//   }

//   void _cleanMessageCache() {
//     Timer.periodic(const Duration(hours: 1), (_) {
//       _messageCache.clear();
//     });
//   }

//   Future<void> _updateStarGivers() async {
//     if (_staleStarGivers.isEmpty) {
//       return;
//     }

//     final query = r'''
//       INSERT INTO star_givers (author_id, guild_id, total)
//       SELECT starrers.author_id, entry.guild_id, COUNT(*)
//       FROM starrers
//       INNER JOIN starboard_entries AS entry ON entry.id = starrers.entry_id
//       WHERE entry.guild_id = ANY($1::int[])
//       GROUP BY starrers.author_id, entry.guild_id
//       ON CONFLICT (author_id, guild_id) DO UPDATE SET total = EXCLUDED.total;
//     ''';

//     final params = [_staleStarGivers.toList()];

//     await db.customStatement(query, params);
//     _staleStarGivers.clear();
//   }
// }
