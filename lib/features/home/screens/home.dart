import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var textcontroller = TextEditingController();
  bool isLoaded = false;
  List comicPanels = [];
  
  final ScrollController _scrollController = ScrollController();
double comicProgress = 0.0;
bool isGeneratingComic = false;
  // Reused variable (no structure change)
  String generatedCode = "Story will appear here...";

  Future<void> saveStoryToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/generated_story.txt");
      await file.writeAsString(generatedCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Story saved to: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving file")),
      );
    }
  }

Future<void> generateStory() async {
  if (textcontroller.text.isEmpty) return;

  setState(() {
    isLoaded = true;
    isGeneratingComic = true;
    comicProgress = 0;
    generatedCode = "Generating...";
    comicPanels = [];
  });

  final request = http.Request(
    'GET',
    Uri.parse(
      "http://10.189.144.221:9000/generate-story-comic-stream?prompt=${textcontroller.text}"
    ),
  );

  final response = await request.send();

  response.stream
      .transform(utf8.decoder)
      .listen((event) {
    for (var line in event.split("\n")) {
      if (line.startsWith("data:")) {
        final jsonStr = line.replaceFirst("data:", "").trim();

        try {
          final data = jsonDecode(jsonStr);

          setState(() {
            comicProgress = (data["progress"] ?? 0).toDouble() / 100;

            if (data["story"] != null) {
              generatedCode = data["story"];
            }

            if (data["panels"] != null && data["panels"] is List) {
  comicPanels = List.from(data["panels"]);
}
          });

        } catch (e) {}
      }
    }
  });
}
void generateComic() {
  if (comicPanels.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Comic not ready")),
    );
    return;
  }

  showComicModal(comicPanels);
}

void showComicModal(List panels) {
  int currentIndex = 0;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final panel = panels[currentIndex];

       return Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Container(
    padding: const EdgeInsets.all(16),
    height: 500,
    child: Column(
      children: [
        Text(
          panel['title'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // ✅ IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            panel['image'],
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          panel['description'],
          style: const TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),

        const Spacer(),

        // 🔥 NAVIGATION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: currentIndex > 0
                  ? () => setModalState(() => currentIndex--)
                  : null,
              child: const Text("⬅ Prev"),
            ),
            Text("${currentIndex + 1}/${panels.length}"),
            ElevatedButton(
              onPressed: currentIndex < panels.length - 1
                  ? () => setModalState(() => currentIndex++)
                  : null,
              child: const Text("Next ➡"),
            ),
          ],
        )
      ],
    ),
  ),
);},
      );
    },
  );
}

void generateVideo() {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              Text(
                "🎬 Story Video",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Icon(Icons.play_circle_fill, size: 80),
              SizedBox(height: 10),
              Text("Video generation coming soon..."),
            ],
          ),
        ),
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF151F2B), Color(0xFF223447)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                "AI Story Teller",
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  letterSpacing: 1.0,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                "${user.name} • ${user.email}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    setState(() => isLoaded = false);
                    textcontroller.clear();
                    generatedCode = "Story will appear here...";
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 INPUT BOX
              Container(
                height: 350,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Scrollbar(
  controller: _scrollController,
  thumbVisibility: true,
  radius: const Radius.circular(8),
  child: SingleChildScrollView(
    controller: _scrollController,
    child: TextFormField(
      controller: textcontroller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        hintText: 'Write your story prompt here...',
        border: InputBorder.none,
      ),
    ),
  ),
),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔥 GENERATE BUTTON
                    SizedBox(
                      width: 300,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: GlobalVariables.whitecolor,
                          backgroundColor: GlobalVariables.btncolor,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: generateStory,
                        child: const Text("Generate Story"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 OUTPUT
              Container(
                height: 490,
                child: isLoaded
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 300,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                generatedCode,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 🔹 BUTTONS
                       Column(
  children: [
    // 🔹 FIRST ROW (Copy + Save)
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.btncolor,
              foregroundColor: GlobalVariables.whitecolor,
            ),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: generatedCode),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Story copied!")),
              );
            },
            label: const Text('Copy Story'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.btncolor,
              foregroundColor: GlobalVariables.whitecolor,
            ),
            onPressed: saveStoryToFile,
            label: const Text('Save Story'),
          ),
        ),
      ],
    ),

    const SizedBox(height: 15),

    // 🔥 SECOND ROW (Comic + Video)
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_stories),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: generateComic,
            label: const Text('Comic Version'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.movie),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: generateVideo,
            label: const Text('Video'),
          ),
        ),
      ],
    ),
  ],
) ],
                      )
                    : Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: GlobalVariables.whitecolor,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/images/loader.gif"),
                            const Text(
                              '✨ Tell your story with AI',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 139, 139, 139),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}