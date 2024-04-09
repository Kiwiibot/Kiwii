// import 'package:kiwii/src/checks/checks.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';
// import 'package:dart_eval/dart_eval.dart';

// final evalCommand = ChatCommand(
//   'eval',
//   'Evaluates a Dart expression.',
//   checks: [adminCheck],
//   id('eval', (ChatContext ctx, String code) async {
//     // final mappings = {
//     //   'ctx': {
//     //     if (ctx case MessageChatContext context)
//     //       'message': {
//     //         'content': context.message.content,
//     //       },
//     //     'respond()'
//     //   }
//     // };
//   }),
// );

// Map<String, dynamic> userToMap(User user) => {
//       'id': user.id.toString(),
//       'username': user.username,
//       'discriminator': user.discriminator,
//       'avatar': {
//         'url': user.avatar.url.toString(),
//       },
//       if (user.banner != null)
//         'banner': {
//           'url': user.banner?.url.toString(),
//         },
//       'globalName': user.globalName,
//       'isBot': user.isBot,
//       'isSystem': user.isSystem,
//       'hasMfaEnabled': user.hasMfaEnabled,
//       if (user.accentColor != null)
//         'accentColor': {
//           'r': user.accentColor!.r,
//           'g': user.accentColor!.g,
//           'b': user.accentColor!.b,
//           'toHexString()': user.accentColor!.toHexString(),
//           'toString()': user.accentColor!.toString(),
//         }
//     };
