import 'dart:io';
import 'package:finance/Features/VideoUploadiing/data/video_entity.dart';
import 'package:finance/Features/VideoUploadiing/data/video_repository.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoController extends GetxController {
  final VideoRepository _videoRepository = VideoRepository();
  
  // Observable lists
  final RxList<VideoEntity> videos = <VideoEntity>[].obs;
  final RxList<VideoEntity> savedVideos = <VideoEntity>[].obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  
  // Upload states
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  
  // Pagination
  DocumentSnapshot? lastDocument;
  final int pageSize = 10;
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  
  @override
  void onInit() {
    super.onInit();
    loadVideos();
    loadSavedVideos();
    
    // Listen to upload progress from repository
    ever(_videoRepository.uploadProgress, (progress) {
      uploadProgress.value = progress;
    });
    
    ever(_videoRepository.isUploading, (uploading) {
      isUploading.value = uploading;
    });
  }
  
  // Load initial videos
  Future<void> loadVideos() async {
    try {
      isLoading.value = true;
      hasMore.value = true;
      lastDocument = null;
      
      final newVideos = await _videoRepository.getVideos(limit: pageSize);
      videos.value = newVideos;
      
      if (newVideos.length < pageSize) {
        hasMore.value = false;
      }
      
      if (newVideos.isNotEmpty) {
        // Get the last document for pagination
        final lastVideoId = newVideos.last.id;
        final docSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(lastVideoId)
            .get();
        lastDocument = docSnapshot;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load videos: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Load more videos for pagination
  Future<void> loadMoreVideos() async {
    if (isLoadingMore.value || !hasMore.value) return;
    
    try {
      isLoadingMore.value = true;
      
      final newVideos = await _videoRepository.getVideos(
        lastDocument: lastDocument,
        limit: pageSize,
      );
      
      if (newVideos.isNotEmpty) {
        videos.addAll(newVideos);
        
        // Update last document
        final lastVideoId = newVideos.last.id;
        final docSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .doc(lastVideoId)
            .get();
        lastDocument = docSnapshot;
        
        if (newVideos.length < pageSize) {
          hasMore.value = false;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load more videos: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }
  
  // Load saved videos
  void loadSavedVideos() {
    _videoRepository.getSavedVideosStream().listen(
      (videos) {
        savedVideos.value = videos;
      },
      onError: (e) {
        Get.snackbar(
          'Error',
          'Failed to load saved videos: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
  
  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
  
  // Record video with camera
  Future<File?> recordVideo() async {
    try {
      final XFile? recordedFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );
      
      if (recordedFile != null) {
        return File(recordedFile.path);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
  
  // Upload video
  Future<void> uploadVideo({
    required File videoFile,
    required String caption,
  }) async {
    try {
      final videoId = await _videoRepository.uploadVideo(
        videoFile: videoFile,
        caption: caption,
      );
      
      Get.snackbar(
        'Success',
        'Video uploaded successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Refresh videos list
      await loadVideos();
      
      // Navigate back to home
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Toggle like
  Future<void> toggleLike(String videoId) async {
    try {
      await _videoRepository.toggleLike(videoId);
      
      // Update local state
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      if (videoIndex != -1) {
        final video = videos[videoIndex];
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final likes = List<String>.from(video.likes);
          if (likes.contains(currentUser.uid)) {
            likes.remove(currentUser.uid);
          } else {
            likes.add(currentUser.uid);
          }
          videos[videoIndex] = video.copyWith(likes: likes);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to toggle like: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Toggle save
  Future<void> toggleSave(String videoId) async {
    try {
      await _videoRepository.toggleSave(videoId);
      
      // Update local state
      final videoIndex = videos.indexWhere((v) => v.id == videoId);
      if (videoIndex != -1) {
        final video = videos[videoIndex];
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final saves = List<String>.from(video.saves);
          if (saves.contains(currentUser.uid)) {
            saves.remove(currentUser.uid);
          } else {
            saves.add(currentUser.uid);
          }
          videos[videoIndex] = video.copyWith(saves: saves);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to toggle save: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Download video
  Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      await _videoRepository.downloadVideo(videoUrl, fileName);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Check if video is liked by current user
  bool isVideoLiked(VideoEntity video) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return video.likes.contains(currentUser.uid);
  }
  
  // Check if video is saved by current user
  bool isVideoSaved(VideoEntity video) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return video.saves.contains(currentUser.uid);
  }
  
  // Refresh videos
  Future<void> refreshVideos() async {
    await loadVideos();
  }
}