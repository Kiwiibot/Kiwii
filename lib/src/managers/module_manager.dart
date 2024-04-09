// // import 'package:get_it/get_it.dart';
// // import 'package:kiwii/generated/prisma_client.dart' as prisma_client;
// // import 'package:kiwii/utils/snowflake.dart';
// // import 'package:nyxx/nyxx.dart';

// // // Re-export for convenience
// // typedef GuildModule = prisma_client.GuildModule;

// // final class ModuleManager {
// //   final Snowflake guildId;
// //   ModuleManager(this.guildId);

// //   // final prisma_client.PrismaClient _prisma = GetIt.I.get<prisma_client.PrismaClient>();

// //   Future<void> alterModules(List<GuildModule> modules) async {
// //     await _prisma.guild.upsert(
// //       where: prisma_client.GuildWhereUniqueInput(
// //         id: guildId.toBigInt(),
// //       ),
// //       update: prisma_client.GuildUpdateInput(
// //         id: prisma_client.BigIntFieldUpdateOperationsInput(
// //           set: guildId.toBigInt(),
// //         ),
// //         enabledModules: modules,
// //       ),
// //       create: prisma_client.GuildCreateInput(
// //         id: guildId.toBigInt(),
// //         enabledModules: modules,
// //       ),
// //     );
// //     _cache[guildId] = modules;
// //   }

// //   Future<List<GuildModule>?> fetchModules() async {
// //     final guild = await _prisma.guild.findUnique(
// //       where: prisma_client.GuildWhereUniqueInput(
// //         id: guildId.toBigInt(),
// //       ),
// //     );

// //     if (guild?.enabledModules != null) {
// //       _cache[guildId] = guild!.enabledModules!.toList();
// //     }

// //     return guild?.enabledModules?.toList();
// //   }

// //   final Map<Snowflake, List<GuildModule>> _cache = {};

// //   /// Returns the list of enabled modules for the guild. (Cached)
// //   List<GuildModule>? get enableModules => _cache[guildId];
// // }

// // // extension GuildModulesExtension on Guild {
// // //   ModuleManager get modules => ModuleManager(id);
// // //   StarboardManager get starboard => StarboardManager(this);
// // // }

// import 'package:kiwii/src/managers/modules/starboard_module.dart';
// import 'package:nyxx/nyxx.dart';

// import './modules/module.dart';

// class ModuleManager {
//   final Snowflake guildId;
//   final NyxxGateway client;
//   final StarboardModule starboard;
//   List<Module> get modules => [starboard];
//   ModuleManager(this.guildId, this.client) : starboard = StarboardModule(guildId, client);
// }

// extension GuildModulesExtension on Guild {
//   ModuleManager get modules => ModuleManager(id, manager.client as NyxxGateway);
// }
