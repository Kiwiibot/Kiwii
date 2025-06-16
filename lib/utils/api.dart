import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../src/settings.dart';

final apiClient = ApiClient(apiUrl);

class ApiClient {
  final Uri baseUri;

  final client = http.Client();

  ApiClient(this.baseUri);

  Future<(String, Uint8List)> aceAttorney(String text, {String? character}) => post(
    '/image/ace_attorney',
    texts: [text],
    options: {
      if (character != null && ["phoenix", "edgeworth", "godot", "apollo"].contains(character)) 'character': character,
    },
  );

  Future<(String, Uint8List)> always(Object image, {String? mode}) => post(
    '/image/always',
    images: [image],
    options: {
      if (mode != null && ['loop', 'normal', 'circle'].contains(mode)) 'mode': mode,
    },
  );
  Future<(String, Uint8List)> anyaSuki(Object image, [String? text]) => post('/image/anya_suki', images: [image], texts: [if (text != null) text]);
  Future<(String, Uint8List)> aronaThrow(Object image) => post('/image/arona_throw', images: [image]);
  Future<(String, Uint8List)> capooDraw(Object image) => post('/image/capoo_draw', images: [image]);
  Future<(String, Uint8List)> capooPoint(Object image) => post('/image/capoo_point', images: [image]);

  Future<(String, Uint8List)> bite(Object image) => post('/image/bite', images: [image]);
  Future<(String, Uint8List)> blamedMahiro(String text) => post('/image/blamed_mahiro', texts: [text]);
  Future<(String, Uint8List)> bounce(Object image) => post('/image/bounce', images: [image]);
  Future<(String, Uint8List)> bocchiDraft(Object image) => post('/image/bocchi_draft', images: [image]);
  Future<(String, Uint8List)> funnyMirror(Object image) => post('/image/funny_mirror', images: [image]);
  Future<(String, Uint8List)> jerkOff(Object image) => post('/image/jerk_off', images: [image]);
  Future<(String, Uint8List)> remoteControl(Object image) => post('/image/remote_control', images: [image]);
  Future<(String, Uint8List)> thinkWhat(Object image) => post('/image/think_what', images: [image]);

  Future<(String, Uint8List)> bubbleTea(Object image, {String? position}) => post(
    '/image/bubble_tea',
    images: [image],
    options: {
      if (position != null && ['left', 'right', 'both'].contains(position)) 'position': position,
    },
  );
  Future<(String, Uint8List)> caption(Object image, String text, {String? font}) => post(
    '/image/caption',
    images: [image],
    texts: [text],
    options: {
      if (font != null && ["futura", "comic sans ms", "impact", "times", "roboto", "ubuntu", "helvetica", "arial"].contains(font)) 'font': font,
    },
  );
  Future<(String, Uint8List)> eject(Object image, String text, {String? seed}) =>
      post('/image/eject', images: [image], texts: [text], options: {if (seed != null) 'seed': seed});
  Future<(String, Uint8List)> illegal(String text) => post('/image/illegal', texts: [text]);
  Future<(String, Uint8List)> petpet(Object image, {bool circle = false}) async => post('/image/petpet', images: [image], options: {'circle': circle});

  Future<(String, Uint8List)> post(
    String route, {
    List</* Uint8List | String | Uri */ dynamic>? images,
    List<String>? texts,
    Map<String, Object>? options,
  }) async {
    Map<String, Object> payload = {
      'images': [
        if (images?.isNotEmpty == true)
          for (final img in images!)
            {
              'name': 'file_${Random().nextInt(555).toRadixString(16)}',
              'type': img is Uint8List ? 'data' : 'url',
              if (img is String || img is Uri) 'url': img.toString(),
              if (img is Uint8List) 'data': base64.encode(img),
            },
      ],
      'texts': [...?texts],
      'options': {...?options},
    };

    final response = await client.post(baseUri.replace(path: route), body: json.encode(payload), headers: {'Content-Type': 'application/json'});

    if (response.statusCode >= 400) {
      throw json.decode(response.body);
    }

    final ext = response.headers['content-type']?.split(';').first.split('/').last;

    return (ext ?? 'png', response.bodyBytes);
  }

  Future<(String, Uint8List)> rotate3d(Object image) => post('/image/rotate_3d', images: [image]);
}
