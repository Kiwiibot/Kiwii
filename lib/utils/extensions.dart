import 'package:darq/darq.dart';
import 'package:dartx/dartx.dart' hide StringCapitalizeExtension;
import 'package:get_it/get_it.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:nyxx_commands/nyxx_commands.dart' hide id;

import '../database.dart' hide Guild;

extension ContextExtension on ChatContext {
  Future<Message> send(String content) => respond(MessageBuilder(content: content));

  // Returns the bot's prefix or '/' if this was invoked from an interaction.
  String get realPrefix => this is InteractionChatContext ? '/' : (this as MessageChatContext).prefix;
}

extension GuildExtensions on Guild {
  Future<Member> get me => members.get(manager.client.user.id);

  Map<Snowflake, GuildChannel> get channels => manager.client.channels.cache.entries
      .where((e) => e.value is GuildChannel && (e.value as GuildChannel).guildId == id)
      .toMap((e) => e as MapEntry<Snowflake, GuildChannel>);
}

extension MemberExtensions on Member {
  Guild? get guild => manager.client.guilds.cache[manager.guildId];

  Future<bool> get isManageable async {
    if (id == guild?.ownerId) {
      return false;
    }

    if (id == manager.client.user.id) {
      return false;
    }

    if (manager.client.user.id == guild?.ownerId) {
      return true;
    }

    final me = await guild!.me;

    final meHighestRole = await me.highestRole;
    final highestRole = await this.highestRole;

    return ((meHighestRole?.position ?? 0).compareTo(highestRole?.position ?? 0) > 0);
  }

  Future<bool> get isUnmanageable async => !await isManageable;

  Future<Permissions> get computedPermissions async =>
      Permissions((await Future.wait(roles.map((e) => e.get()))).map((e) => e.permissions).fold<Flags<Permissions>>(Flags(0), (a, b) => (a | b)).value);

  Future<bool> get isBannable async {
    if (guild == null) {
      return false;
    }

    final me = await guild!.me;

    final mePermissions = await me.computedPermissions;
    final isManageable = await this.isManageable;

    final canBan = (mePermissions.canBanMembers || mePermissions.isAdministrator);

    return canBan && isManageable;
  }

  Future<bool> get isUnbannable async => !await isBannable;

  Future<List<Role>> get resolvedRoles async => Future.wait(roles.map((e) => guild!.roles.get(e.id)));

  Future<Message> sendMessage(MessageBuilder builder) async => (user ?? await manager.client.users.get(id)).sendMessage(builder);
}

extension HighestRoleExtension on Member {
  Future<Role?> get highestRole async {
    final roles = await resolvedRoles;
    return roles.isEmpty ? null : roles.reduce((a, b) => a.position > b.position ? a : b);
  }
}

extension ChatCommandExtension on ChatCommand {
  ChatCommandComponent get root {
    dynamic parent = this;
    while (parent.parent != null) {
      if (parent.parent is CommandsPlugin) {
        break;
      }

      parent = parent.parent!;
    }
    return parent;
  }
}

extension UserExtension on User {
  String get tag => discriminator == '0' ? username : '$username#$discriminator';

  DmChannel? get dm => manager.client.channels.cache.values.firstOrNullWhere((e) => e is DmChannel && e.recipient.id == id) as DmChannel?;

  Future<Message> sendMessage(MessageBuilder builder) async => (dm ?? await manager.createDm(id)).sendMessage(builder);
}

extension FutureErrorNullable<T> on Future<T> {
  Future<T?> silentCatchAsNull() async {
    try {
      return await this;
    } catch (_) {
      return null;
    }
  }
}

// extension ThreadExtension on Thread {
//   // GuildTextChannel get parent => client.channels[p
// }

extension EmbedBuilderBetter on EmbedBuilder {
  void addBlankField({bool isInline = false}) => addField(
        name: '\u200b',
        value: '\u200b',
        isInline: isInline,
      );

  void addField({required String name, required String value, bool isInline = false}) => (fields ?? (fields = [])).add(
        EmbedFieldBuilder(
          name: name,
          value: value,
          isInline: isInline,
        ),
      );

  void maybeAddField({String? name, String? value, bool isInline = false}) {
    if (name != null && value != null) {
      addField(name: name, value: value, isInline: isInline);
    }
  }
}

extension ListExtension<E> on List<E> {
  String joinWithStep([String separator = '', int step = 1, String inBetween = ' ']) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i += step) {
      buffer.write(this[i]);
      if (i + step < length) {
        buffer.write(separator);
      }
    }
    return buffer.toString();
  }
}

extension SnowflakeExtension on Snowflake {
  /// Converts a [Snowflake] to a [BigInt].
  BigInt toBigInt() => BigInt.from(value);
}

extension SnowflakeInt on int {
  Snowflake get snowflake => Snowflake(this);
}

extension SnowflakeString on String {
  Snowflake get snowflake => Snowflake.parse(this);
}

extension StringExtension on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
  String get firstLetterUpperCase => '${this[0].toUpperCase()}${substring(1)}';
  String get title => splitMapJoin(' ', onNonMatch: (s) => s.capitalize, onMatch: (s) => s[0]!);
}

extension ClientExtensions on NyxxRest {
  AppDatabase get db => GetIt.I.get<AppDatabase>();
  Cache<String> get cache => GetIt.I.get<Cache<String>>();
}
