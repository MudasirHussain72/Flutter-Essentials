import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:widget_of_the_week/controllers/record_speech_to_text_controller.dart';
import 'package:widget_of_the_week/controllers/services/dependency_injection.dart';
import 'package:widget_of_the_week/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:widget_of_the_week/widgets/record_speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RecordSpeechToTextController(),
        )
      ],
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
        child: const GetMaterialApp(
          debugShowCheckedModeBanner: false,
          // home: CachedVideoPlayerWidget(),
          // home: ShorebirdCicdExample(),
          // home: LongPressDialog(),
          home: RecordSpeechToText(),
        ),
      ),
    );
  }
}
