import 'dart:io';
import 'dart:math';
import 'package:finance/Features/VideoUploadiing/Presentation/controllers/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoUploadScreen extends StatefulWidget {
  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final VideoController videoController = Get.find<VideoController>();
  final TextEditingController captionController = TextEditingController();
  
  File? selectedVideo;
  VideoPlayerController? videoPlayerController;
  bool isVideoInitializing = false;
  
  @override
  void dispose() {
    captionController.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideoPlayer(File videoFile) async {
    setState(() => isVideoInitializing = true);
    videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.file(videoFile);
    
    try {
      await videoPlayerController!.initialize();
      await videoPlayerController!.setLooping(true);
      setState(() {});
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => isVideoInitializing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Upload Video',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (selectedVideo != null)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _selectNewVideo,
            ),
        ],
      ),
      body: Obx(() {
        if (videoController.isUploading.value) {
          return _buildUploadingView();
        }
        
        return selectedVideo == null
            ? _buildVideoSelectionView()
            : _buildVideoPreviewView();
      }),
    );
  }
  
  Widget _buildVideoSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 100,
            color: Colors.white54,
          ),
          SizedBox(height: 30),
          Text(
            'Select a video to upload',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectionButton(
                icon: Icons.videocam,
                label: 'Record',
                onTap: _recordVideo,
              ),
              _buildSelectionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPreviewView() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  if (videoPlayerController != null && 
                      videoPlayerController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(videoPlayerController!),
                    ),
                  if (isVideoInitializing)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  if (videoPlayerController != null && 
                      videoPlayerController!.value.isInitialized)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          videoPlayerController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: _toggleVideoPlayback,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Caption',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: Colors.white54),
                    fillColor: Colors.white12,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    counterStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectNewVideo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white30),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Change Video'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _uploadVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Upload',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUploadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: videoController.uploadProgress.value,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text(
                  '${(videoController.uploadProgress.value * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Uploading your video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please don\'t close the app',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 30),
          Obx(() {
            if (videoController.uploadProgress.value > 0) {
              return Text(
                '${_formatFileSize(_estimateFileSize(videoController.uploadProgress.value))}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              );
            }
            return SizedBox();
          }),
        ],
      ),
    );
  }
  
  Future<void> _recordVideo() async {
    final videoFile = await videoController.recordVideo();
    if (videoFile != null) {
      setState(() {
        selectedVideo = videoFile;
      });
      await _initializeVideoPlayer(videoFile);
    }
  }
  
  Future<void> _pickFromGallery() async {
    final videoFile = await videoController.pickVideoFromGallery();
    if (videoFile != null) {
      setState(() {
        selectedVideo = videoFile;
      });
      await _initializeVideoPlayer(videoFile);
    }
  }
  
  void _toggleVideoPlayback() {
    setState(() {
      if (videoPlayerController!.value.isPlaying) {
        videoPlayerController!.pause();
      } else {
        videoPlayerController!.play();
      }
    });
  }
  
  void _selectNewVideo() {
    setState(() {
      selectedVideo = null;
      videoPlayerController?.dispose();
      videoPlayerController = null;
      captionController.clear();
    });
  }
  
  Future<void> _uploadVideo() async {
    if (selectedVideo == null) return;
    
    final caption = captionController.text.trim();
    if (caption.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add a caption for your video',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      await videoController.uploadVideo(
        videoFile: selectedVideo!,
        caption: caption,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Upload failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Helper methods for upload progress display
  int _estimateFileSize(double progress) {
    if (selectedVideo == null || progress <= 0) return 0;
    return (selectedVideo!.lengthSync() * progress).round();
  }
  
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]} uploaded';
  }
}