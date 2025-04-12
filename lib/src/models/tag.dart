import 'package:nyxx/nyxx.dart';
import 'package:option/option.dart';

final class Tag {
  /// The contents for this tag.
  final String content;

  /// When the tag was created.
  final DateTime createdAt;

  /// When the tag was updated.
  final DateTime? updatedAt;

  /// The id of this tag.
  final int id;

  /// Where this tag was registered. (Usually a guild id)
  final Snowflake locationId;

  /// The name of this tag.
  final String name;

  /// The id of the user that created this tag.
  final Snowflake ownerId;

  /// How many times this tag was called.
  final int timesCalled;

  const Tag({
    required this.createdAt,
    required this.id,
    required this.locationId,
    required this.name,
    required this.ownerId,
    required this.content,
    required this.timesCalled,
    this.updatedAt,
  });

  Tag copyWith({
    Option<String> content = const None(),
    Option<int> id = const None(),
    Option<DateTime> createdAt = const None(),
    Option<Snowflake> locationId = const None(),
    Option<String> name = const None(),
    Option<Snowflake> ownerId = const None(),
    Option<int> timesCalled = const None(),
  }) => Tag(
    createdAt: createdAt.unwrapOr(this.createdAt),
    id: id.unwrapOr(this.id),
    locationId: locationId.unwrapOr(this.locationId),
    name: name.unwrapOr(this.name),
    ownerId: ownerId.unwrapOr(this.ownerId),
    timesCalled: timesCalled.unwrapOr(this.timesCalled),
    content: content.unwrapOr(this.content),
  );

  static Tag fromRow(Map<String, Object?> row) {
    return Tag(
      content: row['content'] as String,
      createdAt: row['created_at'] as DateTime,
      id: row['id'] as int,
      locationId: Snowflake.parse(row['location_id']!),
      name: row['name'] as String,
      ownerId: Snowflake.parse(row['owner_id']!),
      timesCalled: row['times_called'] as int? ?? 0,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }
}

class EditableTag {
  /// The id of this tag.
  final int? id;

  /// The contents for this tag.
  final String? content;

  /// Where this tag was registered. (Usually a guild id)
  final Snowflake? locationId;

  /// The name of this tag.
  final String? name;

  /// The id of the user that created this tag.
  final Snowflake? ownerId;

  /// How many times this tag was called.
  final int? timesCalled;

  const EditableTag({this.locationId, this.name, this.ownerId, this.content, this.id, this.timesCalled});

  EditableTag copyWith({
    Option<String?> content = const None(),
    Option<Snowflake?> locationId = const None(),
    Option<String?> name = const None(),
    Option<Snowflake?> ownerId = const None(),
    Option<int?> timesCalled = const None(),
    Option<int?> id = const None(),
  }) => EditableTag(
    locationId: locationId.unwrapOr(this.locationId),
    name: name.unwrapOr(this.name),
    ownerId: ownerId.unwrapOr(this.ownerId),
    timesCalled: timesCalled.unwrapOr(this.timesCalled),
    content: content.unwrapOr(this.content),
    id: id.unwrapOr(this.id),
  );
}
