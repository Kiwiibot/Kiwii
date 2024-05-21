import 'package:drift_postgres/drift_postgres.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart';
import '../../models/appeal.dart';

enum AppealStatus {
  pending,
  accepted,
  denied,
}

Future<Appeal> createAppeal(CreateAppeal appeal) async {
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();

  final nextAppealId = await nextAppeal(appeal.guildId);

  try {
    final newAppeal = Appeal(
      appealId: nextAppealId,
      targetId: appeal.targetId,
      targetTag: appeal.targetTag,
      guildId: appeal.guildId,
      createdAt: PgDateTime(DateTime.now()),
      status: AppealStatus.pending,
      refId: appeal.refId,
    );

    await db.createAppeal(newAppeal);

    return newAppeal;
  } catch (e) {
    logger.warning('Failed to create appeal: $e');
    rethrow;
  }
}

Future<int> nextAppeal(Snowflake guildId) async {
  final db = GetIt.I.get<AppDatabase>();

  final lastAppeal = await (db.appeals.select()
        ..where((a) => a.guildId.equalsValue(guildId))
        ..orderBy([(u) => OrderingTerm.desc(u.appealId)])
        ..limit(1))
      .getSingleOrNull();

  return (lastAppeal?.appealId ?? 0) + 1;
}
