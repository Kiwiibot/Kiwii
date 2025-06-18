import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import '../../kiwii.dart';
import '../../utils/api.dart';

final _imagesCommandPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.attachFiles;
final _imagesCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

typedef Img = ({String d, String opts});

const imgs = <String, Img>{
  'always': (d: 'Have I always been?', opts: 'image'),
  'anya-suki': (d: 'The "Anya Likes This" meme', opts: '[image] <text>'),
  'bocchi-draft': (d: 'Displays Hitori Gotō displaying an image', opts: '[image]'),
  'bounce': (d: 'Makes an image bounce', opts: '[image]'),
  'think-what': (d: 'The meme where a girl is thinking about marriage while the guy thinks about other things', opts: '[image]'),
  'petpet': (d: 'The petpet meme', opts: 'image'),
  'rotate3d': (d: 'Rotates the provided image in 3D', opts: '[image]'),
  'funny-mirror': (d: 'Makes the provided image acts funky (idk, try it)', opts: '[image]'),
  'remote-control': (d: 'Yeah.. this exists', opts: '[image]'),
  'bubble-tea': (d: 'Applies a bubble tea glass on the image', opts: '[image] <mode=left|right|both>'),
  'bite': (d: 'Nom nom nom. :3', opts: '[image]'),
  'arona-throw': (d: 'Arona throws the provided image', opts: '[image]'),
  'eject': (d: 'Ejects someone, or the provided image with text', opts: '<image> <text=username>'),
  'capoo-draw': (d: 'Capoo draws you', opts: '[image]'),
  'capoo-point': (d: 'Capoo point', opts: '[image]'),
  'illegal': (d: 'Show trump writing the provided text', opts: '[text]'),
  'ace-attorney': (d: 'Write text to an ace-attorney character', opts: '[text] <character=phoenix|appolo|edgeworth|godot>'),
  'blamed-mahiro': (d: 'Blames Mahiro because of the provided text', opts: '[text]'),
  'atri-pillow': (d: 'Shows atri with a pillow', opts: '[text] <mode=yes|no>'),
  'colour-cycle': (d: 'Alters the hue of the provided image', opts: '[image]'),
  'rotating-globe': (d: 'Transforms the provided image in a rotating globe', opts: '[image]'),
  'wave': (d: 'Makes the provided image wavy/dizzy', opts: '[image]'),
  'pixelate': (d: 'Pixelate the provided image', opts: '[image]'),
  'prism': (d: 'Idk, but it looks dope', opts: '[image]'),
  'jitter': (d: 'Makes the provided image jitter', opts: '[image]'),
  'scanlines': (d: 'Makes the provided image looks like from a CRT TV', opts: '[image]'),
  'random-block-shuffle': (d: 'Divide the provided image in smaller chunks and shuffle them', opts: '[image]'),
  'gif': (d: 'Transforms the provided image in a gif to be favouritable', opts: '[image]'),
};

Iterable<CommandOptionChoiceBuilder<dynamic>> autocompleteCallback(AutocompleteContext ctx) {
  final opt = ctx.currentValue.toLowerCase().trim();

  if (opt.isEmpty) {
    return imgs.keys.take(25).map((e) => CommandOptionChoiceBuilder(name: e, value: e));
  }

  final f = imgs.keys.where((e) => e.startsWith(opt));

  return f.take(25).map((e) => CommandOptionChoiceBuilder(name: e, value: e));
}

final imagesCommand = ChatCommand(
  'images',
  'Show the images to use (idk im so done)',
  id('images', (ChatContext ctx, @Autocomplete(autocompleteCallback) @Description('The image to get info of') String image) async {
    final img = imgs[image]!;
    final (ext, preview) = await apiClient.preview(image.replaceAll('-', '_'));
    final filename = '$image.$ext';
    await ctx.respond(
      MessageBuilder(
        embeds: [
          EmbedBuilder(
            title: image,
            description: img.d,
            image: EmbedImageBuilder(url: Uri(scheme: 'attachment', host: filename)),
            footer: EmbedFooterBuilder(text: 'Options: `${img.opts}`'),
          ),
        ],
        attachments: [AttachmentBuilder(data: preview, fileName: filename)],
      ),
    );
  }),
  checks: [BasePermissionsCheck(_imagesCommandPermissions), BaseSelfPermissionsCheck(_imagesCommandClientPermissions)],
  options: KiwiiCommandOptions(
    permissions: _imagesCommandPermissions,
    clientPermissions: _imagesCommandClientPermissions,
    usage: 'images',
    type: CommandType.slashOnly,
    examples: [(command: 'images', description: 'Dont be stupid')],
  ),
);
