import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/converters/converters.dart';

final _avatarCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _avatarCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

final avatarCommand = ChatCommand(
  'avatar',
  'Get the avatar of the user, or yourself',
  id('avatar', (
    ChatContext ctx, [
    @Description('The member to get the avatar of.', {Locale.fr: 'Le membre dont vous voulez voir l\'avatar'}) Member? member,
    @Description('The size to use for the displayed avatar', {Locale.fr: 'La taille de l\'avatar a afficher'})
    @UseConverter(imageSizeConverter)
    int size = 4096,
    @Description('Wheter to see the user\'s current guild avatar', {Locale.fr: 'Est-ce qu\'il faut afficher l\'avatar du serveur de l\'utilisateur'})
    bool server = false,
  ]) async {
    member ??= ctx.member ?? await ctx.guild?.members.get(ctx.user.id);

    final user = await ctx.client.users.fetch(member!.id);

    final formats = {
      CdnFormat.png,
      CdnFormat.jpeg,
      CdnFormat.webp,
      if (server && member.avatar?.isAnimated == true) CdnFormat.gif,
      if (user.avatar.isAnimated) CdnFormat.gif,
    };

    final avatarUrls = [for (final format in formats) (format, getAvatar(member, server, user).get(format: format, size: size))];

    final embed = EmbedBuilder(
      author: EmbedAuthorBuilder(name: ctx.guild.t.commands.avatar.avatarOf(user: user.globalName ?? user.tag)),
      description:
          '${ctx.guild.t.commands.avatar.displayError(url: avatarUrls.last.$2)}\n\nFormat: ${avatarUrls.map((e) => '[${e.$1.name}](${e.$2})').join(' • ')}',
      image: EmbedImageBuilder(url: avatarUrls.last.$2),
      color: user.accentColor,
    );

    await ctx.respond(MessageBuilder(embeds: [embed]));
  }),
  checks: [BasePermissionsCheck(_avatarCommandPermissions), BaseSelfPermissionsCheck(_avatarCommandClientPermissions)],
  options: KiwiiCommandOptions(
    permissions: _avatarCommandPermissions,
    clientPermissions: _avatarCommandClientPermissions,
    usage: '<user> <size:16..4096> <server>',
    examples: [
      (command: "@lexedia", description: "Get the avatar of @lexedia"),
      (command: "@user 2048", description: "Get the avatar of @user, with a size of 2048"),
      (command: "@user 557 true", description: "Get the guild-avatar of @user, with a size of 512"),
    ],
  ),
);

CdnAsset getAvatar(Member member, [bool server = false, User? user]) => switch (member) {
  Member(:final avatar?) when server => avatar,
  Member(:final avatar) when avatar == null || !server => user!.avatar,
  _ => throw 'noop',
};
