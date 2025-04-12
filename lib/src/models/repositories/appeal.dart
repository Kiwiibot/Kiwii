import 'package:nyxx/nyxx.dart';

import '../appeal.dart';
import 'repositories.dart';
import '../../moderation/appeal/create_appeal.dart';
import '../../moderation/appeal/update_appeal.dart';

final class AppealRepository extends Repository {
  const AppealRepository({required super.connection});

  Future<Appeal> create(CreateAppeal appeal) => createAppeal(appeal);

  Future<Appeal> update(UpdateAppeal appeal) => updateAppeal(appeal);

  Future<Appeal?> pending(Snowflake userId) {
    final r = connection
        .execute(
          r'SELECT * FROM appeals WHERE target_id = $1 AND status = $2 AND reason IS NULL LIMIT 1;',
          parameters: [userId.value, AppealStatus.pending.index],
        )
        .then((r) => r.singleOrNull == null ? null : Appeal.fromRow(r.single.toColumnMap()));
    return r;
  }

  Future<Appeal?> byRef(int refId) {
    final r = connection
        .execute(r'SELECT * FROM appeals WHERE ref_id = $1', parameters: [refId])
        .then((r) => r.singleOrNull == null ? null : Appeal.fromRow(r.single.toColumnMap()));

    return r;
  }
}
