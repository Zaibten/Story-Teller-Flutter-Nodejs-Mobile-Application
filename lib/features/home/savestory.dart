// saved_stories_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../providers/user_provider.dart';
import 'screens/test.dart';

// Import your existing K class and styles from NewPage
// Or copy the K class here if needed

class SavedStoriesPage extends StatefulWidget {
  static const String routeName = '/saved-stories';
  const SavedStoriesPage({Key? key}) : super(key: key);

  @override
  State<SavedStoriesPage> createState() => _SavedStoriesPageState();
}

class _SavedStoriesPageState extends State<SavedStoriesPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  final String _baseUrl = 'http://192.168.100.97:9000';
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _shimmerController;
  late AnimationController _cardSlideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedStories();
  }

  void _initAnimations() {
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleAnimation = CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut);
    
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    
    _cardSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardSlideAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _shimmerController.dispose();
    _cardSlideController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedStories() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    
    if (user.id == null) {
      setState(() {
        _isLoading = false;
        _stories = [];
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user-stories/${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stories = List<Map<String, dynamic>>.from(data['stories']);
          });
          _fadeController.forward();
          _cardSlideController.forward();
        }
      }
    } catch (e) {
      print('Load stories error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stories: $e'), backgroundColor: K.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStory(String storyId, int index) async {
    setState(() => _isDeleting = true);
    
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/story/$storyId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _stories.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story deleted!'), backgroundColor: K.mint),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: K.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _openStoryDialog(Map<String, dynamic> story) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _StoryDetailDialog(story: story, baseUrl: _baseUrl),
    );
  }

  String _getCharacterEmoji(String? character) {
    switch (character) {
      case 'Cat': return '🐱';
      case 'Lion': return '🦁';
      case 'Elephant': return '🐘';
      case 'Mouse': return '🐭';
      case 'Monkey': return '🐒';
      case 'Crocodile': return '🐊';
      default: return '📖';
    }
  }

  Color _getCharacterColor(String? character) {
    switch (character) {
      case 'Cat': return const Color(0xFFFF4D8D);
      case 'Lion': return const Color(0xFFFF9500);
      case 'Elephant': return const Color(0xFF8B5CF6);
      case 'Mouse': return const Color(0xFF00BFA5);
      case 'Monkey': return const Color(0xFFFF5722);
      case 'Crocodile': return const Color(0xFF2E7D32);
      default: return K.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: K.bg,
      body: Stack(
        children: [
          // Animated Background Sparkles
          _buildSparkleBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Premium Header
                _buildPremiumHeader(user, screenWidth),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _stories.isEmpty
                          ? _buildEmptyState()
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _stories.length,
                                itemBuilder: (context, index) {
                                  return _buildStoryCard(_stories[index], index);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkleBackground() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              K.bg,
              K.pastel[_sparkleAnimation.value.toInt().clamp(0, K.pastel.length - 1) % K.pastel.length],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(dynamic user, double screenWidth) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: K.rainbowGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: const [
          BoxShadow(color: K.ink, offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Row(
            children: [
              // Library Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + _pulseAnimation.value * 0.05,
                    child: const Text('📚', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY STORY LIBRARY',
                      style: ts(screenWidth < 380 ? 16 : 18, K.white, fw: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_stories.length} magical ${_stories.length == 1 ? 'story' : 'stories'} saved',
                      style: tb(12, K.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              // User Avatar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: K.yellow, width: 2),
                ),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: ts(18, K.white, fw: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + _pulseAnimation.value * 0.15,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: K.rainbowGradient,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 8),
                  ],
                ),
                child: const Text('📖', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Loading your stories...', style: ts(18, K.purple, fw: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(K.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (_, __) => Transform.scale(
              scale: 0.9 + _sparkleAnimation.value * 0.1,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: K.oceanGradient,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 10),
                  ],
                ),
                child: const Text('📭', style: TextStyle(fontSize: 64)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('No stories yet!', style: ts(24, K.purple, fw: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'Generate magical stories from the home screen\nand they will appear here',
            textAlign: TextAlign.center,
            style: tb(14, K.ink.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          _PremiumButton(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: K.ink, size: 20),
                const SizedBox(width: 8),
                Text('CREATE A STORY', style: ts(14, K.ink, fw: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story, int index) {
    final createdAt = DateTime.parse(story['createdAt']);
    final charColor = _getCharacterColor(story['character']);
    final isEven = index % 2 == 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (_, value, __) => Transform.translate(
        offset: Offset(isEven ? 20 * (1 - value) : -20 * (1 - value), 0),
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: () => _openStoryDialog(story),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: AnimatedBuilder(
                animation: _cardSlideController,
                builder: (_, __) => Transform.scale(
                  scale: _cardSlideAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [K.surface, K.pastel[index % K.pastel.length]],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: charColor, width: 3),
                      boxShadow: const [
                        BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left colored section with emoji
                        Container(
                          width: 90,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [charColor, charColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25),
                            ),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Transform.scale(
                                scale: 1.0 + _pulseAnimation.value * 0.05,
                                child: Text(
                                  _getCharacterEmoji(story['character']),
                                  style: const TextStyle(fontSize: 44),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story['title'] ?? 'Untitled Story',
                                  style: ts(16, K.ink, fw: FontWeight.w900),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  story['storyText'] ?? '',
                                  style: tb(12, K.ink.withOpacity(0.7)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: charColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: charColor, width: 1),
                                      ),
                                      child: Text(
                                        story['world'] != null && story['world']!.isNotEmpty
                                            ? '${story['world']}'
                                            : 'Magical World',
                                        style: ts(10, charColor, fw: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (story['mood'] != null && story['mood']!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: K.yellow.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: K.yellow, width: 1),
                                        ),
                                        child: Text(
                                          story['mood'],
                                          style: ts(10, K.orange, fw: FontWeight.w700),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(createdAt),
                                      style: tb(10, K.ink.withOpacity(0.4)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Delete button
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 40),
                            icon: Icon(Icons.more_vert_rounded, color: K.ink.withOpacity(0.5)),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteStory(story['_id'], index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: K.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete Story'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// STORY DETAIL DIALOG
// ============================================
class _StoryDetailDialog extends StatefulWidget {
  final Map<String, dynamic> story;
  final String baseUrl;
  
  const _StoryDetailDialog({required this.story, required this.baseUrl});

  @override
  State<_StoryDetailDialog> createState() => _StoryDetailDialogState();
}

class _StoryDetailDialogState extends State<_StoryDetailDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    
    _videoUrl = widget.story['videoUrl'];
    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      _initVideoPlayer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      _videoController = controller;
      await controller.initialize();
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        aspectRatio: 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: K.yellow,
          handleColor: K.orange,
          backgroundColor: Colors.white24,
        ),
      );
      setState(() => _videoInitialized = true);
    } catch (e) {
      print('Video init error: $e');
    }
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'Happy': return '🌟';
      case 'Funny': return '🎪';
      case 'Adventure': return '⚡';
      case 'Bedtime': return '🌙';
      default: return '✨';
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'Happy': return const Color(0xFFFFCC00);
      case 'Funny': return const Color(0xFFFF5500);
      case 'Adventure': return const Color(0xFFCC0000);
      case 'Bedtime': return const Color(0xFF4C5FC4);
      default: return K.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final moodColor = _getMoodColor(widget.story['mood']);
    final moodEmoji = _getMoodEmoji(widget.story['mood']);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: screenWidth * 0.92,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF150D2E), Color(0xFF0B1845)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: moodColor, width: 2),
              boxShadow: [
                BoxShadow(color: moodColor.withOpacity(0.4), blurRadius: 24, spreadRadius: 4),
                const BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [moodColor.withOpacity(0.3), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [moodColor, moodColor.withOpacity(0.6)]),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          widget.story['character'] != null 
                              ? {'Cat':'🐱','Lion':'🦁','Elephant':'🐘','Mouse':'🐭','Monkey':'🐒','Crocodile':'🐊'}[widget.story['character']] ?? '📖'
                              : '📖',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.story['title'] ?? 'Magical Story',
                              style: ts(18, Colors.white, fw: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.story['world'] ?? 'Magical World',
                                    style: tb(10, Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: moodColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$moodEmoji ${widget.story['mood'] ?? 'Adventure'}',
                                    style: tb(10, Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Video Section (if available)
                if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: moodColor, width: 2),
                        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _videoInitialized && _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: K.yellow),
                                    SizedBox(height: 8),
                                    Text('Loading video...', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Story Text
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        widget.story['storyText'] ?? '',
                        style: tb(14, Colors.white, h: 1.6),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ),
                
                // Footer - Date and Language
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(DateTime.parse(widget.story['createdAt'])),
                            style: tb(11, Colors.white38),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.story['language'] == 'urdu' 
                              ? K.purple.withOpacity(0.3)
                              : K.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          widget.story['language'] == 'urdu' ? '🇵🇰 Roman Urdu' : '🇺🇸 English',
                          style: tb(10, Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }
}

// ============================================
// PREMIUM BUTTON HELPER
// ============================================
class _PremiumButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isActive;
  
  const _PremiumButton({
    required this.onTap,
    required this.child,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive ? K.rainbowGradient : const LinearGradient(colors: [Colors.grey, Colors.grey]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: K.ink, width: 2.5),
          boxShadow: isActive ? const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)] : [],
        ),
        child: child,
      ),
    );
  }
}