import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'ai_client.dart';
import 'ai_dio.dart';
import 'package:dio/dio.dart';

class OllamaClient extends AiClient {
  OllamaClient(super.config);

  @override
  Map<String, String> getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final basic = config['basic_auth'];
    if (basic is String && basic.isNotEmpty) {
      final base64 = base64Encode(utf8.encode(basic));
      headers['Authorization'] = 'Basic $base64';
    }
    return headers;
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    // /api/chat
    final msg = json['message'];
    if (msg is Map && msg['content'] is String) {
      return msg['content'] as String;
    }
    // /api/generate
    if (json['response'] is String) {
      return json['response'] as String;
    }
    return null;
  }

  @override
  Map<String, dynamic> generateRequestBody(
    List<Map<String, dynamic>> messages,
  ) {
    return {
      'model': model,
      'stream': true,
      'messages': messages,
    };
  }

  /// 自己處理 NDJSON streaming
  @override
  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    final dio = AiDio.instance.dio;
    String leftover = '';

    try {
      final res = await dio.post(
        url,
        data: generateRequestBody(messages),
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
      );

      if (res.statusCode != 200) {
        // 把錯誤 body 讀完再丟出
        final body = await res.data.stream
            .transform(StreamTransformer<Uint8List, String>.fromHandlers(
              handleData: (data, sink) => sink.add(utf8.decode(data)),
            ))
            .fold<String>('', (p, e) => p + e);
        yield* Stream.error('Error: ${res.statusCode}\n$body');
        return;
      }

      // 正確情況：逐塊讀取 -> 緩衝 -> 按行解析 -> extractContent
      final byteStream = res.data.stream as Stream<Uint8List>;
      await for (final chunk in byteStream.transform(
        StreamTransformer<Uint8List, String>.fromHandlers(
          handleData: (data, sink) => sink.add(utf8.decode(data)),
        ),
      )) {
        leftover += chunk;

        final lines = leftover.split(RegExp(r'\r?\n'));
        leftover = lines.removeLast(); // 最後一個可能是不完整 JSON，留下

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          // Ollama 不會有 "data:" 前綴，也不會有 [DONE]
          try {
            final obj = jsonDecode(trimmed);
            if (obj is Map && obj['done'] == true) {
              // 結束訊號，直接忽略
              continue;
            }
            final content = extractContent(obj);
            if (content != null) yield content;
          } catch (_) {
            // 半截 JSON，留給下一輪
          }
        }
      }

      // 流結束後，再試最後殘留
      if (leftover.trim().isNotEmpty) {
        try {
          final obj = jsonDecode(leftover);
          final content = extractContent(obj);
          if (content != null) yield content;
        } catch (_) {}
      }
    } catch (e) {
      print("testtest | 'Request failed: $e'");
      yield* Stream.error('Request failed: $e');
    } finally {
      // 不在這裡關閉全域 dio
    }
  }
}
