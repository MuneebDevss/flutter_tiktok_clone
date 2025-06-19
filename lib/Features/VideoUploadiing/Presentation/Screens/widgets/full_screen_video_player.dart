import 'package:finance/Features/VideoUploadiing/Presentation/Screens/video_feed_screen.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/controllers/video_controller.dart';
import 'package:finance/Features/VideoUploadiing/data/video_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoEntity video;
  
  const FullScreenVideoPlayer({Key? key, required this.video}) : super(key: key);
  
  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  final VideoController videoController = Get.find<VideoController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: VideoPlayerWidget(
        video: widget.video,
        isActive: true,
      ),
    );
  }
}