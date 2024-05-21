import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart';
import '../../models/appeal.dart';

Future<Appeal> updateAppeal(UpdateAppeal appeal) async {
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();

  try {
    final currentAppeal = await db.getAppeal(appeal.appealId, appeal.guildId);

    final updatedAppeal = currentAppeal.copyWith(
      reason: Value(appeal.reason),
      modId: Value(appeal.modId),
      modTag: Value(appeal.modTag),
      status: Value(appeal.status),
    );

    await db.updateAppeal(updatedAppeal);

    return updatedAppeal;
  } catch (e) {
    logger.warning('Failed to update appeal: $e');
    rethrow;
  }
}
