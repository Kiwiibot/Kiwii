import 'dart:convert';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import '../../kiwii.dart';

final _restCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _restCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel;

final restCommand = ChatCommand(
  'rest',
  'Runs a REST operation with the given data',
  id('rest', (MessageChatContext ctx, String method, HttpRoute route, [Map<String, Object?>? data, bool short = true]) async {
    final res = await ctx.client.httpHandler.execute(BasicRequest(route, method: method, body: (data == null || method == 'GET') ? null : json.encode(data)));

    await ctx.respond(
      MessageBuilder(
        content:
            'REST operation completed with status code ${res.statusCode}${short ? '' : '\n\n```json\n${JsonEncoder.withIndent(' ').convert(res.jsonBody)}\n```'}',
      ),
    );
  }),
  checks: [BasePermissionsCheck(_restCommandPermissions), BaseSelfPermissionsCheck(_restCommandClientPermissions), OwnerCheck()],
  options: KiwiiCommandOptions(
    permissions: _restCommandPermissions,
    clientPermissions: _restCommandClientPermissions,
    usage: '',
    examples: [(command: '', description: '')],
    type: CommandType.textOnly,
  ),
);
