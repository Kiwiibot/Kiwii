import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
// ignore: implementation_imports
import 'package:drift_postgres/src/types.dart';
import 'package:postgres/postgres.dart';

export 'package:drift/drift.dart';

part 'database.g.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get content => text()();
  IntColumn get ownerId => integer()();
  IntColumn get locationId => integer()();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampNoTimezone)();
}

class Starboard extends Table {
  IntColumn get id => integer()();
  IntColumn get channelId => integer().nullable()();
  IntColumn get threshold => integer()();
  BoolColumn get locked => boolean()();
  Column<Interval> get maxAge => customType(PgTypes.interval)();
  TextColumn get customEmojis => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DataClassName('StarboardEntry')
class StarboardEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get botMessageId => integer().nullable()();
  IntColumn get messageId => integer().unique()();
  IntColumn get channelId => integer().nullable()();
  IntColumn get authorId => integer().nullable()();
  IntColumn get guildId => integer().nullable().references(Starboard, #id, onDelete: KeyAction.cascade, onUpdate: KeyAction.noAction)();
  IntColumn get total => integer().clientDefault(() => 0)();
}

class Starrers extends Table {
  Column<int> get id => customType(const SerialType())();
  IntColumn get authorId => integer()();
  IntColumn get entryId => integer().references(StarboardEntries, #id, onDelete: KeyAction.cascade, onUpdate: KeyAction.noAction)();
}

class StarGivers extends Table {
  Column<int> get id => customType(const SerialType())();
  IntColumn get authorId => integer()();
  IntColumn get guildId => integer()();
  IntColumn get total => integer()();
}

class Guild extends Table {
  IntColumn get id => integer()();
  IntColumn get moduleId => integer().references(Modules, #id)();
}

class Modules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  BoolColumn get enabled => boolean()();
}

@DriftDatabase(tables: [Tags, Starboard, StarboardEntries, Starrers, StarGivers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

PgDatabase _openConnection() {
  return PgDatabase(
    endpoint: Endpoint(
      database: 'kiwii',
      host: 'database',
      username: 'postgres',
      password: 'foobarbaz',
      port: 5432,
    ),
    logStatements: true,
    settings: ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );
}

class SerialType extends PostgresType<int> {
  const SerialType() : super(type: Type.serial, name: 'serial');
}
