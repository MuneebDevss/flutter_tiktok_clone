import 'package:finance/Core/Theme/theme.dart';
import 'package:finance/Features/Auth/Presentation/login_page.dart';
import 'package:finance/Features/VideoUploadiing/Presentation/Screens/video_feed_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';




void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  
                                                                                                                                                                                                                                                                            
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      
      return GetMaterialApp(
        themeMode: ThemeMode.dark,
        theme: TAppTheme.darkTheme,

        debugShowCheckedModeBanner: false,
        home: AppStart(),
      );
    });
  }
}

class AppStart extends StatelessWidget {
  const AppStart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkUserSession(),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for Firebase initialization
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // Navigate to the respective page
          return snapshot.data!;
        } else {
          // Fallback in case of an unexpected scenario
          return const Scaffold(
            body: Center(child: Text('Unexpected Error Occurred')),
          );
        }
      },
    );
  }

  Future<Widget> _checkUserSession() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (currentUser == null) {
      // No user session found, navigate to LoginPage
      return LoginPage();
    }  else {
      // User is signed in and email is verified
      return VideoFeedScreen();
    }
  }
}
