import 'package:finance/Features/VideoUploadiing/Presentation/controllers/video_controller.dart';
import 'package:finance/Features/VideoUploadiing/data/video_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  _VideoFeedScreenState createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final VideoController videoController = Get.find<VideoController>();
  final PageController pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    // Load videos when screen initializes
    if (videoController.videos.isEmpty) {
      videoController.loadVideos();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'TikTok Clone',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/upload'),
            icon: Icon(Icons.add, color: Colors.white, size: 28),
          ),
          IconButton(
            onPressed: () => videoController.refreshVideos(),
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Obx(() {
        if (videoController.isLoading.value && videoController.videos.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        }
        
        if (videoController.videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 100,
                  color: Colors.white54,
                ),
                SizedBox(height: 20),
                Text(
                  'No videos yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Be the first to upload a video!',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Upload Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo is ScrollEndNotification &&
                pageController.position.extentAfter < 200) {
              videoController.loadMoreVideos();
            }
            return false;
          },
          child: PageView.builder(
            controller: pageController,
            scrollDirection: Axis.vertical,
            itemCount: videoController.videos.length,
            itemBuilder: (context, index) {
              final video = videoController.videos[index];
              return VideoPlayerWidget(
                video: video,
                isActive: true, // You can implement active video logic here
              );
            },
          ),
        );
      }),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final VideoEntity video;
  final bool isActive;
  
  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.isActive,
  });
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  final VideoController videoController = Get.find<VideoController>();
  bool isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }
  
  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.video.videoUrl);
    
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      
      if (widget.isActive) {
        _controller!.play();
      }
      
      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video Player
          Center(
            child: isInitialized && _controller != null
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
          ),
          
          // Right Side Actions
          Positioned(
            right: 10,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  icon: videoController.isVideoLiked(widget.video)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: widget.video.likes.length,
                  onTap: () => videoController.toggleLike(widget.video.id),
                  isActive: videoController.isVideoLiked(widget.video),
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  icon: videoController.isVideoSaved(widget.video)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  count: widget.video.saves.length,
                  onTap: () => videoController.toggleSave(widget.video.id),
                  isActive: videoController.isVideoSaved(widget.video),
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.download,
                  onTap: () => _downloadVideo(),
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.share,
                  onTap: () => _shareVideo(),
                ),
              ],
            ),
          ),
          
          // Bottom User Info and Caption
          Positioned(
            left: 10,
            right: 80,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[700],
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.video.userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeAgo(widget.video.createdAt),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 10),
                
                // Caption
                if (widget.video.caption.isNotEmpty)
                  Text(
                    widget.video.caption,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    int? count,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 30,
            ),
          ),
        ),
        if (count != null) ...[
          SizedBox(height: 5),
          Text(
            _formatCount(count),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
  
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  void _downloadVideo() {
    final fileName = 'video_${widget.video.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    videoController.downloadVideo(widget.video.videoUrl, fileName);
  }
  
  void _shareVideo() {
    // Implement share functionality
    Get.snackbar(
      'Share',
      'Share functionality will be implemented here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}