import 'package:nyxx_commands/nyxx_commands.dart';

import '../settings.dart';

final adminCheck = Check((ctx) => ctx.user.id == ownerId, name: 'AdminCheck');
