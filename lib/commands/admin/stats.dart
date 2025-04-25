import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:tabular/tabular.dart';
import '../../kiwii.dart';
import '../../plugins/tracking.dart';

final _statsCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _statsCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel;

final statsCommand = ChatCommand(
  'stats',
  '',
  id('stats', (MessageChatContext ctx) async {
    final tracking = ctx.client.options.plugins.whereType<Tracking>().first;

    final rows = [
      ['TBNU', 'CBNU', 'TNU', 'BNT'],
      [
        tracking.batchNameUpdates.length,
        tracking.currentBatchNameUpdates.length,
        tracking.totalNameUpdates,
        tracking.doBatchNamesUpdateTask.isActive && tracking.doBatchNamesUpdateTask.tick <= 0
            ? 'PENDING'
            : tracking.doBatchNamesUpdateTask.isActive
            ? 'ACTIVE'
            : 'CANCELED',
      ],
    ];

    await ctx.respond(MessageBuilder(content: codeBlock(tabular(rows, border: Border.all), 'prolog')));
  }),
  checks: [BasePermissionsCheck(_statsCommandPermissions), BaseSelfPermissionsCheck(_statsCommandClientPermissions), OwnerCheck()],
  options: KiwiiCommandOptions(
    permissions: _statsCommandPermissions,
    clientPermissions: _statsCommandClientPermissions,
    usage: '',
    examples: [(command: '', description: '')],
    type: CommandType.textOnly,
  ),
);
