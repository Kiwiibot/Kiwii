import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'src/settings.dart';

export 'package:drift/drift.dart';

part 'database.g.dart';

QueryExecutor _openConnection() {
  return NativeDatabase.createInBackground(File('kiwii.sqlite'));
}

@DriftDatabase(tables: [Tags, GuildTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.addColumn(tags, tags.timesCalled as GeneratedColumn<Object>);
          }
          if (from == 2) {
            await m.addColumn(guildTable, guildTable.autoModThreshold as GeneratedColumn<Object>);
          }
        },
      );
}

@DataClassName('Guild')
class GuildTable extends Table {
  IntColumn get guildId => integer()();
  TextColumn get locale => text().withDefault(const Constant('en-GB'))();
  RealColumn get autoModThreshold => real().withDefault(const Constant(0.8))();

  @override
  Set<Column> get primaryKey => {guildId};
}

class Tags extends Table {
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get id => integer().autoIncrement()();
  IntColumn get locationId => integer()();
  TextColumn get name => text()();
  IntColumn get ownerId => integer()();
  IntColumn get timesCalled => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => ['UNIQUE(name, location_id)'];
}

class Starboard extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get guild => integer().references(GuildTable, #guildId)();
  IntColumn get threshold => integer().withDefault(const Constant(3))();
  TextColumn get emojis => text().withDefault(Constant(starboardEmojis.join(',')))();
  IntColumn get channelId => integer()();
}
