import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:postgres/postgres.dart';

import '../tag.dart';
import 'repositories.dart';

final class TagRepository extends Repository {
  final List<Tag> tags = [];

  TagRepository({required super.connection});

  Future<Tag> create(EditableTag tag) async {
    final createdTag = await connection.runTx(
      (t) => t
          .execute(
            r'INSERT INTO tags (content, location_id, name, owner_id) VALUES ($1, $2, $3, $4) RETURNING created_at, id;',
            parameters: [tag.content, tag.locationId!.value, tag.name, tag.ownerId!.value],
          )
          .then(
            (r) => Tag.fromRow({
              ...r.single.toColumnMap(),
              'content': tag.content,
              'location_id': tag.locationId!.value,
              'owner_id': tag.ownerId!.value,
              'name': tag.name,
            }),
          ),
    );

    tags.add(createdTag);

    return createdTag;
  }

  Future<void> delete(Tag tag) async {
    await connection.runTx((t) => t.execute(r'DELETE FROM tags WHERE id=$1;', parameters: [tag.id]));
    tags.remove(tag);
  }

  Future<void> deleteWith(Tag tag, String clause) async {
    await connection.runTx(
      (t) => t.execute(
        'DELETE FROM tags WHERE id=\$1 AND $clause',
        parameters: [tag.id, tag.name, tag.locationId.value, if (clause.contains(r'$4')) tag.ownerId.value],
      ),
    );
    tags.remove(tag);
  }

  Future<void> edit(EditableTag tag) async {
    final buffer = StringBuffer(r'UPDATE tags SET ');

    final entries = {'content': tag.content, 'location_id': tag.locationId, 'name': tag.name, 'owner_id': tag.ownerId, 'times_called': tag.timesCalled};

    buffer.write(entries.entries.where((e) => e.value != null).map((e) => '${e.key} = @${e.key}').join(','));

    buffer.write(' WHERE id = @id ');

    buffer.write('RETURNING *;');

    final updatedTag = await connection.runTx((t) => t.execute(Sql.named(buffer.toString()), parameters: {...entries..removeWhere((k, v) => v == null), 'id': tag.id}).then((r) => Tag.fromRow(r.single.toColumnMap())));

    final oldTagIndex = tags.indexWhere((t) => t.id == tag.id!);
    tags[oldTagIndex] = updatedTag;
  }

  Future<Iterable<Tag>> findAll(Snowflake guildId, [Snowflake? userId]) async {
    if (userId == null) {
      return tags.where((tag) => tag.locationId == guildId);
    }

    return tags.where((tag) => tag.locationId == guildId && userId == tag.ownerId);
  }

  Future<Tag> find(String name, Snowflake guildId) async {
    Tag tag;

    try {
      tag = tags.firstWhere((t) => t.locationId == guildId && t.name == name);
    } on StateError {
      tag = await connection
          .execute(r'SELECT * FROM tags WHERE name = $1 AND location_id = $2', parameters: [name, guildId])
          .then((r) => Tag.fromRow(r.single.toColumnMap()));
      tags.add(tag);
    }

    return tag;
  }
}
