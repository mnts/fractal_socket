import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:fractal/types/file.dart';
import 'package:signed_fractal/api.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'service.dart';

class StorjFApi {
  // Storj S3 configuration
  String accessKey;
  String secretKey;
  String region;
  static const endpoint = 'https://gateway.storjshare.io';

  StorjFApi({
    this.region = '',
    required this.accessKey,
    required this.secretKey,
  }) {
    map[accessKey] = this;
  }

  static Map<String, StorjFApi> map = {};

  static init() {
    FractalAPI.cmds['generateUploadUrl'] = (m, s) async {
      final api = StorjFApi.map[m['key']];
      if (api == null) return {'error': 'wrong key'};
      final url = api.generatePresignedUrl(m['bucket'], m['file']);
      return (url == null) ? {'error': 'wrong credentials'} : {'url': url};
    };
  }

  String? generatePresignedUrl(
    String bucketName,
    String fileName,
  ) {
    try {
      // Generate pre-signed URL
      final credentials = AWSCredentials(accessKey, secretKey);
      final provider = AWSCredentialsProvider(credentials);
      final signer = AWSSigV4Signer(credentialsProvider: provider);

      final scope = AWSCredentialScope(
        region: region,
        service: AWSService.s3,
      );

      final rq = AWSHttpRequest.put(
        Uri.parse('$endpoint/$bucketName/$fileName'),
        headers: {
          'host': Uri.parse(endpoint).host,
        },
      );

      final preUri = signer.presignSync(
        rq,
        credentialScope: scope,
        expiresIn: Duration(days: 1),
        serviceConfiguration: ServiceConfiguration(
          signBody: false,
        ),
      );

      return preUri.toString();
    } catch (e) {
      return null;
    }
  }

  /*https://gateway.storjshare.io/fractal2d/pVRpXbxc3NKnh1ru1oUcF.png
  ?X-Amz-Date=20250115T083423Z
  &X-Amz-SignedHeaders=host
  &X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=jugkzdx7khfonqpglyczw5k7fw6a%2F20250115%2Fglobal%2Fs3%2Faws4_request
  &X-Amz-Expires=3600
  &X-Amz-Signature=85e7f0af0df765715d023b02d8602f2c31cb5e6d32c00013c1c17c9e1e0b4bbe


  https://gateway.storjshare.io/demo-bucket/my-file.txt
  &X-Amz-Date=20220728T214316Z
  &X-Amz-SignedHeaders=host
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=jx6hia24r2va4aa4iwwinwzqofoa%2F20220728%2Fus-1%2Fs3%2Faws4_request
  &X-Amz-Expires=3600
  &X-Amz-Signature=ec5555fc80e48dfb0c97901c0d6ff66c35fce07457ab7b41592265878ea21698
  */
}

class StorjServiceF extends ServiceF {
  final String bucket;

  @override
  Future<String?> upload(FileF ff) async {
    //final ext = p.extension(ff.fileName);
    final fileName = ff.name;
    final uri = await uploadUri(fileName);
    await http.put(uri, body: ff.bytes);
    return 'sj://$bucket/$fileName';
  }

  StorjServiceF({
    required this.bucket,
    required super.downloadUri,
    required super.uploadUri,
  });
}
