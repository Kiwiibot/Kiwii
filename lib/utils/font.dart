const weights = {
  100: 'thin',
  200: 'extraLight',
  300: 'light',
  400: 'regular',
  500: 'medium',
  600: 'semiBold',
  700: 'bold',
  800: 'extraBold',
  900: 'heavy',
  950: 'extraBlack',
};

const fallbacks = ['Symbola', 'Noto-CJK'];

typedef Metadata = ({String? name, String style, int weight, String type});

class Font {
  final String path;
  final String fileName;
  final String name;
  final String type;
  final int weight;
  final String style;
  late final List<String> fallbacks;

  get fileNameNoExtension => fileName.replaceAll(RegExp(r'(\.(otf|ttf))$'), '');

  Font({
    required this.path,
    required this.fileName,
    required this.type,
    required this.weight,
    required this.style,
    required Metadata metadata,
  }) : name = metadata.name ?? fileName {
    fallbacks = fallbacks.where((f) => f != fileNameNoExtension).toList();
  }
}
