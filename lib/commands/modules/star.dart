// import 'dart:async';

// import 'package:get_it/get_it.dart';
// import 'package:kiwii/generated/prisma_client.dart';
// import 'package:kiwii/src/managers/modules/starboard_manager.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';
// import 'package:kiwii/kiwii.dart';

// final _starboards = <Snowflake, StarboardConfig>{};
// final _messageCache = <Snowflake, Message>{};
// final _aboutToBeDeleted = <Snowflake>{};
// final _staleStarGivers = <Snowflake>{};
// // final _locks = WeakReference(<Snowflake, Guild>{});
// final spoilers = RegExp(r'\|\|(.+?)\|\|');
// final prisma = GetIt.I.get<PrismaClient>();

// // Future<void> _updateStarGivers() async {
// //   if (_staleStarGivers.isNotEmpty) {
// //     return;
// //   }

// //   final query = r'''
// //     INSERT INTO "StarGiv
// // }

// final star = ChatCommand(
//   'star',
//   'Star a message, or view the stats of a starred message',
//   id('star', (ChatContext ctx, Snowflake messageId) async {
//     Timer(const Duration(hours: 1), () {
//       _messageCache.clear();
//     });
//     final starboard = _starboards[ctx.guild!.id]!;
//   }),
//   checks: [
//     GuildCheck.all(name: 'star-guild-check'),
//     Check(
//       (ctx) async {
//         final starboard = await ctx.guild!.starboard.getStarboard();
//         if (starboard == null || starboard.channelId == null) {
//           await ctx.respond(MessageBuilder(content: 'Starboard is not configured for this server.'));
//           return false;
//         }
//         _starboards[ctx.guild!.id] = starboard;
//         return true;
//       },
//       name: 'star-check',
//       allowsDm: false,
//       requiredPermissions: Permissions.addReactions,
//     ),
//   ],
// );
