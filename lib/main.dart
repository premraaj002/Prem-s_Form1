import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_wrapper.dart';
import 'screens/public_form_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prem\'s Form',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      // Add route handling for public forms
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        
        // Handle public form routes: /form/[formId]
        if (uri.pathSegments.length == 2 && 
            uri.pathSegments[0] == 'form') {
          final formId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => PublicFormScreen(formId: formId),
            settings: settings,
          );
        }
        
        // Default route handling
        return MaterialPageRoute(
          builder: (context) => AuthWrapper(),
          settings: settings,
        );
      },
      home: AuthWrapper(),
    );
  }
}
