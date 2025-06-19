import 'package:finance/Features/VideoUploadiing/Presentation/Screens/profile_screen.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/Screens/saved_videos_screen.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/Screens/video_feed_screen.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/Screens/video_uploading_screen.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/controllers/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  
  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}

class MainNavigationScreen extends StatelessWidget {
  final MainNavigationController navigationController = Get.put(MainNavigationController());
  final VideoController videoController = Get.put(VideoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        switch (navigationController.selectedIndex.value) {
          case 0:
            return VideoFeedScreen();
          case 1:
            return SavedVideosScreen();
          case 2:
            return VideoUploadScreen();
          case 3:
            return ProfileScreen();
          default:
            return VideoFeedScreen();
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: navigationController.selectedIndex.value,
        onTap: (index) {
          if (index == 2) {
            // Navigate to upload screen
            Get.to(() => VideoUploadScreen());
          } else {
            navigationController.changeIndex(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white54,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }
}





