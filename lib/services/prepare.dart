import 'package:fractal/fractal.dart';
import 'package:fractal_socket/services/storj.dart';
import 'package:signed_fractal/models/index.dart';
import 'package:http/http.dart' as http;
import '../index.dart';

class ServicesF {
  static Uri download(String path) {
    final uri = Uri(
      scheme: 'https',
      host: 'storj.set.bond',
      path: path,
    );
    print('Download: $uri');
    return uri;
  }

  static Future<Uri> uplUri(String name) async {
    final re = await http.get(Uri(
      scheme: 'https',
      host: 'us-central1-fractal-447104.cloudfunctions.net',
      path: 'Presign',
      queryParameters: {
        'key': name,
        'method': 'POST',
      },
    ));

    return Uri.parse(re.body);
  }

  static Future init() async {
    final storjService = StorjServiceF(
      bucket: 'frac',
      downloadUri: download,
      uploadUri: uplUri,
    );
    FileF.uploader = storjService.upload;
    FileF.urlFile = storjService.downloadUri;

    /*
    final pinataService = ServiceF(
      jwt:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIxNDgyZGIyNy02NWFiLTQ4YjktOTRjZC1hZGM1MThmNGJhM2MiLCJlbWFpbCI6Im1udGFza0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJGUkExIn1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiMzA1MTViMTRiY2E0MmQ5MzgxZWEiLCJzY29wZWRLZXlTZWNyZXQiOiI0NmEwMTUxZTc5ZDgyNmZlOTU5NWMwN2YyZDkxMmY4YjUyODg3ZWU5ZTljMzdjNmY0YzExMTFmZGUxNjhmNTI1IiwiZXhwIjoxNzY4MTMyMjg3fQ.8wnV3jP6R2ypA9sOPhfB_I8UbTFqG1g-mYU9Bzt5nMo',
      fields: {
        'group_id': '0194552f-d6eb-7954-86c3-0f4efb1d4777',
      },
      uploadUri: Uri.parse('https://uploads.pinata.cloud/v3/files'),
      downloadUri: (String hash) => Uri.parse(
        'https://teal-sour-canidae-362.mypinata.cloud/files/$hash',
      ),
    );
    FileF.uploader = pinataService.upload;
    FileF.urlFile = pinataService.downloadUri;
    */
  }
}
