import 'dart:convert';

import 'package:dartx/dartx_io.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';

final _restCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _restCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel;

final restCommand = ChatCommand(
  'rest',
  'Runs a REST operation with the given data',
  id('rest', (MessageChatContext ctx, String method, HttpRoute route, [Map<String, Object?>? data, bool? short]) async {
    final res = await ctx.client.httpHandler.execute(BasicRequest(route, method: method, body: (data == null || method == 'GET') ? null : json.encode(data)));

    final jsonEncodedResponse = '\n\n${codeBlock(JsonEncoder.withIndent(' ').convert(res.jsonBody), 'json')}';

    final toDisplay = switch (short) {
      null when method == 'GET' => jsonEncodedResponse,
      null when method == 'HEAD' => codeBlock(
        JsonEncoder.withIndent(' ').convert(
          res.headers.filter(
            (e) => switch (e.key) {
              'set-cookie' || 'report-to' => false,
              _ => true,
            },
          ),
        ),
        'json',
      ),
      null => '',
      true => '',
      false => jsonEncodedResponse,
    };

    await ctx.respond(MessageBuilder(content: 'REST operation completed with status code ${res.statusCode}$toDisplay'));
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
