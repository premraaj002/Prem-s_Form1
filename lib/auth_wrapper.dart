import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/email_verify_page.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to handle app state changes properly
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove lifecycle observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes if needed
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        break;
      case AppLifecycleState.paused:
        // App is in background
        break;
      case AppLifecycleState.detached:
        // App is being closed
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.blue[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Prem\'s Form',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }
        
        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          
          // Check if email is verified
          if (user.emailVerified) {
            return DashboardScreen();
          } else {
            return EmailVerificationScreen(email: user.email ?? '');
          }
        }
        
        // User is not logged in
        return LoginScreen();
      },
    );
  }
}
