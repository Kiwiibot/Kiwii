import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
// ignore: implementation_imports
import 'package:drift_postgres/src/types.dart';
import 'package:postgres/postgres.dart';

export 'package:drift/drift.dart';

part 'database.g.dart';

PgDatabase _openConnection() {
  return PgDatabase(
    endpoint: Endpoint(
      database: 'kiwii',
      host: 'localhost',
      username: 'postgres',
      password: 'Hello1234',
      port: 5432,
    ),
    logStatements: true,
    settings: ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );
}

@DriftDatabase(tables: [Tags, Starboard, StarboardEntries, Starrers, StarGivers, GuildTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// class Guild extends Table {
//   IntColumn get id => integer()();
//   IntColumn get moduleId => integer().references(Modules, #id)();
// }

// class Modules extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   TextColumn get name => text()();
//   TextColumn get description => text()();
//   BoolColumn get enabled => boolean()();
// }

class GuildTable extends Table {
  IntColumn get guildId => integer()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get locale => text()();
}

class SerialType extends PostgresType<int> {
  const SerialType() : super(type: Type.serial, name: 'serial');
}

class Starboard extends Table {
  IntColumn get channelId => integer().nullable()();
  TextColumn get customEmojis => text().nullable()();
  IntColumn get id => integer()();
  BoolColumn get locked => boolean()();
  Column<Interval> get maxAge => customType(PgTypes.interval)();
  @override
  Set<Column<Object>>? get primaryKey => {id};

  IntColumn get threshold => integer()();
}

@DataClassName('StarboardEntry')
class StarboardEntries extends Table {
  IntColumn get authorId => integer().nullable()();
  IntColumn get botMessageId => integer().nullable()();
  IntColumn get channelId => integer().nullable()();
  IntColumn get guildId => integer().nullable().references(Starboard, #id, onDelete: KeyAction.cascade, onUpdate: KeyAction.noAction)();
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId => integer().unique()();
  IntColumn get total => integer().clientDefault(() => 0)();
}

class StarGivers extends Table {
  IntColumn get authorId => integer()();
  IntColumn get guildId => integer()();
  Column<int> get id => customType(const SerialType())();
  IntColumn get total => integer()();
}

class Starrers extends Table {
  IntColumn get authorId => integer()();
  IntColumn get entryId => integer().references(StarboardEntries, #id, onDelete: KeyAction.cascade, onUpdate: KeyAction.noAction)();
  Column<int> get id => customType(const SerialType())();
}

class Tags extends Table {
  TextColumn get content => text()();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampNoTimezone)();
  IntColumn get id => integer().autoIncrement()();
  IntColumn get locationId => integer()();
  TextColumn get name => text()();
  IntColumn get ownerId => integer()();
}

class UserTable extends Table {
  TextColumn get email => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get password => text()();

}
