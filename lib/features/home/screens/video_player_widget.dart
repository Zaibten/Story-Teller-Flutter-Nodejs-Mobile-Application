import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoGenerationPage extends StatefulWidget {
  final String? story;
  final List<dynamic>? panels;
  final String? initialPrompt;
  
  const VideoGenerationPage({
    Key? key,
    this.story,
    this.panels,
    this.initialPrompt,
  }) : super(key: key);

  @override
  State<VideoGenerationPage> createState() => _VideoGenerationPageState();
}

class _VideoGenerationPageState extends State<VideoGenerationPage>
    with SingleTickerProviderStateMixin {
  
  static const String _baseUrl = 'http://192.168.100.97:9000';
  
  late TabController _tabController;
  final TextEditingController _promptController = TextEditingController();
  
  // Video generation state
  bool _isGenerating = false;
  double _generationProgress = 0;
  String _generationStatus = '';
  String? _generatedVideoUrl;
  String? _error;
  
  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // Generation history - FIXED: Use proper data types
  List<Map<String, dynamic>> _videoHistory = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.initialPrompt != null) {
      _promptController.text = widget.initialPrompt!;
    }
    
    _loadVideoHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadVideoHistory() async {
    // Load from local storage or API - FIXED: Use DateTime correctly
    setState(() {
      _videoHistory = [
        {
          'id': '1',
          'title': 'My First Story Video',
          'thumbnail': '',
          'url': '',
          'date': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch, // FIXED: Convert to int
        },
      ];
    });
  }
  
  Future<void> _generateVideo() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty && widget.story == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a story idea or use the generated story!')),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _generationProgress = 0;
      _generationStatus = 'Initializing video generation...';
      _error = null;
      _generatedVideoUrl = null;
    });
    
    try {
      // Use Server-Sent Events for progress updates
      final uri = Uri.parse('$_baseUrl/stream-video-generation')
          .replace(queryParameters: {
        'prompt': prompt,
        'story': widget.story ?? prompt,
      });
      
      final request = await http.Client().send(http.Request('GET', uri));
      
      await for (final chunk in request.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = jsonDecode(line.substring(6));
            
            if (data['error'] != null) {
              setState(() => _error = data['error']);
              break;
            }
            
            setState(() {
              _generationProgress = (data['progress'] ?? _generationProgress).toDouble();
              _generationStatus = data['status'] ?? _generationStatus;
              
              if (data['videoUrl'] != null) {
                _generatedVideoUrl = data['videoUrl'];
                _initializeVideoPlayer(data['videoUrl']);
              }
            });
          }
        }
      }
      
    } catch (e) {
      setState(() => _error = 'Failed to generate video: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }
  
  Future<void> _generateVideoFromComic() async {
    if (widget.panels == null || widget.panels!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No comic panels available to generate video!')),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _generationProgress = 0;
      _generationStatus = 'Creating video from your comic...';
      _error = null;
    });
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-video-from-comic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'story': widget.story,
          'panels': widget.panels,
          'style': 'animated',
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          _generatedVideoUrl = data['videoUrl'];
          _generationProgress = 100;
          _generationStatus = 'Video ready!';
        });
        _initializeVideoPlayer(data['videoUrl']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video generated in ${data['duration']} seconds!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = data['error'] ?? 'Generation failed');
      }
    } catch (e) {
      setState(() => _error = 'Failed to generate video: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }
  
  Future<void> _initializeVideoPlayer(String url) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    
    setState(() => _isVideoInitialized = true);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        title: const Text(
          'Video Generator',
          style: TextStyle(
            fontFamily: 'Comic Sans MS',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFF2D55),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'Comic Sans MS',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '🎬 GENERATE', icon: Icon(Icons.movie_creation)),
            Tab(text: '📚 HISTORY', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }
  
  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Story Input Card
          _buildStoryInputCard(),
          
          const SizedBox(height: 16),
          
          // Generate Buttons
          _buildGenerateButtons(),
          
          const SizedBox(height: 16),
          
          // Progress Indicator
          if (_isGenerating) _buildProgressCard(),
          
          // Error Display
          if (_error != null) _buildErrorCard(),
          
          // Video Player
          if (_generatedVideoUrl != null && _isVideoInitialized)
            _buildVideoPlayer(),
          
          // Preview Card
          if (widget.panels != null && widget.panels!.isNotEmpty && !_isGenerating)
            _buildComicPreviewCard(),
        ],
      ),
    );
  }
  
  Widget _buildStoryInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF12072A), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF12072A), offset: Offset(5, 5), blurRadius: 0)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B6FFF), Color(0xFF8B2FFF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create Your Story Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: widget.story != null
                        ? 'Your story is ready! Add any extra details...'
                        : 'Enter your story idea...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF12072A), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF12072A), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                if (widget.story != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF8000), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.book, color: Color(0xFFFF8000), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Current Story',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.story!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenerateButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildGradientButton(
            onPressed: _isGenerating ? null : _generateVideo,
            label: '🎬 Generate Video',
            gradient: const LinearGradient(
              colors: [Color(0xFF2DEB6F), Color(0xFF00CFFF)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (widget.panels != null && widget.panels!.isNotEmpty)
          Expanded(
            child: _buildGradientButton(
              onPressed: _isGenerating ? null : _generateVideoFromComic,
              label: '🎨 From Comic',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF8000)],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF12072A), width: 3),
          boxShadow: onPressed == null
              ? []
              : const [BoxShadow(color: Color(0xFF12072A), offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00CFFF), width: 3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _generationStatus,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${_generationProgress.toInt()}%'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _generationProgress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DEB6F)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF2D55), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF2D55)),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF2D55)))),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF12072A), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF12072A), offset: Offset(6, 6), blurRadius: 0)
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFFF2D55),
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _videoController!.setLooping(!_videoController!.value.isLooping),
                  icon: Icon(
                    Icons.repeat,
                    color: _videoController!.value.isLooping ? const Color(0xFFFF2D55) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComicPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC00), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library, color: Color(0xFFFFCC00)),
              SizedBox(width: 8),
              Text(
                'Your Comic Panels Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.panels!.length,
              itemBuilder: (context, index) {
                final panel = widget.panels![index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: panel['image'] != null && panel['image'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: panel['image'],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    if (_videoHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No videos generated yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Generate Your First Video'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videoHistory.length,
      itemBuilder: (context, index) {
        final video = _videoHistory[index];
        // FIXED: Properly handle DateTime conversion
        final dateTime = DateTime.fromMillisecondsSinceEpoch(video['date'] as int);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF12072A), width: 2),
          ),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.movie, color: Colors.grey),
            ),
            title: Text(video['title'] as String),
            subtitle: Text('${dateTime.year}-${dateTime.month}-${dateTime.day}'),
            trailing: const Icon(Icons.play_circle, color: Color(0xFFFF2D55)),
            onTap: () {
              if (video['url'].toString().isNotEmpty) {
                _initializeVideoPlayer(video['url'] as String);
                _tabController.animateTo(0);
              }
            },
          ),
        );
      },
    );
  }
}

// Video Modal Dialog
class VideoGenerationModal extends StatelessWidget {
  final String? story;
  final List<dynamic>? panels;
  
  const VideoGenerationModal({
    Key? key,
    this.story,
    this.panels,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Color(0xFFFFF7ED)),
          child: VideoGenerationPage(
            story: story,
            panels: panels,
          ),
        ),
      ),
    );
  }
}