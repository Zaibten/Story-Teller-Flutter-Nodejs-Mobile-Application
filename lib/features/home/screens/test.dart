import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewPage extends StatefulWidget {
  static const String routeName = '/new-page';

  const NewPage({Key? key}) : super(key: key);

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  final TextEditingController _controller = TextEditingController();

  String story = "";
  List panels = [];
  double progress = 0;
  bool isLoading = false;

  final String baseUrl = "http://10.189.144.221:9000";

  /// IMAGE BUILDER (FAST CDN)
  Widget buildImage(String image) {
    if (image.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Image.network(
      image,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image),
      ),
    );
  }

  /// 🚀 STREAM API
  Future<void> generateComicStream() async {
    String prompt = _controller.text.trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter prompt first")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      story = "";
      panels = [];
      progress = 0;
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
              }

              /// INITIAL PANELS
              if (data["panels"] != null) {
                panels = List.from(data["panels"]);
              }

              /// 🔥 UPDATE SINGLE IMAGE (FAST)
              if (data["panelIndex"] != null && data["image"] != null) {
                int index = data["panelIndex"];
                if (index < panels.length) {
                  panels[index]["image"] = data["image"];
                }
              }

              if (data["step"] == "done") {
                isLoading = false;
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Story",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(story),
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
                          child: buildImage(panel["image"] ?? ""),
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
              )
            ]
          ],
        ),
      ),
    );
  }
}