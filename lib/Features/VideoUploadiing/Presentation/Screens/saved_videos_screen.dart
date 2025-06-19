import 'package:finance/Features/VideoUploadiing/Presentation/Screens/widgets/full_screen_video_player.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/controllers/video_controller.dart';
import 'package:finance/Features/VideoUploadiing/data/video_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SavedVideosScreen extends StatelessWidget {
  final VideoController videoController = Get.find<VideoController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Saved Videos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (videoController.savedVideos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 100,
                  color: Colors.white54,
                ),
                SizedBox(height: 20),
                Text(
                  'No saved videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Videos you save will appear here',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: videoController.savedVideos.length,
          itemBuilder: (context, index) {
            final video = videoController.savedVideos[index];
            return _buildVideoThumbnail(video);
          },
        );
      }),
    );
  }
  
  Widget _buildVideoThumbnail(VideoEntity video) {
    return GestureDetector(
      onTap: () {
        // Navigate to full screen video player
        Get.to(() => FullScreenVideoPlayer(video: video));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Thumbnail placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_fill,
                size: 50,
                color: Colors.white54,
              ),
            ),
            
            // Video info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (video.caption.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        video.caption,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bookmark icon
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark,
                  color: Colors.red,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}