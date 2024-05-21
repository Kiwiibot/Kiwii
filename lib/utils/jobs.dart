import 'package:dartx/dartx.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:style_cron_job/style_cron_job.dart';

import '../database.dart';
import '../kiwii.dart';
import '../src/models/case.dart';
import '../src/moderation/case/delete_case.dart';
import '../src/moderation/replies/acknowledge_case.dart';

Future<void> registerJobs() async {
  final client = GetIt.I.get<NyxxGateway>();
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();

  each.minute.listen((time) async {
    await modActionTimers(db, client, logger);
  });
}

Future<void> modActionTimers(AppDatabase db, NyxxGateway client, Logger logger) async {
  final query = db.cases.selectOnly()
    ..addColumns([db.cases.guildId, db.cases.caseId, db.cases.actionExpiration])
    ..where(db.cases.actionExpiration.isNotNull() & db.cases.actionProcessed.equals(false));
  final currentCases = await query
      .map((row) => (
            actionExpiration: row.read(db.cases.actionExpiration),
            caseId: row.read(db.cases.caseId),
            guildId: Snowflake.parse(row.read(db.cases.guildId)!),
          ))
      .get();

  for (final ccase in currentCases) {
    if (ccase.actionExpiration! <= DateTime.now()) {
      final guild = client.guilds.cache[ccase.guildId];

      if (guild == null) {
        continue;
      }

      try {
        final newCase = await deleteCase(
          DeleteCase(
            guildId: guild.id,
            caseId: ccase.caseId!,
            modId: client.user.id,
            modTag: (await client.user.get()).tag,
          ),
          guild,
        );
        await acknowledgeCase(guild, newCase, '/', await client.user.get());
      } catch (e) {
        logger.warning('Failed to delete case ${ccase.caseId}', e);
      }
    }
  }
}
