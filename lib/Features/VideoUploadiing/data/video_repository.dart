import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance/Features/VideoUploadiing/data/video_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = "videos";

  // Upload progress observable
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;

  // Upload video to Firebase Storage and save metadata to Firestore
  Future<String> uploadVideo({
    required File videoFile,
    required String caption,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      final storageRef = _storage.ref().child('videos/$fileName');

      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(videoFile);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        uploadProgress.value = (snapshot.bytesTransferred / snapshot.totalBytes);
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Get user data for video metadata
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create video document in Firestore
      final videoDoc = await _firestore.collection(_collectionName).add({
        'userId': user.uid,
        'videoUrl': downloadUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'saves': [],
        'userEmail': userData['email'] ?? user.email ?? '',
        'userName': userData['name'] ?? 'Anonymous',
      });

      isUploading.value = false;
      uploadProgress.value = 0.0;
      
      return videoDoc.id;
    } catch (e) {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      throw Exception('Failed to upload video: $e');
    }
  }

  // Get all videos for feed (ordered by creation time)
  Stream<List<VideoEntity>> getVideosStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VideoEntity.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get paginated videos for better performance
  Future<List<VideoEntity>> getVideos({
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return VideoEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  // Like/Unlike video
  Future<void> toggleLike(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final videoRef = _firestore.collection(_collectionName).doc(videoId);
      
      await _firestore.runTransaction((transaction) async {
        final videoDoc = await transaction.get(videoRef);
        
        if (!videoDoc.exists) {
          throw Exception('Video not found');
        }

        final data = videoDoc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        } else {
          likes.add(user.uid);
        }
        
        transaction.update(videoRef, {'likes': likes});
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Save/Unsave video
  Future<void> toggleSave(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final videoRef = _firestore.collection(_collectionName).doc(videoId);
      
      await _firestore.runTransaction((transaction) async {
        final videoDoc = await transaction.get(videoRef);
        
        if (!videoDoc.exists) {
          throw Exception('Video not found');
        }

        final data = videoDoc.data()!;
        final saves = List<String>.from(data['saves'] ?? []);
        
        if (saves.contains(user.uid)) {
          saves.remove(user.uid);
        } else {
          saves.add(user.uid);
        }
        
        transaction.update(videoRef, {'saves': saves});
      });
    } catch (e) {
      throw Exception('Failed to toggle save: $e');
    }
  }

  // Download video
  Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      final dio = Dio();
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Download file
      await dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            uploadProgress.value = (received / total);
          }
        },
      );
      
      uploadProgress.value = 0.0;
      Get.snackbar(
        'Success', 
        'Video downloaded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      uploadProgress.value = 0.0;
      throw Exception('Failed to download video: $e');
    }
  }

  // Get user's saved videos
  Stream<List<VideoEntity>> getSavedVideosStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('saves', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VideoEntity.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get user's uploaded videos
  Stream<List<VideoEntity>> getUserVideosStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VideoEntity.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}