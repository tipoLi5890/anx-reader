import 'dart:async';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/settings_page/subpage/ai_chat_page.dart';
import 'package:anx_reader/providers/ai_cache_count.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/service/ai/ollama_client.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/widgets/ai_stream.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AISettings extends ConsumerStatefulWidget {
  const AISettings({super.key});

  @override
  ConsumerState<AISettings> createState() => _AISettingsState();
}

class _AISettingsState extends ConsumerState<AISettings> {
  bool showSettings = false;
  int currentIndex = 0;
  late List<Map<String, dynamic>> initialServicesConfig;
  bool _obscureApiKey = true;

  // Ollama 連接狀態管理
  String _ollamaConnectionStatus = 'idle'; // idle, connecting, connected, error
  String _ollamaConnectionError = '';
  List<String> _ollamaModels = [];
  bool _isLoadingModels = false;
  Timer? _urlValidationTimer;
  bool _showAdvancedSettings = false;

  List<Map<String, dynamic>> services = EnvVar.isBeian
      ? [
          {
            "identifier": "openai",
            "title": "通用",
            "logo": "assets/images/commonAi.png",
            "config": {
              "url":
                  "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "qwen-long",
            },
          },
          {
            "identifier": "claude",
            "title": "Claude",
            "logo": "assets/images/claude.png",
            "config": {
              "url": "https://api.anthropic.com/v1/messages",
              "api_key": "YOUR_API_KEY",
              "model": "claude-3-5-sonnet-20240620",
            },
          },
          {
            "identifier": "gemini",
            "title": "Gemini",
            "logo": "assets/images/gemini.png",
            "config": {
              "url":
                  "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "gemini-2.0-flash"
            },
          },
          {
            "identifier": "deepseek",
            "title": "DeepSeek",
            "logo": "assets/images/deepseek.png",
            "config": {
              "url": "https://api.deepseek.com/v1/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "deepseek-chat",
            },
          },
        ]
      : [
          {
            "identifier": "ollama",
            "title": "Ollama",
            "logo": "assets/images/ollama.png",
            "config": {
              "url": "http://localhost:11434",
              "model": "llama3.2",
              "api_key": "",
              "keep_alive": "5m",
              "enable_thinking": "false",
              "hide_thinking": "false",
              "timeout": "30000",
              "basic_auth": "",
            },
          },
          {
            "identifier": "openai",
            "title": "OpenAI",
            "logo": "assets/images/openai.png",
            "config": {
              "url": "https://api.openai.com/v1/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "gpt-4o-mini",
            },
          },
          {
            "identifier": "claude",
            "title": "Claude",
            "logo": "assets/images/claude.png",
            "config": {
              "url": "https://api.anthropic.com/v1/messages",
              "api_key": "YOUR_API_KEY",
              "model": "claude-3-5-sonnet-20240620",
            },
          },
          {
            "identifier": "gemini",
            "title": "Gemini",
            "logo": "assets/images/gemini.png",
            "config": {
              "url":
                  "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "gemini-2.0-flash"
            },
          },
          {
            "identifier": "deepseek",
            "title": "DeepSeek",
            "logo": "assets/images/deepseek.png",
            "config": {
              "url": "https://api.deepseek.com/v1/chat/completions",
              "api_key": "YOUR_API_KEY",
              "model": "deepseek-chat",
            },
          },
        ];

  /*
   * Ollama AI Integration - UI Components
   * Copyright (c) 2025 Genius Holdings Co., Ltd (https://github.com/ezoxygenTeam)
   * Managed by: tipo (LI, CHING-YU) (https://github.com/tipoLi5890)
   * 
   * The following Ollama-specific methods are subject to dual licensing:
   * - Commercial License: Contact Genius Holdings Co., Ltd
   * - AGPL-3.0 License: https://www.gnu.org/licenses/agpl-3.0.html
   * 
   * See LICENSE-OLLAMA-AI.md for complete licensing terms.
   */

  // Ollama 專用輔助方法
  bool _isDropdownField(String key) {
    return key == "enable_thinking" || key == "hide_thinking";
  }

  bool _isBasicOllamaField(String key) {
    return ["url", "model"].contains(key);
  }

  bool _isAdvancedOllamaField(String key) {
    return [
      "api_key",
      "keep_alive",
      "enable_thinking",
      "hide_thinking",
      "timeout",
      "basic_auth"
    ].contains(key);
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case "api_key":
        return "api_key (optional)";
      case "keep_alive":
        return "keep_alive";
      case "enable_thinking":
        return "enable_thinking";
      case "hide_thinking":
        return "hide_thinking";
      case "timeout":
        return "timeout (ms)";
      case "basic_auth":
        return "basic_auth (optional)";
      default:
        return key;
    }
  }

  String _getFieldHelpText(String key) {
    switch (key) {
      case "model":
        return "常見模型：llama3.2, deepseek-r1, qwen2.5, gemma2 等";
      case "api_key":
        return "通常不需要，可留空";
      case "keep_alive":
        return "模型保持在記憶體的時間（如：5m, 1h, -1 表示永久）";
      case "enable_thinking":
        return "啟用思維模式解析（用於 DeepSeek-R1 等思維模型）";
      case "hide_thinking":
        return "隱藏思維過程，只顯示最終答案";
      case "timeout":
        return "請求超時時間（毫秒），預設 30000";
      case "basic_auth":
        return "基本認證，格式：username:password";
      case "url":
        return "Ollama 服務器地址，預設 http://localhost:11434";
      default:
        return "";
    }
  }

  Widget _buildTextField(String key) {
    final isOllama = services[currentIndex]["identifier"] == "ollama";

    return TextField(
      obscureText: key == "api_key" && _obscureApiKey,
      controller: TextEditingController(
          text: services[currentIndex]["config"][key] ??
              initialServicesConfig[currentIndex]["config"][key]),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: _getFieldLabel(key),
        hintText: services[currentIndex]["config"][key],
        suffixIcon: key == "api_key"
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
                icon: _obscureApiKey
                    ? const Icon(Icons.visibility_off)
                    : const Icon(Icons.visibility),
              )
            : isOllama && key == "url"
                ? _buildUrlStatusIcon()
                : null,
      ),
      onChanged: (value) {
        services[currentIndex]["config"][key] = value;

        // Ollama URL 變更時觸發驗證
        if (isOllama && key == "url") {
          _validateOllamaUrl(value);
        }
      },
    );
  }

  Widget _buildUrlStatusIcon() {
    switch (_ollamaConnectionStatus) {
      case 'connecting':
        return const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case 'connected':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'error':
        return Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.link);
    }
  }

  Widget _buildDropdownField(String key) {
    return DropdownButtonFormField<String>(
      value: services[currentIndex]["config"][key] ?? "false",
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: _getFieldLabel(key),
      ),
      items: const [
        DropdownMenuItem(value: "false", child: Text("false")),
        DropdownMenuItem(value: "true", child: Text("true")),
      ],
      onChanged: (value) {
        setState(() {
          services[currentIndex]["config"][key] = value ?? "false";
        });
      },
    );
  }

  Widget _buildOllamaModelField() {
    final currentModel = services[currentIndex]["config"]["model"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_ollamaModels.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _ollamaModels.contains(currentModel) ? currentModel : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "模型選擇",
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            hint: _isLoadingModels
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text("載入模型中..."),
                    ],
                  )
                : const Text("請選擇模型"),
            items: _ollamaModels.map((model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(
                  model,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isLoadingModels
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        services[currentIndex]["config"]["model"] = value;
                      });
                    }
                  },
          )
        else
          TextField(
            controller: TextEditingController(text: currentModel),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "模型名稱",
              hintText: "請輸入模型名稱 (如: llama3.2)",
              suffixIcon: _isLoadingModels
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.edit),
            ),
            onChanged: (value) {
              services[currentIndex]["config"]["model"] = value;
            },
          ),
        if (_ollamaConnectionStatus == 'error')
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _ollamaConnectionError,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        if (_ollamaModels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "找到 ${_ollamaModels.length} 個可用模型",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildOllamaConnectionBanner() {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    switch (_ollamaConnectionStatus) {
      case 'connecting':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        iconColor = Colors.blue;
        icon = Icons.sync;
        title = "正在連接 Ollama 服務...";
        subtitle = "請稍等，正在檢測服務狀態";
        break;
      case 'connected':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        iconColor = Colors.green;
        icon = Icons.check_circle;
        title = "Ollama 服務已連接";
        subtitle = _ollamaModels.isNotEmpty
            ? "發現 ${_ollamaModels.length} 個可用模型"
            : "已連接，正在載入模型列表...";
        break;
      case 'error':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        iconColor = Colors.red;
        icon = Icons.error;
        title = "Ollama 服務連接失敗";
        subtitle = _ollamaConnectionError.isNotEmpty
            ? _ollamaConnectionError
            : "請檢查服務器地址和網絡連接";
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        iconColor = Colors.grey;
        icon = Icons.cloud_off;
        title = "Ollama 服務未連接";
        subtitle = "請輸入正確的服務器地址";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (_ollamaConnectionStatus == 'connecting')
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          else
            Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_ollamaConnectionStatus == 'error')
            TextButton(
              onPressed: () {
                final url = services[currentIndex]["config"]["url"] ?? "";
                _validateOllamaUrl(url);
              },
              child: Text(
                "重試",
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Ollama API 方法
  Future<void> _validateOllamaUrl(String url) async {
    if (url.isEmpty) {
      setState(() {
        _ollamaConnectionStatus = 'idle';
        _ollamaConnectionError = '';
      });
      return;
    }

    // 取消之前的計時器
    _urlValidationTimer?.cancel();

    // 設置防抖動計時器
    _urlValidationTimer = Timer(const Duration(milliseconds: 800), () async {
      setState(() {
        _ollamaConnectionStatus = 'connecting';
        _ollamaConnectionError = '';
      });

      final result = await OllamaClient.validateUrl(url);
      
      if (result['success'] as bool) {
        setState(() {
          _ollamaConnectionStatus = 'connected';
          _ollamaConnectionError = '';
        });

        // 成功連接後自動獲取模型列表
        final baseUrl = result['baseUrl'] as String;
        await _fetchOllamaModels(baseUrl);
      } else {
        setState(() {
          _ollamaConnectionStatus = 'error';
          _ollamaConnectionError = result['error'] as String;
        });
      }
    });
  }

  Future<void> _fetchOllamaModels(String baseUrl) async {
    setState(() {
      _isLoadingModels = true;
    });

    final result = await OllamaClient.fetchModels(baseUrl);
    
    if (result['success'] as bool) {
      final modelNames = result['models'] as List<String>;
      
      // 按受歡迎程度排序模型
      modelNames.sort(
          (a, b) => _getModelPriority(a).compareTo(_getModelPriority(b)));

      setState(() {
        _ollamaModels = modelNames;
        _isLoadingModels = false;

        // 如果當前選擇的模型不在列表中，設置為第一個可用模型
        final currentModel = services[currentIndex]["config"]["model"];
        if (currentModel.isEmpty || !modelNames.contains(currentModel)) {
          if (modelNames.isNotEmpty) {
            services[currentIndex]["config"]["model"] = modelNames.first;
          }
        }
      });
    } else {
      setState(() {
        _isLoadingModels = false;
        _ollamaModels = [];
      });
    }
  }

  // 模型優先級排序（熱門模型優先顯示）
  int _getModelPriority(String modelName) {
    final popularModels = [
      'llama3.2',
      'llama3.1',
      'llama2',
      'deepseek-r1',
      'qwen2.5',
      'gemma2',
      'mistral',
      'phi',
      'codellama',
    ];

    for (int i = 0; i < popularModels.length; i++) {
      if (modelName.toLowerCase().contains(popularModels[i])) {
        return i;
      }
    }
    return popularModels.length; // 未知模型排在最後
  }


  Widget _buildOllamaHelpPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 18,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                "Ollama 設置指南",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            "1. 安裝 Ollama",
            "訪問 https://ollama.ai 下載並安裝 Ollama",
            Icons.download,
          ),
          const SizedBox(height: 8),
          _buildHelpItem(
            "2. 啟動服務",
            "運行 'ollama serve' 或從系統服務啟動",
            Icons.play_arrow,
          ),
          const SizedBox(height: 8),
          _buildHelpItem(
            "3. 下載模型",
            "運行 'ollama pull llama3.2' 下載推薦模型",
            Icons.cloud_download,
          ),
          const SizedBox(height: 8),
          _buildHelpItem(
            "4. 驗證連接",
            "默認地址：http://localhost:11434",
            Icons.link,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    initialServicesConfig = services.map((service) {
      return {
        ...service,
        'config': Map<String, String>.from(service['config']),
      };
    }).toList();
    for (var service in services) {
      for (var key in service["config"].keys) {
        service["config"][key] =
            Prefs().getAiConfig(service["identifier"])[key] ??
                service["config"][key];
      }
    }

    // 為 Ollama 服務初始化連接狀態
    _initializeOllamaService();

    super.initState();
  }

  void _initializeOllamaService() {
    final ollamaIndex =
        services.indexWhere((service) => service["identifier"] == "ollama");
    if (ollamaIndex != -1) {
      final ollamaUrl = services[ollamaIndex]["config"]["url"] ?? "";
      if (ollamaUrl.isNotEmpty && ollamaUrl != "http://localhost:11434") {
        // 如果有自定義 URL，立即驗證
        Future.delayed(const Duration(milliseconds: 500), () {
          _validateOllamaUrl(ollamaUrl);
        });
      } else {
        // 嘗試自動檢測本地 Ollama
        Future.delayed(const Duration(milliseconds: 500), () {
          _validateOllamaUrl("http://localhost:11434");
        });
      }
    }
  }

  void _onOllamaServiceSelected() {
    final ollamaUrl = services[currentIndex]["config"]["url"] ?? "";
    if (ollamaUrl.isNotEmpty) {
      // 驗證現有 URL
      _validateOllamaUrl(ollamaUrl);
    } else {
      // 嘗試默認本地地址
      services[currentIndex]["config"]["url"] = "http://localhost:11434";
      _validateOllamaUrl("http://localhost:11434");
    }
  }

  @override
  void dispose() {
    _urlValidationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> prompts = [
      {
        "identifier": AiPrompts.test,
        "title": L10n.of(context).settings_ai_prompt_test,
        "variables": ["language_locale"],
      },
      {
        "identifier": AiPrompts.summaryTheChapter,
        "title": L10n.of(context).settings_ai_prompt_summary_the_chapter,
        "variables": ["chapter"],
      },
      {
        "identifier": AiPrompts.summaryTheBook,
        "title": L10n.of(context).settings_ai_prompt_summary_the_book,
        "variables": ["book", "author"],
      },
      {
        "identifier": AiPrompts.summaryThePreviousContent,
        "title":
            L10n.of(context).settings_ai_prompt_summary_the_previous_content,
        "variables": ["previous_content"],
      },
      {
        "identifier": AiPrompts.translate,
        "title": L10n.of(context).settings_ai_prompt_translate_and_dictionary,
        "variables": ["text", "to_locale", "from_locale"],
      }
    ];

    Widget aiConfig() {
      final isOllama = services[currentIndex]["identifier"] == "ollama";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              services[currentIndex]["title"],
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (isOllama) _buildOllamaConnectionBanner(),
          // 基礎設置
          if (isOllama) ...[
            // 顯示基礎字段
            for (var key in services[currentIndex]["config"].keys)
              if (_isBasicOllamaField(key))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (key == "model")
                        _buildOllamaModelField()
                      else
                        _buildTextField(key),
                      if (key != "model" && _getFieldHelpText(key).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _getFieldHelpText(key),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
            // 高級設置切換按鈕
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showAdvancedSettings = !_showAdvancedSettings;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAdvancedSettings
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showAdvancedSettings ? "隱藏高級設置" : "顯示高級設置",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 高級設置區域（可摺疊）
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showAdvancedSettings
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "高級設置",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var key in services[currentIndex]["config"].keys)
                          if (_isAdvancedOllamaField(key))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isDropdownField(key))
                                    _buildDropdownField(key)
                                  else
                                    _buildTextField(key),
                                  if (_getFieldHelpText(key).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _getFieldHelpText(key),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            // Ollama 使用指南
            if (_ollamaConnectionStatus == 'idle' ||
                _ollamaConnectionStatus == 'error')
              _buildOllamaHelpPanel(),
          ] else ...[
            // 非 Ollama 服務的原始字段渲染
            for (var key in services[currentIndex]["config"].keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTextField(key),
              ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    Prefs().deleteAiConfig(
                      services[currentIndex]["identifier"],
                    );
                    services[currentIndex]["config"] = Map<String, String>.from(
                        initialServicesConfig[currentIndex]["config"]);
                    setState(() {});
                  },
                  child: Text(L10n.of(context).common_reset)),
              TextButton(
                  onPressed: () {
                    SmartDialog.show(
                      onDismiss: () {
                        AiDio.instance.cancel();
                      },
                      builder: (context) => AlertDialog(
                          title: Text(L10n.of(context).common_test),
                          content: AiStream(
                              prompt: generatePromptTest(),
                              identifier: services[currentIndex]["identifier"],
                              config: services[currentIndex]["config"],
                              regenerate: true)),
                    );
                  },
                  child: Text(L10n.of(context).common_test)),
              TextButton(
                  onPressed: () {
                    Prefs().saveAiConfig(
                      services[currentIndex]["identifier"],
                      services[currentIndex]["config"],
                    );

                    setState(() {
                      showSettings = false;
                    });
                  },
                  child: Text(L10n.of(context).common_save)),
              TextButton(
                  onPressed: () {
                    Prefs().selectedAiService =
                        services[currentIndex]["identifier"];
                    Prefs().saveAiConfig(
                      services[currentIndex]["identifier"],
                      services[currentIndex]["config"],
                    );

                    setState(() {
                      showSettings = false;
                    });
                  },
                  child: Text(L10n.of(context).common_apply)),
            ],
          )
        ],
      );
    }

    var servicesTile = CustomSettingsTile(
        child: AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        if (showSettings) {
                          if (currentIndex == index) {
                            setState(() {
                              showSettings = false;
                            });
                            return;
                          }
                          showSettings = false;
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () {
                              setState(() {
                                showSettings = true;
                                currentIndex = index;
                              });

                              // 切換到 Ollama 時自動驗證連接
                              if (services[index]["identifier"] == "ollama") {
                                _onOllamaServiceSelected();
                              }
                            },
                          );
                        } else {
                          showSettings = true;
                          currentIndex = index;

                          // 首次選擇 Ollama 時自動驗證連接
                          if (services[index]["identifier"] == "ollama") {
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              _onOllamaServiceSelected();
                            });
                          }
                        }

                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Prefs().selectedAiService ==
                                      services[index]["identifier"]
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset(
                              services[index]["logo"],
                              height: 25,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(services[index]["title"]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            !showSettings ? const SizedBox() : aiConfig(),
          ],
        ),
      ),
    ));

    var promptTile = CustomSettingsTile(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          return SettingsTile.navigation(
            title: Text(prompts[index]["title"]),
            onPressed: (context) {
              SmartDialog.show(builder: (context) {
                final controller = TextEditingController(
                  text: Prefs().getAiPrompt(
                    AiPrompts.values[index],
                  ),
                );

                return AlertDialog(
                  title: Text(L10n.of(context).common_edit),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        maxLines: 10,
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Wrap(
                        children: [
                          for (var variable in prompts[index]["variables"])
                            TextButton(
                              onPressed: () {
                                // insert the variables at the cursor
                                if (controller.selection.start == -1 ||
                                    controller.selection.end == -1) {
                                  return;
                                }

                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: controller.selection.start,
                                  ),
                                );

                                controller.text = controller.text.replaceRange(
                                  controller.selection.start,
                                  controller.selection.end,
                                  '{{$variable}}',
                                );
                              },
                              child: Text(
                                '{{$variable}}',
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Prefs().deleteAiPrompt(AiPrompts.values[index]);
                        controller.text = Prefs().getAiPrompt(
                          AiPrompts.values[index],
                        );
                      },
                      child: Text(L10n.of(context).common_reset),
                    ),
                    TextButton(
                      onPressed: () {
                        Prefs().saveAiPrompt(
                          AiPrompts.values[index],
                          controller.text,
                        );
                      },
                      child: Text(L10n.of(context).common_save),
                    ),
                  ],
                );
              });
            },
          );
        },
      ),
    );

    return settingsSections(sections: [
      SettingsSection(
        title: Text(L10n.of(context).settings_ai_services),
        tiles: [
          servicesTile,
          SettingsTile.navigation(
            leading: const Icon(Icons.chat),
            title: Text(L10n.of(context).ai_chat),
            onPressed: (context) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AiChatPage(),
                ),
              );
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text(L10n.of(context).settings_ai_prompt),
        tiles: [
          promptTile,
        ],
      ),
      SettingsSection(
        title: Text(L10n.of(context).settings_ai_cache),
        tiles: [
          CustomSettingsTile(
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(L10n.of(context).settings_ai_cache_size),
                  Text(
                    L10n.of(context).settings_ai_cache_current_size(ref
                        .watch(aiCacheCountProvider)
                        .when(
                            data: (value) => value,
                            loading: () => 0,
                            error: (error, stack) => 0)),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(Prefs().maxAiCacheCount.toString()),
                  Expanded(
                    child: Slider(
                      value: Prefs().maxAiCacheCount.toDouble(),
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      label: Prefs().maxAiCacheCount.toString(),
                      onChanged: (value) {
                        Prefs().maxAiCacheCount = value.toInt();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SettingsTile.navigation(
              title: Text(L10n.of(context).settings_ai_cache_clear),
              onPressed: (context) {
                SmartDialog.show(
                  builder: (context) => AlertDialog(
                    title: Text(L10n.of(context).common_confirm),
                    actions: [
                      TextButton(
                        onPressed: () {
                          SmartDialog.dismiss();
                        },
                        child: Text(L10n.of(context).common_cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(aiCacheCountProvider.notifier).clearCache();
                          SmartDialog.dismiss();
                        },
                        child: Text(L10n.of(context).common_confirm),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    ]);
  }
}
