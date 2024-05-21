import 'package:get_it/get_it.dart';

import '../../../database.dart';
import '../../models/case.dart';

Future<Case> updateCase(UpdateCase case_) async {
  final db = GetIt.I.get<AppDatabase>();

  final currentCase = await db.getCase(case_.caseId!, case_.guildId!);

  final updates = currentCase.copyWith(
    reason: Value(case_.reason),
    refId: Value(case_.refId),
    actionExpiration: Value(case_.actionExpiration),
    appealRefId: Value(case_.appealRefId),
    contextMessageId: Value(case_.contextMessageId),
    reportRefId: Value(case_.reportRefId),
  );

  return db.updateCase(updates);
}

Future<List<Case>> batchUpdateCase(List<UpdateCase> cases) async {
  final db = GetIt.I.get<AppDatabase>();

  final updatedCases = <Case>[];

  for (final case_ in cases) {
    final currentCase = await db.getCase(case_.caseId!, case_.guildId!);

    final updates = currentCase.copyWith(
      reason: Value(case_.reason),
      refId: Value(case_.refId),
      actionExpiration: Value(case_.actionExpiration),
      appealRefId: Value(case_.appealRefId),
      contextMessageId: Value(case_.contextMessageId),
      reportRefId: Value(case_.reportRefId),
    );

    updatedCases.add(updates);
  }

  return db.insertOrUpdateCases(updatedCases);
}