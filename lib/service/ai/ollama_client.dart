import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'ai_client.dart';
import 'ai_dio.dart';
import 'package:dio/dio.dart';

/// NDJSON 處理結果
class _NDJSONProcessResult {
  final List<String> contents;
  final String leftover;
  final bool isDone;

  _NDJSONProcessResult(this.contents, this.leftover, this.isDone);
}

/// Ollama AI 客戶端實作
///
/// 支援功能：
/// - 双端點支援：/api/chat 和 /api/generate
/// - 串流處理：Ollama NDJSON 格式
/// - 思維模式：DeepSeek-R1 等思維模型支援
/// - 記憶體管理：keep_alive 參數控制
/// - 錯誤處理：詳細錯誤訊息和狀態碼處理
/// - 超時控制：可配置的請求超時
class OllamaClient extends AiClient {
  OllamaClient(super.config) {
    _validateConfiguration();
  }

  /// 驗證配置參數
  void _validateConfiguration() {
    if (url.isEmpty) {
      throw ArgumentError('Ollama server URL is required');
    }
    if (model.isEmpty) {
      throw ArgumentError('Model name is required');
    }

    // 設置預設值
    _setDefaultValues();
  }

  /// 設置預設值
  void _setDefaultValues() {
    // 如果 URL 不包含端點，預設使用 /api/chat
    if (!url.contains('/api/')) {
      final baseUrl =
          url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      config['url'] = '$baseUrl/api/chat';
    }
  }

  @override
  Map<String, String> getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    // 處理基本身份驗證
    final basic = config['basic_auth'];
    if (basic is String && basic.isNotEmpty) {
      final credentials = base64Encode(utf8.encode(basic));
      headers['Authorization'] = 'Basic $credentials';
    }

    // 處理 API 金鑰驗證（如果需要）
    final apiKey = config['api_key'];
    if (apiKey is String && apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY') {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    return headers;
  }

  // 思維標籤狀態追蹤
  bool _inThinkingMode = false;
  final StringBuffer _thinkingBuffer = StringBuffer();
  final StringBuffer _finalBuffer = StringBuffer();

  /// 是否啟用思維模式解析
  bool get _enableThinkingMode {
    final value = config['enable_thinking'];
    if (value == true) return true;
    if (value == false) return false;
    if (value is String) {
      final stringValue = value as String;
      return stringValue.toLowerCase() == 'true';
    }
    return false;
  }

  /// 是否隱藏思維內容（只返回最終答案）
  bool get _hideThinking {
    final value = config['hide_thinking'];
    if (value == true) return true;
    if (value == false) return false;
    if (value is String) {
      final stringValue = value as String;
      return stringValue.toLowerCase() == 'true';
    }
    return false;
  }

  /// 獲取超時設定（毫秒）
  int get _requestTimeout {
    final timeout = config['timeout'];
    if (timeout is int) {
      return timeout as int;
    }
    if (timeout is String) {
      final stringValue = timeout as String;
      final parsed = int.tryParse(stringValue);
      if (parsed != null) {
        return parsed;
      }
    }
    return 30000; // 預設 30 秒
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    String? rawContent;

    // 從不同端點提取內容
    final msg = json['message'];
    if (msg is Map && msg['content'] is String) {
      // /api/chat 端點
      rawContent = msg['content'] as String;
    } else if (json['response'] is String) {
      // /api/generate 端點
      rawContent = json['response'] as String;
    }

    if (rawContent == null || rawContent.isEmpty) {
      return null;
    }

    // 如果禁用思維模式，直接返回原始內容
    if (!_enableThinkingMode) {
      return rawContent;
    }

    // 處理思維標籤
    return _processThinkingContent(rawContent);
  }

  /// 處理包含思維標籤的內容
  String? _processThinkingContent(String content) {
    const thinkStart = '<think>';
    const thinkEnd = '</think>';

    String remaining = content;
    String output = '';

    while (remaining.isNotEmpty) {
      if (!_inThinkingMode) {
        // 在非思維模式中，查找思維開始標籤
        final startIndex = remaining.indexOf(thinkStart);
        if (startIndex == -1) {
          // 沒有思維標籤，整段都是最終內容
          _finalBuffer.write(remaining);
          if (!_hideThinking || _finalBuffer.isNotEmpty) {
            output += remaining;
          }
          remaining = '';
        } else {
          // 找到思維開始標籤
          final beforeThink = remaining.substring(0, startIndex);
          if (beforeThink.isNotEmpty) {
            _finalBuffer.write(beforeThink);
            if (!_hideThinking || _finalBuffer.isNotEmpty) {
              output += beforeThink;
            }
          }
          _inThinkingMode = true;
          remaining = remaining.substring(startIndex + thinkStart.length);
        }
      } else {
        // 在思維模式中，查找思維結束標籤
        final endIndex = remaining.indexOf(thinkEnd);
        if (endIndex == -1) {
          // 沒有結束標籤，整段都是思維內容
          _thinkingBuffer.write(remaining);
          if (!_hideThinking) {
            output += remaining;
          }
          remaining = '';
        } else {
          // 找到思維結束標籤
          final thinkContent = remaining.substring(0, endIndex);
          if (thinkContent.isNotEmpty) {
            _thinkingBuffer.write(thinkContent);
            if (!_hideThinking) {
              output += thinkContent;
            }
          }
          _inThinkingMode = false;
          remaining = remaining.substring(endIndex + thinkEnd.length);
        }
      }
    }

    return output.isNotEmpty ? output : null;
  }

  /// 重設思維模式狀態
  void _resetThinkingState() {
    _inThinkingMode = false;
    _thinkingBuffer.clear();
    _finalBuffer.clear();
  }

  /// 判斷是否使用 /api/chat 端點（預設）或 /api/generate 端點
  bool get _isChatEndpoint {
    return url.contains('/api/chat') || !url.contains('/api/generate');
  }

  @override
  Map<String, dynamic> generateRequestBody(
    List<Map<String, dynamic>> messages,
  ) {
    final body = <String, dynamic>{
      'model': model,
      'stream': true,
    };

    // 添加 keep_alive 參數以優化模型記憶體管理
    final keepAlive = config['keep_alive'];
    if (keepAlive != null) {
      body['keep_alive'] = keepAlive;
    } else {
      body['keep_alive'] = '5m'; // Ollama 預設值
    }

    // 根據端點類型生成不同的請求體
    if (_isChatEndpoint) {
      // /api/chat 端點使用 messages 陣列
      body['messages'] = messages;
    } else {
      // /api/generate 端點使用單一 prompt
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        body['prompt'] = lastMessage['content'] ?? '';

        // 如果有系統訊息，添加為 system 參數
        final systemMessage = messages.firstWhere(
          (msg) => msg['role'] == 'system',
          orElse: () => <String, dynamic>{},
        );
        if (systemMessage.isNotEmpty) {
          body['system'] = systemMessage['content'];
        }
      }
    }

    // 添加其他可選參數
    final options = config['options'];
    if (options != null && options is Map) {
      body['options'] = options;
    }

    return body;
  }

  /// 獨立處理 Ollama NDJSON 串流回應
  @override
  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    // 重設思維模式狀態
    _resetThinkingState();

    final dio = AiDio.instance.dio;
    String leftoverBuffer = '';
    bool streamCompleted = false;

    try {
      // 驗證配置
      if (url.isEmpty || model.isEmpty) {
        yield* Stream.error('Invalid configuration: URL or model is empty');
        return;
      }

      final requestBody = generateRequestBody(messages);
      final response = await dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: Duration(milliseconds: _requestTimeout),
          receiveTimeout: Duration(milliseconds: _requestTimeout * 2),
        ),
      );

      // 處理 HTTP 錯誤
      if (response.statusCode != 200) {
        final errorBody = await _readErrorResponse(response);
        final errorMessage =
            _formatErrorMessage(response.statusCode!, errorBody);
        yield* Stream.error(errorMessage);
        return;
      }

      // 處理成功回應的串流數據
      final byteStream = response.data.stream as Stream<Uint8List>;

      await for (final chunk in byteStream) {
        if (streamCompleted) break;

        final chunkText = _safeUtf8Decode(chunk);
        leftoverBuffer += chunkText;

        // 按行處理 NDJSON
        final processResult = _processNDJSONLines(leftoverBuffer);
        leftoverBuffer = processResult.leftover;

        for (final content in processResult.contents) {
          if (content.isNotEmpty) {
            yield content;
          }
        }

        if (processResult.isDone) {
          streamCompleted = true;
          break;
        }
      }

      // 處理最後的緩衝區殘留
      if (leftoverBuffer.trim().isNotEmpty && !streamCompleted) {
        final finalContent = _processFinalBuffer(leftoverBuffer);
        if (finalContent != null && finalContent.isNotEmpty) {
          yield finalContent;
        }
      }
    } catch (e) {
      yield* Stream.error('Request failed: ${e.toString()}');
    }
  }

  /// 安全的 UTF-8 解碼
  String _safeUtf8Decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      return String.fromCharCodes(bytes);
    }
  }

  /// 讀取錯誤回應體
  Future<String> _readErrorResponse(Response response) async {
    try {
      if (response.data?.stream != null) {
        final errorBytes = await response.data.stream.fold<List<int>>(
            <int>[], (previous, element) => previous..addAll(element));
        return _safeUtf8Decode(Uint8List.fromList(errorBytes));
      }
      return response.data?.toString() ?? 'Unknown error';
    } catch (e) {
      return 'Error reading response: $e';
    }
  }

  /// 格式化錯誤訊息
  String _formatErrorMessage(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return 'Authentication failed: Invalid API key or credentials';
      case 403:
        return 'Access forbidden: Check your permissions';
      case 404:
        return 'Model not found: $model. Please check if the model is available';
      case 429:
        return 'Rate limit exceeded: Too many requests';
      case 503:
        return 'Service unavailable: Server is overloaded. Please try again later';
      default:
        return 'HTTP Error $statusCode: $body';
    }
  }

  /// 處理 NDJSON 行
  _NDJSONProcessResult _processNDJSONLines(String buffer) {
    final lines = buffer.split(RegExp(r'\r?\n'));
    final leftover = lines.removeLast(); // 保留最後一行作為緩衝
    final contents = <String>[];
    bool isDone = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;

        // 檢查是否為結束信號
        if (json['done'] == true) {
          isDone = true;
          continue;
        }

        // 提取和處理內容
        final content = extractContent(json);
        if (content != null) {
          contents.add(content);
        }
      } catch (e) {
        // JSON 解析失敗，忽略這一行
        continue;
      }
    }

    return _NDJSONProcessResult(contents, leftover, isDone);
  }

  /// 處理最後緩衝區的殘留內容
  String? _processFinalBuffer(String buffer) {
    final trimmed = buffer.trim();
    if (trimmed.isEmpty) return null;

    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      return extractContent(json);
    } catch (e) {
      // 無法解析為 JSON，返回 null
      return null;
    }
  }
}
