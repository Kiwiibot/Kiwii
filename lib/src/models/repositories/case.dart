import 'package:nyxx/nyxx.dart';

import '../../moderation/case/update_case.dart';
import '../case.dart';
import 'repositories.dart';

final class CaseRepository extends Repository {
  final logger = Logger('Kiwii.Repositories.CaseRepository');

  CaseRepository({required super.connection});

  Future<Case> get(int caseId, Snowflake guildId) async {
    final r = await connection.execute(r'SELECT * FROM cases WHERE case_id = $1 AND guild_id = $2', parameters: [caseId, guildId.value]).then((r) => r.single);

    return Case.fromRow(r.toColumnMap());
  }

  Future<Case?> getOrNull(int caseId, Snowflake guildId) async {
    final r = await connection
        .execute(r'SELECT * FROM cases WHERE case_id = $1 AND guild_id = $2', parameters: [caseId, guildId.value])
        .then((r) => r.singleOrNull);

    if (r == null) {
      return null;
    }

    return Case.fromRow(r.toColumnMap());
  }

  Future<Case> update(UpdateCase case_) => updateCase(case_);

  Future<Case> create(CreateCase case_) async {
    final entries = case_.toRow()..removeWhere((_, v) => v == null);

    final args = entries.values.toList();

    final buffer = StringBuffer('INSERT INTO cases (');

    buffer.write(entries.entries.map((e) => e.key).join(', '));

    buffer.write(', case_id');

    // int index = 0;

    buffer.write(') ');

    buffer.write('VALUES (');

    buffer.write(entries.entries.indexed.map((e) => '\$${e.$1 + 1}').join(', '));

    // Special case for the case_id
    buffer.write(r', next_case($1)');

    buffer.write(') ');

    buffer.write('RETURNING *;');

    logger.fine('Executing "$buffer" with $args');

    final r = await connection.execute(buffer.toString(), parameters: args).then((r) => r.single);

    return Case.fromRow(r.toColumnMap());
  }
}
