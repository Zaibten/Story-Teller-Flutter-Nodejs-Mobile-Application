// // lib/widgets/story_generation_dialog.dart
// import 'dart:async';
// import 'package:flutter/material.dart';

// class StoryGenerationDialog extends StatefulWidget {
//   final String character;
//   final String world;
//   final String mood;
//   final StoryService storyService;

//   const StoryGenerationDialog({
//     Key? key,
//     required this.character,
//     required this.world,
//     required this.mood,
//     required this.storyService,
//   }) : super(key: key);

//   @override
//   State<StoryGenerationDialog> createState() => _StoryGenerationDialogState();
// }

// class _StoryGenerationDialogState extends State<StoryGenerationDialog>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _spinnerCtrl;
//   late Animation<double> _rotation;
  
//   String _status = "Initializing...";
//   int _progress = 0;
//   String? _currentStory;
//   String? _romanUrduStory;
//   List<dynamic>? _panels;
//   String? _videoUrl;
//   StreamSubscription? _subscription;
//   bool _isComplete = false;
//   String? _generationTime;

//   @override
//   void initState() {
//     super.initState();
//     _spinnerCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//     _rotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_spinnerCtrl);
    
//     _startGeneration();
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     _spinnerCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _startGeneration() async {
//     try {
//       final stream = await widget.storyService.generateStoryStream(
//         character: widget.character,
//         world: widget.world,
//         mood: widget.mood,
//       );

//       _subscription = stream.listen((event) {
//         setState(() {
//           if (event.progress != null) _progress = event.progress!;
//           if (event.status != null) _status = event.status!;
//           if (event.story != null) _currentStory = event.story;
//           if (event.romanUrduStory != null) _romanUrduStory = event.romanUrduStory;
//           if (event.panels != null) _panels = event.panels;
//           if (event.videoUrl != null) _videoUrl = event.videoUrl;
//           if (event.generationTime != null) _generationTime = event.generationTime;
          
//           if (event.progress == 100) {
//             _isComplete = true;
//             _status = "Complete! Loading your story...";
            
//             // Close dialog after a short delay and show the story
//             Future.delayed(const Duration(milliseconds: 800), () {
//               if (mounted) {
//                 Navigator.pop(context);
//                 _showStoryDialog();
//               }
//             });
//           }
          
//           if (event.error != null) {
//             _status = "Error: ${event.error}";
//           }
//         });
//       });
//     } catch (e) {
//       setState(() {
//         _status = "Error: $e";
//       });
//     }
//   }

//   void _showStoryDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => StoryResultDialog(
//         story: _currentStory ?? 'No story generated',
//         romanUrduStory: _romanUrduStory,
//         panels: _panels,
//         videoUrl: _videoUrl,
//         character: widget.character,
//         world: widget.world,
//         mood: widget.mood,
//         generationTime: _generationTime,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(36),
//           border: Border.all(color: Colors.white.withOpacity(0.12)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Animated spinner
//             AnimatedBuilder(
//               animation: _rotation,
//               builder: (_, __) {
//                 return Transform.rotate(
//                   angle: _rotation.value,
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Text(
//                       _progress < 30 ? '📖' : _progress < 70 ? '✨' : '🌟',
//                       style: const TextStyle(fontSize: 48),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 24),
            
//             // Progress indicator
//             LinearProgressIndicator(
//               value: _progress / 100,
//               backgroundColor: Colors.white.withOpacity(0.2),
//               valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
//             ),
//             const SizedBox(height: 16),
            
//             // Status text
//             Text(
//               _status,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Progress percentage
//             Text(
//               '$_progress%',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Animated dots
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(3, (i) {
//                 return AnimatedBuilder(
//                   animation: _spinnerCtrl,
//                   builder: (_, __) {
//                     final opacity = (0.3 + (_spinnerCtrl.value * 2 + i) % 1).clamp(0.3, 1.0);
//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 4),
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(opacity),
//                         shape: BoxShape.circle,
//                       ),
//                     );
//                   },
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Story Result Dialog
// class StoryResultDialog extends StatelessWidget {
//   final String story;
//   final String? romanUrduStory;
//   final List<dynamic>? panels;
//   final String? videoUrl;
//   final String character;
//   final String world;
//   final String mood;
//   final String? generationTime;

//   const StoryResultDialog({
//     Key? key,
//     required this.story,
//     this.romanUrduStory,
//     this.panels,
//     this.videoUrl,
//     required this.character,
//     required this.world,
//     required this.mood,
//     this.generationTime,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF150D2E), Color(0xFF0B1845)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//           borderRadius: BorderRadius.circular(38),
//           border: Border.all(color: Colors.white.withOpacity(0.13)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Header
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.white.withOpacity(0.1), Colors.transparent],
//                 ),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(38),
//                   topRight: Radius.circular(38),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.auto_stories, color: Colors.white, size: 32),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '$character\'s $mood Adventure',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           'in the $world',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.7),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (generationTime != null)
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '✨ $generationTime',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
            
//             // Story content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // English story
//                     const Text(
//                       '📖 English Story',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.05),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white.withOpacity(0.1)),
//                       ),
//                       child: Text(
//                         story,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           height: 1.6,
//                         ),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 20),
                    
//                     // Roman Urdu story (if available)
//                     if (romanUrduStory != null) ...[
//                       const Text(
//                         '🕌 Urdu Story (Roman Script)',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.05),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.white.withOpacity(0.1)),
//                         ),
//                         child: Text(
//                           romanUrduStory!,
//                           style: const TextStyle(
//                             color: Color(0xFFFFD700),
//                             fontSize: 14,
//                             height: 1.6,
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
                    
//                     // Comic panels preview
//                     if (panels != null && panels!.isNotEmpty) ...[
//                       const Text(
//                         '🎨 Story Panels',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       SizedBox(
//                         height: 120,
//                         child: ListView.separated(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: panels!.length,
//                           separatorBuilder: (_, __) => const SizedBox(width: 12),
//                           itemBuilder: (_, index) {
//                             final panel = panels![index];
//                             return Container(
//                               width: 100,
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.05),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: Colors.white.withOpacity(0.1)),
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   if (panel['image'] != null && panel['image'].toString().isNotEmpty)
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Image.network(
//                                         panel['image'],
//                                         height: 70,
//                                         width: 90,
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white54),
//                                       ),
//                                     )
//                                   else
//                                     const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     panel['title'] ?? 'Panel ${index + 1}',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 9,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                     maxLines: 2,
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
            
//             // Action buttons
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.transparent, Colors.white.withOpacity(0.05)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   if (videoUrl != null)
//                     Expanded(
//                       child: _ActionButton(
//                         label: '🎬 Watch Video',
//                         onTap: () {
//                           // Show video dialog
//                           _showVideoDialog(context, videoUrl!);
//                         },
//                         color: const Color(0xFFFF6D00),
//                       ),
//                     ),
//                   if (videoUrl != null) const SizedBox(width: 12),
//                   Expanded(
//                     child: _ActionButton(
//                       label: '✨ Close',
//                       onTap: () => Navigator.pop(context),
//                       color: Colors.white.withOpacity(0.2),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showVideoDialog(BuildContext context, String videoUrl) {
//     showDialog(
//       context: context,
//       builder: (_) => VideoPreviewDialog(videoUrl: videoUrl),
//     );
//   }
// }

// class _ActionButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   final Color color;

//   const _ActionButton({
//     required this.label,
//     required this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [color, color.withOpacity(0.8)],
//           ),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(
//           label,
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class VideoPreviewDialog extends StatelessWidget {
//   final String videoUrl;

//   const VideoPreviewDialog({Key? key, required this.videoUrl}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         height: MediaQuery.of(context).size.height * 0.5,
//         decoration: BoxDecoration(
//           color: Colors.black,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Column(
//           children: [
//             // Video player placeholder - you can integrate a proper video player here
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.play_circle_filled, color: Colors.white, size: 64),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Video URL: $videoUrl',
//                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Center(
//                     child: Text('Close', style: TextStyle(color: Colors.white)),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }