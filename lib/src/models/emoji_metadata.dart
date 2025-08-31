import 'dart:convert';
import 'dart:io';

class EmojiMetadata {
  final List<String> knownSupportedEmoji;
  final Map<String, EmojiData> data;

  const EmojiMetadata({required this.knownSupportedEmoji, required this.data});

  factory EmojiMetadata.fromJson(Map<String, dynamic> json) {
    return EmojiMetadata(
      knownSupportedEmoji: List.from(json['knownSupportedEmoji']),
      data: Map.fromEntries((json['data'] as Map).entries.map((e) => MapEntry<String, EmojiData>(e.key.toString(), EmojiData.fromJson(e.value as Map)))),
    );
  }

  @override
  String toString() => 'EmojiMetadata(knownSupportedEmoji: $knownSupportedEmoji, data: $data)';
}

class EmojiData {
  final String alt;
  final List<String> keywords;
  final String emojiCodepoint;
  final int gBoardOrder;
  final Map<String, List<EmojiCombination>> combinations;

  const EmojiData({required this.alt, required this.keywords, required this.emojiCodepoint, required this.gBoardOrder, required this.combinations});

  factory EmojiData.fromJson(Map<dynamic, dynamic> json) {
    return EmojiData(
      alt: json['alt'] as String,
      keywords: List.from(json['keywords']),
      emojiCodepoint: json['emojiCodepoint'] as String,
      gBoardOrder: json['gBoardOrder'] as int,
      combinations:
          json['combinations'] == null
              ? {}
              : Map.fromEntries(
                (json['combinations'] as Map).entries.map(
                  (e) => MapEntry<String, List<EmojiCombination>>(
                    e.key.toString(),
                    List<Map<dynamic, dynamic>>.from(e.value).map((item) => EmojiCombination.fromJson(item)).toList(),
                  ),
                ),
              ),
    );
  }

  @override
  String toString() => 'EmojiData(alt: $alt, keywords: $keywords, emojiCodepoint: $emojiCodepoint, gBoardOrder: $gBoardOrder, combinations: $combinations)';
}

class EmojiCombination {
  final String gStaticUrl;
  final String alt;
  final String leftEmoji;
  final String rightEmoji;
  final String leftEmojiCodepoint;
  final String rightEmojiCodepoint;
  final String date;
  final bool isLatest;
  final int gBoardOrder;

  const EmojiCombination({
    required this.gStaticUrl,
    required this.alt,
    required this.leftEmoji,
    required this.rightEmoji,
    required this.leftEmojiCodepoint,
    required this.rightEmojiCodepoint,
    required this.date,
    required this.isLatest,
    required this.gBoardOrder,
  });

  factory EmojiCombination.fromJson(Map<dynamic, dynamic> json) {
    return EmojiCombination(
      gStaticUrl: json['gStaticUrl'] as String,
      alt: json['alt'] as String,
      leftEmoji: json['leftEmoji'] as String,
      rightEmoji: json['rightEmoji'] as String,
      leftEmojiCodepoint: json['leftEmojiCodepoint'] as String,
      rightEmojiCodepoint: json['rightEmojiCodepoint'] as String,
      date: json['date'] as String,
      isLatest: json['isLatest'] as bool,
      gBoardOrder: json['gBoardOrder'] as int,
    );
  }

  @override
  String toString() =>
      'EmojiCombination(gStaticUrl: $gStaticUrl, alt: $alt, leftEmoji: $leftEmoji, rightEmoji: $rightEmoji, leftEmojiCodepoint: $leftEmojiCodepoint, rightEmojiCodepoint: $rightEmojiCodepoint, date: $date, isLatest: $isLatest, gBoardOrder: $gBoardOrder)';
}

EmojiMetadata? _emojiMetadata;

Future<EmojiMetadata> getEmojiMetadata() async {
  if (_emojiMetadata != null) return _emojiMetadata!;

  final jsonString = await File('lib/utils/metadata.json').readAsString();

  final jsonData = json.decode(jsonString) as Map<String, dynamic>;

  _emojiMetadata = EmojiMetadata.fromJson(jsonData);

  return _emojiMetadata!;
}

Future<EmojiData> getEmojiData(String emoji) async {
  final metadata = await getEmojiMetadata();
  final data = metadata.data[emoji.runes.first.toRadixString(16)];

  if (data == null) {
    throw Exception('Emoji data not found for $emoji');
  }

  return data;
}
