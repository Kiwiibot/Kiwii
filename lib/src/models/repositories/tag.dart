import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:postgres/postgres.dart';

import '../tag.dart';
import 'repositories.dart';

final class TagRepository extends Repository {
  final List<Tag> tags = [];

  final logger = Logger('Kiwii.Repositories.TagRepository');

  TagRepository({required super.connection});

  Future<Tag> create(EditableTag tag) async {
    final stmt = r'INSERT INTO tags (content, location_id, name, owner_id) VALUES ($1, $2, $3, $4) RETURNING created_at, id;';
    final args = [tag.content, tag.locationId!.value, tag.name, tag.ownerId!.value];

    logger.fine('Executing "$stmt" with $args');

    final createdTag = await connection.runTx(
      (t) => t
          .execute(stmt, parameters: args)
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
    logger.fine('Executing "DELETE FROM tags WHERE id = \$1" with [${tag.id}]');
    await connection.runTx((t) => t.execute(r'DELETE FROM tags WHERE id = $1;', parameters: [tag.id]));
    tags.remove(tag);
  }

  Future<void> deleteWith(Tag tag, String clause) async {
    final stmt = 'DELETE FROM tags WHERE id=\$1 AND $clause;';
    final args = [tag.id, tag.name, tag.locationId.value, if (clause.contains(r'$4')) tag.ownerId.value];

    logger.fine('Executing "$stmt" with $args');

    await connection.runTx((t) => t.execute(stmt, parameters: args));
    tags.remove(tag);
  }

  Future<void> edit(EditableTag tag) async {
    final buffer = StringBuffer(r'UPDATE tags SET ');

    final entries = {
      'content': tag.content,
      'location_id': tag.locationId?.value,
      'name': tag.name,
      'owner_id': tag.ownerId?.value,
      'times_called': tag.timesCalled,
    };

    buffer.write(entries.entries.where((e) => e.value != null).map((e) => '${e.key} = @${e.key}').join(','));

    buffer.write(' WHERE id = @id ');

    buffer.write('RETURNING *;');

    final args = {...entries..removeWhere((k, v) => v == null), 'id': tag.id};

    logger.fine('Executing "$buffer" with $args');

    final updatedTag = await connection.runTx(
      (t) => t.execute(Sql.named(buffer.toString()), parameters: args).then((r) => Tag.fromRow(r.single.toColumnMap())),
    );

    final oldTagIndex = tags.indexWhere((t) => t.id == tag.id!);

    if (oldTagIndex == -1) {
      return;
    }

    tags[oldTagIndex] = updatedTag;
  }

  Future<Iterable<Tag>> findAll(Snowflake guildId, [Snowflake? userId]) async {
    final Iterable<Tag> tags;

    if (userId == null) {
      tags = this.tags.where((tag) => tag.locationId == guildId);
    } else {
      tags = this.tags.where((tag) => tag.locationId == guildId && userId == tag.ownerId);
    }

    if (tags.isEmpty) {
      final stmt = 'SELECT * FROM tags WHERE location_id = \$1 ${userId == null ? '' : r'AND owner_id = $2'}';
      final args = [guildId.value, if (userId != null) userId.value];

      logger.fine('Executing "$stmt" with $args');

      final r = await connection.execute(stmt, parameters: args);

      final tgs = r.map((r) => Tag.fromRow(r.toColumnMap()));

      this.tags.addAll(tgs);

      return tgs;
    }

    return tags;
  }

  Future<Tag> find(String name, Snowflake guildId) async {
    Tag tag;

    try {
      tag = tags.firstWhere((t) => t.locationId == guildId && t.name == name);
    } on StateError {
      tag = await connection
          .execute(r'SELECT * FROM tags WHERE name = $1 AND location_id = $2', parameters: [name, guildId.value])
          .then((r) => Tag.fromRow(r.single.toColumnMap()));
      tags.add(tag);
    }

    return tag;
  }
}
