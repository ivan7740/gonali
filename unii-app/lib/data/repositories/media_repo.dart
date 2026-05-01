import 'package:dio/dio.dart';

class UploadedMedia {
  const UploadedMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.sizeBytes,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
    id: (json['id'] as num).toInt(),
    mediaType: json['media_type'] as String,
    url: json['url'] as String,
    sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  );

  final int id;
  final String mediaType;
  final String url;
  final int? sizeBytes;
}

class MediaRepo {
  MediaRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UploadedMedia> uploadBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/upload',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = res.data;
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return UploadedMedia.fromJson(body['data'] as Map<String, dynamic>);
  }
}
