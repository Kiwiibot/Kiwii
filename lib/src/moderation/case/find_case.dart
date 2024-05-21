import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart';

Future<List<Case>> listCases(String sentence, Snowflake guildId) {
  final db = GetIt.I.get<AppDatabase>();

  if (sentence.isEmpty) {
    return (db.select(db.cases)
          ..where(
            (tbl) => tbl.guildId.equalsValue(guildId),
          )
          ..orderBy([
            (u) => OrderingTerm(expression: u.createdAt),
          ])
          ..limit(25))
        .get();
  }
  int? caseId;
  if ((caseId = int.tryParse(sentence)) != null) {
    return (db.select(db.cases)
          ..where(
            (tbl) => tbl.guildId.equalsValue(guildId) & tbl.caseId.equals(caseId!),
          ))
        .get();
  }

  return (db.select(db.cases)
        ..where((tbl) =>
            tbl.guildId.equalsValue(guildId) &
            (tbl.targetId.equals(int.tryParse(sentence) ?? 0) | tbl.targetTag.like('%$sentence%') | tbl.reason.like('%$sentence%')))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)])
        ..limit(25))
      .get();
}
