import 'dart:async';
import 'dart:typed_data';

import 'package:signed_fractal/signed_fractal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

extension NetExt on NodeFractal {
  net(MP m) async {
    final uri = Uri.parse('https://$name/${this['path']}');
    final headers = <String, String>{};
    /*
    bool isJson = true;
    final headers = <String, String>{
      if (isJson) "Content-Type": "application/json",
      if (isJson) "Accept": "application/json",
    };

    if (resolve('bearer') case String bearer) {
      headers['Authorization'] = 'Bearer $bearer';
    }
    */

    http.BaseResponse? re;
    switch (m) {
      case {'method': 'post', 'body': String s}:
        re = await http.post(
          uri,
          headers: headers,
          body: s,
        );
      case {'method': 'put', 'body': Uint8List b}:
        re = await http.put(
          uri,
          headers: headers,
          body: b,
        );
      case {'method': 'post', 'body': Uint8List b}:
        final rq = http.MultipartRequest('POST', uri);
        rq.headers.addAll(headers);
        rq.fields.addAll(m['fields'] ?? {});
        final f = http.MultipartFile.fromBytes(
          'file',
          b,
          filename: 'test.jpg',
        );
        rq.files.add(f);
        re = await rq.send();
      default:
        re = await http.get(
          uri,
          headers: headers,
        );
    }

    if (re.statusCode == 200) {
      final data = switch (re.headers['content-type']) {
        'application/json' when re is http.StreamedResponse => json.decode(
            await re.stream.bytesToString(),
          ),
        'application/json' when re is http.Response => json.decode(re.body),
        'image/jpeg' || 'image/gif' || 'image/png' => ImageF.bytes(
            await _reBytes(re) as Uint8List,
          ),
        _ => _reBytes(re),
      };
      return data;
    } else {
      throw ('${re.reasonPhrase}');
    }
  }

  static Future<Uint8List?> _reBytes(http.BaseResponse re) async =>
      switch (re) {
        http.StreamedResponse sre => await sre.stream.toBytes(),
        http.Response re => re.bodyBytes,
        _ => null,
      };
}
