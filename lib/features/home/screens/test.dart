import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

class NewPage extends StatefulWidget {
  static const String routeName = '/new-page';
  const NewPage({Key? key}) : super(key: key);

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  String story = "";
  List panels = [];
  double progress = 0;
  bool isLoading = false;
  String generationTime = "";

  // Reading state
  bool isReading = false;
  bool isPaused = false;
  int currentWordIndex = -1;
  List<String> storyWords = [];
  List<int> wordStartIndices = []; // character index where each word starts

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final String baseUrl = "http://192.168.100.97:9000";

  @override
  void initState() {
    super.initState();
    _initTts();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _stopReading(reset: true);
    _flutterTts.stop();
    _bounceController.dispose();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.1);
  }

  /// Prepares word boundaries from the story text
  void _prepareWordBoundaries() {
    if (story.isEmpty) return;
    storyWords = story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    wordStartIndices.clear();

    int currentPos = 0;
    for (int i = 0; i < storyWords.length; i++) {
      wordStartIndices.add(currentPos);
      // Move past the word and any following whitespace
      currentPos += storyWords[i].length;
      if (i < storyWords.length - 1) {
        // Skip exactly one space between words (assumes standard spacing)
        currentPos += 1;
      }
    }
  }

  void _startReading() async {
    if (story.isEmpty) return;
    if (isReading && !isPaused) return;

    if (storyWords.isEmpty || wordStartIndices.isEmpty) {
      _prepareWordBoundaries();
    }

    if (currentWordIndex < 0 || !isPaused) {
      currentWordIndex = 0;
    }
    if (currentWordIndex >= storyWords.length) {
      currentWordIndex = 0;
    }

    setState(() {
      isReading = true;
      isPaused = false;
    });

    // Set up progress handler to sync highlighting with the spoken voice
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (!isReading || isPaused) return;
      // Find which word contains the current character position (start)
      int newIndex = _getWordIndexAtPosition(start);
      if (newIndex != -1 && newIndex != currentWordIndex) {
        setState(() {
          currentWordIndex = newIndex;
        });
        _triggerBounce();
      }
    });

    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      if (!isPaused) {
        _stopReading(reset: true);
      }
    });

    // Start speaking from the current word
    String remainingText = story.substring(wordStartIndices[currentWordIndex]);
    await _flutterTts.speak(remainingText);
  }

  /// Returns the index of the word that contains the given character position
  int _getWordIndexAtPosition(int charPos) {
    if (wordStartIndices.isEmpty) return -1;
    for (int i = 0; i < wordStartIndices.length; i++) {
      int wordStart = wordStartIndices[i];
      int wordEnd = (i < wordStartIndices.length - 1)
          ? wordStartIndices[i + 1] - 1 // end before next word's start
          : story.length;
      if (charPos >= wordStart && charPos <= wordEnd) {
        return i;
      }
    }
    return -1;
  }

  void _pauseReading() {
    if (!isReading || isPaused) return;
    _flutterTts.stop();
    setState(() {
      isPaused = true;
      isReading = false;
    });
  }

  void _stopReading({bool reset = false}) {
    _flutterTts.stop();
    setState(() {
      isReading = false;
      isPaused = false;
      if (reset) {
        currentWordIndex = -1;
        storyWords = [];
        wordStartIndices = [];
      }
    });
  }

  void _triggerBounce() {
    _bounceController.reset();
    _bounceController.forward();
  }

  Widget _buildHighlightedStory() {
    if (story.isEmpty) return const SizedBox.shrink();

    List<String> words = story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 6.0,
        alignment: WrapAlignment.start,
        children: words.asMap().entries.map((entry) {
          int idx = entry.key;
          String word = entry.value;
          bool isCurrent = (isReading || isPaused) && idx == currentWordIndex;

          Widget wordWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.yellow.shade200 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word,
              style: TextStyle(
                fontSize: isCurrent ? 20 : 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          );

          if (isCurrent) {
            wordWidget = AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: child,
                );
              },
              child: wordWidget,
            );
          }

          return GestureDetector(
            onTap: () {
              if (isReading || isPaused) {
                setState(() {
                  currentWordIndex = idx;
                });
                _stopReading(reset: false);
                _startReading();
              }
            },
            child: wordWidget,
          );
        }).toList(),
      ),
    );
  }

  // Image helpers (unchanged)
  Widget buildFastImage(String imageUrl) {
    if (imageUrl.isEmpty) return _buildBlurPlaceholder();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildBlurPlaceholder(),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image),
      ),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
    );
  }

  Widget _buildBlurPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.grey.shade200),
          ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _precacheImage(String url) {
    if (url.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  Future<void> generateComicStream() async {
    String prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter prompt first")),
      );
      return;
    }

    _stopReading(reset: true);
    setState(() {
      isLoading = true;
      story = "";
      panels = [];
      progress = 0;
      generationTime = "";
    });

    try {
      final request = http.Request(
        "GET",
        Uri.parse("$baseUrl/generate-story-comic-stream?prompt=$prompt"),
      );
      final response = await request.send();

      response.stream.transform(utf8.decoder).listen((chunk) {
        final lines = chunk.split("\n");
        for (var line in lines) {
          if (line.startsWith("data:")) {
            final jsonStr = line.replaceFirst("data:", "").trim();
            if (jsonStr.isEmpty) continue;
            final data = jsonDecode(jsonStr);
            setState(() {
              progress = (data["progress"] ?? progress).toDouble();
              if (data["story"] != null) {
                story = data["story"];
                // Reset word tracking when new story arrives
                storyWords = [];
                wordStartIndices = [];
                currentWordIndex = -1;
              }
              if (data["panels"] != null) panels = List.from(data["panels"]);
              if (data["panelIndex"] != null && data["image"] != null) {
                int index = data["panelIndex"];
                if (index < panels.length) {
                  panels[index]["image"] = data["image"];
                  _precacheImage(data["image"]);
                }
              }
              if (data["step"] == "done") {
                isLoading = false;
                if (data["generationTime"] != null) {
                  generationTime = data["generationTime"];
                }
              }
            });
          }
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Streaming Error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Comic Generator"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter Story Prompt",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: generateComicStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Generate Comic"),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              Column(
                children: [
                  LinearProgressIndicator(value: progress / 100),
                  const SizedBox(height: 8),
                  Text("${progress.toInt()}%"),
                ],
              ),

            if (story.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Story",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: (isReading && !isPaused) ? null : _startReading,
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        tooltip: "Play",
                      ),
                      IconButton(
                        onPressed: (isReading && !isPaused) ? _pauseReading : null,
                        icon: const Icon(Icons.pause, color: Colors.orange),
                        tooltip: "Pause",
                      ),
                      IconButton(
                        onPressed: () => _stopReading(reset: true),
                        icon: const Icon(Icons.stop, color: Colors.red),
                        tooltip: "Stop",
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildHighlightedStory(),
            ],

            if (panels.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Comic Panels",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: panels.map((panel) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: buildFastImage(panel["image"] ?? ""),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                panel["title"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(panel["description"] ?? ""),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (generationTime.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, size: 20, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        "Total generation time: $generationTime",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}