import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/settings_page/subpage/ai_chat_page.dart';
import 'package:anx_reader/providers/ai_cache_count.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
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

  // Ollama 專用輔助方法
  bool _isDropdownField(String key) {
    return key == "enable_thinking" || key == "hide_thinking";
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
            : null,
      ),
      onChanged: (value) {
        services[currentIndex]["config"][key] = value;
      },
    );
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
    super.initState();
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
          for (var key in services[currentIndex]["config"].keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOllama && _isDropdownField(key))
                    _buildDropdownField(key)
                  else
                    _buildTextField(key),
                  if (isOllama && _getFieldHelpText(key).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getFieldHelpText(key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                            },
                          );
                        } else {
                          showSettings = true;
                          currentIndex = index;
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
