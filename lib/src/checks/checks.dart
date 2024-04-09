import 'package:kiwii/src/settings.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

final adminCheck = Check((ctx) => ctx.user.id == ownerId, name: 'AdminCheck');

