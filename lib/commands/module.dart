// import 'package:kiwii/src/managers/module_manager.dart';
// import 'package:kiwii/utils/utils.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';

// final module = ChatGroup(
//   'module',
//   'Enable or disable a module for the server',
//   children: [
//     ChatCommand(
//       'enable',
//       'Enable a module for the serveer',
//       id('module-enable', (ChatContext ctx, GuildModule module) async {
//         var modules = ctx.guild!.modules.enableModules ?? await ctx.guild!.modules.fetchModules();

//         final respondBuilder = MessageBuilder(content: 'Enabled module `${module.name.firstLetterUpperCase}`');

//         if (modules == null) {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         } else if (modules.contains(module)) {
//           await ctx.respond(MessageBuilder(content: 'Module `${module.name.firstLetterUpperCase}` is already enabled.'));
//         } else {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         }
//       }),
//     ),
//     ChatCommand(
//       'disable',
//       'Disable a module for the server',
//       id('module-disable', (ChatContext ctx, GuildModule module) async {
//         var modules = ctx.guild!.modules.enableModules ?? await ctx.guild!.modules.fetchModules();

//         final respondBuilder = MessageBuilder(content: 'Disabled module `$module`');

//         if (modules == null || !modules.contains(module)) {
//           await ctx.respond(MessageBuilder(content: 'Module `$module` is already disabled.'));
//         } else {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         }
//       }),
//     ),
//   ],
//   checks: [
//     GuildCheck.all(name: 'module-guild'),
//   ],
// );
