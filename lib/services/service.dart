import 'package:fractal/fractal.dart';
import 'package:http/http.dart' as http;

/*
formData.append('file', f);
formData.append("group_id", tck.Group);
fetch("https://uploads.pinata.cloud/v3/files",{
    method: "POST",
    headers: {
    Authorization: `Bearer ${tck.JWT}`,
    },
    body: formData,
  }).then(async function(response,error){
    if(error) {
      console.error("Failed to upload image:", error);
      $btn.blink('red');
    }
  if (!response.ok) {
    $btn.blink('red');
    throw new Error(`Error: ${response.statusText}`);
  }

  const result = await response.json();
  const ipfsHash = result.data.cid;
  var src = 'https://'+tck.GATEWAY+'/files/'+ipfsHash;

0ff9c8ddb5410ac288ee
fe4fbaebdb71545b50035867ce99198ef4ecfff4eff7cb86fd323ba111c8078d
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIxNDgyZGIyNy02NWFiLTQ4YjktOTRjZC1hZGM1MThmNGJhM2MiLCJlbWFpbCI6Im1udGFza0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJGUkExIn1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiMGZmOWM4ZGRiNTQxMGFjMjg4ZWUiLCJzY29wZWRLZXlTZWNyZXQiOiJmZTRmYmFlYmRiNzE1NDViNTAwMzU4NjdjZTk5MTk4ZWY0ZWNmZmY0ZWZmN2NiODZmZDMyM2JhMTExYzgwNzhkIiwiZXhwIjoxNzY4MTQzMzYzfQ.IrXVsXeP2K4M2ZaZwdDXQ6M6RE9elZz8tKs-3GY6b8M
*/

class ServiceF {
  final String? jwt;
  final Map<String, String> fields;
  final Uri Function(String) downloadUri;
  final Future<Uri> Function(String) uploadUri;

  ServiceF({
    this.fields = const {},
    required this.downloadUri,
    required this.uploadUri,
    this.jwt,
  });

  Future<String?> upload(FileF ff) async {
    final uri = await uploadUri(ff.fileName);
    var request = http.MultipartRequest('POST', uri);
    if (jwt != null) request.headers['Authorization'] = "Bearer $jwt";
    request.fields.addAll(fields);

    final f = http.MultipartFile.fromBytes(
      'file',
      ff.bytes,
      filename: 'test.jpg',
    );
    request.files.add(f);

    final re = await request.send();

    if (re.statusCode == 200) {
      //final r = await re.stream.bytesToString();

      var m = {}; //jsonDecode(re.c);

      return m['data']['cid'];
    }
    return null;
  }
}
