/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:nyxx/nyxx.dart' hide Guild;
import 'package:postgres/postgres.dart' as pg;

import 'plugins/localization.dart';
import 'src/moderation/appeal/create_appeal.dart';
import 'src/moderation/case/create_case.dart';
import 'src/moderation/reports/create_report.dart';
import 'src/settings.dart';
import 'translations.g.dart';

export 'package:drift/drift.dart';

part 'database.g.dart';

QueryExecutor _openConnection() {
  // return NativeDatabase.createInBackground(File('kiwii.sqlite'));
  return PgDatabase(
    endpoint: pg.Endpoint(
      database: postgresDb,
      host: 'localhost',
      username: postgresUser,
      password: postgresPassword,
    ),
    settings: pg.ConnectionSettings(
      sslMode: pg.SslMode.disable,
    ),
  );
}

@DriftDatabase(tables: [Tags, GuildTable, Cases, Appeals, Reports])
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
          if (to == 2) {
            await m.addColumn(appeals, appeals.logPostId);
          }

          if (to == 3) {
            await m.addColumn(cases, cases.logDmMessageId);
          }
        },
      );

  Future<Case> createCase(Case case_) => into(cases).insertReturning(case_);
  Future<Case> updateCase(Case case_) async {
    await update(cases).replace(case_);
    return case_;
  }

  Future<Case> getCase(int caseId, Snowflake guildId) async {
    return (select(cases)..where((c) => c.caseId.equals(caseId) & c.guildId.equalsValue(guildId))).getSingle();
  }

  Future<Case?> getCaseOrNull(int caseId, Snowflake guildId) async {
    return (select(cases)..where((c) => c.caseId.equals(caseId) & c.guildId.equalsValue(guildId))).getSingleOrNull();
  }

  Future<Case> getLastCase(Snowflake guildId) async {
    return (select(cases)
          ..where((c) => c.guildId.equalsValue(guildId))
          ..orderBy([(u) => OrderingTerm(expression: u.caseId, mode: OrderingMode.desc)]))
        .getSingle();
  }

  Future<List<Case>> insertOrUpdateCases(List<Case> cases) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(this.cases, cases);
    });

    return (select(this.cases)..where((tbl) => tbl.caseId.isIn(cases.map((c) => c.caseId)))).get();
  }

  Future<Report> createReport(Report report) => into(reports).insertReturning(report);
  Future<Report> updateReport(Report report) async {
    await update(reports).replace(
      report.copyWith(updatedAt: Value(PgDateTime(DateTime.now()))),
    );
    return report;
  }

  Future<Report> getReport(int reportId, Snowflake guildId) async {
    return (select(reports)..where((r) => r.reportId.equals(reportId) & r.guildId.equalsValue(guildId))).getSingle();
  }

  Future<Appeal> createAppeal(Appeal appeal) => into(appeals).insertReturning(appeal);

  Future<Appeal> updateAppeal(Appeal appeal) async {
    await update(appeals).replace(
      appeal.copyWith(updatedAt: Value(PgDateTime(DateTime.now()))),
    );
    return appeal;
  }

  Future<Appeal> getAppeal(int appealId, Snowflake guildId) async {
    return (select(appeals)..where((a) => a.appealId.equals(appealId) & a.guildId.equalsValue(guildId))).getSingle();
  }

  Future<Appeal?> pendingAppeal(Snowflake userId) async {
    return (select(appeals)
          ..where((a) => a.targetId.equalsValue(userId) & a.status.equalsValue(AppealStatus.pending) & a.reason.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  // Future<Report> updateReport(Report report) async {
  //   await update(reports).replace(
  //     report.copyWith(updatedAt: Value(DateTime.now())),
  //   );
  //   return report;
  // }

  Future<Guild> getGuild(Snowflake guildId) async {
    return (select(guildTable)..where((g) => g.guildId.equalsValue(guildId))).getSingle();
  }

  Future<Guild?> getGuildOrNull(Snowflake guildId) async {
    return (select(guildTable)..where((g) => g.guildId.equalsValue(guildId))).getSingleOrNull();
  }

  // Future<List<
}

class SnowflakeConverter extends TypeConverter<Snowflake, int> {
  const SnowflakeConverter();
  @override
  Snowflake fromSql(int fromDb) {
    return Snowflake.parse(fromDb);
  }

  @override
  int toSql(Snowflake value) {
    return value.value;
  }
}

class SnowflakeArray extends TypeConverter<List<Snowflake>, List<int>> {
  const SnowflakeArray();
  @override
  List<Snowflake> fromSql(List<int> fromDb) {
    return fromDb.map((e) => Snowflake.parse(e)).toList();
  }

  @override
  List<int> toSql(List<Snowflake> value) {
    return value.map((e) => e.value).toList();
  }
}

class LocaleConverter extends TypeConverter<AppLocale, String> {
  const LocaleConverter();
  @override
  AppLocale fromSql(String fromDb) => convertLocale(fromDb)!;
  @override
  String toSql(AppLocale value) {
    return '${value.languageCode}-${value.countryCode}';
  }
}

@DataClassName('Guild')
class GuildTable extends Table {
  IntColumn get guildId => integer().map(const SnowflakeConverter())();
  TextColumn get locale => text().map(const LocaleConverter()).withDefault(const Constant('en-GB'))();
  RealColumn get autoModThreshold => real().withDefault(const Constant(0.8))();
  Column<List<int>> get reportTypeTags => customType(PgTypes.bigIntArray).map(const SnowflakeArray()).withDefault(const Constant([], PgTypes.bigIntArray))();
  Column<List<int>> get reportStatusTags => customType(PgTypes.bigIntArray).map(const SnowflakeArray()).withDefault(const Constant([], PgTypes.bigIntArray))();
  IntColumn get appealChannelId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get modLogChannelId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get reportChannelId => integer().map(const SnowflakeConverter()).nullable()();
  Column<List<int>> get logIgnoreChannels => customType(PgTypes.bigIntArray).map(const SnowflakeArray()).withDefault(const Constant([], PgTypes.bigIntArray))();

  @override
  Set<Column> get primaryKey => {guildId};

  @override
  List<String> get customConstraints => ['UNIQUE(guild_id)'];
}

const postgresCurrentDateAndTime = CustomExpression<PgDateTime>('NOW()');

class Cases extends Table {
  IntColumn get guildId => integer().map(const SnowflakeConverter())();
  IntColumn get logMessageId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get caseId => integer()();
  IntColumn get refId => integer().nullable()();
  IntColumn get targetId => integer().map(const SnowflakeConverter())();
  TextColumn get targetTag => text()();
  IntColumn get modId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get modTag => text().nullable()();
  IntColumn get action => intEnum<CaseAction>()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get actionExpiration => dateTime().nullable()();
  BoolColumn get actionProcessed => boolean().nullable().withDefault(const Constant(true))();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampWithTimezone).withDefault(postgresCurrentDateAndTime)();
  IntColumn get contextMessageId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get roleId => integer().map(const SnowflakeConverter()).nullable()();
  BoolColumn get multi => boolean().nullable().withDefault(const Constant(false))();
  IntColumn get reportRefId => integer().nullable()();
  IntColumn get appealRefId => integer().nullable()();
  IntColumn get logDmMessageId => integer().map(const SnowflakeConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {guildId, caseId};
}

class Appeals extends Table {
  IntColumn get guildId => integer().map(const SnowflakeConverter())();
  IntColumn get appealId => integer()();
  IntColumn get status => intEnum<AppealStatus>().withDefault(Variable(AppealStatus.pending.index)).nullable()();
  IntColumn get targetId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get targetTag => text().nullable()();
  IntColumn get modId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get modTag => text().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get refId => integer().nullable()();
  Column<PgDateTime> get updatedAt => customType(PgTypes.timestampWithTimezone).nullable()();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampWithTimezone).withDefault(postgresCurrentDateAndTime)();
  IntColumn get logPostId => integer().map(const SnowflakeConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {guildId, appealId};
}

class Reports extends Table {
  IntColumn get guildId => integer().map(const SnowflakeConverter())();
  IntColumn get reportId => integer()();
  IntColumn get type => intEnum<ReportType>().nullable()();
  IntColumn get status => intEnum<ReportStatus>().nullable()();
  IntColumn get messageId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get channelId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get targetId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get targetTag => text().nullable()();
  IntColumn get authorId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get authorTag => text().nullable()();
  IntColumn get modId => integer().map(const SnowflakeConverter()).nullable()();
  TextColumn get modTag => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get attachmentUrl => text().nullable()();
  IntColumn get logPostId => integer().map(const SnowflakeConverter()).nullable()();
  IntColumn get refId => integer().nullable()();
  Column<PgDateTime> get updatedAt => customType(PgTypes.timestampWithTimezone).nullable()();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampWithTimezone).withDefault(postgresCurrentDateAndTime)();
  Column<List<int>> get contextMessagesIds => customType(PgTypes.bigIntArray).map(const SnowflakeArray()).nullable()();

  @override
  Set<Column> get primaryKey => {guildId, reportId};
}

class Tags extends Table {
  TextColumn get content => text()();
  Column<PgDateTime> get createdAt => customType(PgTypes.timestampWithTimezone).withDefault(postgresCurrentDateAndTime)();
  IntColumn get id => integer().autoIncrement()();
  IntColumn get locationId => integer()();
  TextColumn get name => text()();
  IntColumn get ownerId => integer().map(const SnowflakeConverter())();
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

class JsonSerializerDb extends ValueSerializer {
  final bool serializeDateTimeValuesAsString;

  const JsonSerializerDb({this.serializeDateTimeValuesAsString = false});

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) {
      return null as T;
    }

    final typeList = <T>[];

    if (typeList is List<DateTime?>) {
      if (json is int) {
        return DateTime.fromMillisecondsSinceEpoch(json) as T;
      } else {
        return DateTime.parse(json.toString()) as T;
      }
    }

    if (typeList is List<double?> && json is int) {
      return json.toDouble() as T;
    }

    // blobs are encoded as a regular json array, so we manually convert that to
    // a Uint8List
    if (typeList is List<Uint8List?> && json is! Uint8List) {
      final asList = (json as List).cast<int>();
      return Uint8List.fromList(asList) as T;
    }

    return json as T;
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) {
      return serializeDateTimeValuesAsString ? value.toIso8601String() : value.millisecondsSinceEpoch;
    }

    return switch (value) {
      Snowflake(:final value) => value.toString(),
      PgDateTime(:final dateTime) => toJson(dateTime),
      _ => value,
    };
  }
}
