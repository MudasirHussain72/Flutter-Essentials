// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_of_the_week/components/network_image_widget.dart';
import 'package:widget_of_the_week/components/textfield_widget.dart';
import 'package:widget_of_the_week/controllers/record_speech_to_text_controller.dart';

class RecordSpeechToText extends StatefulWidget {
  const RecordSpeechToText({super.key});

  @override
  State<RecordSpeechToText> createState() => _RecordSpeechToTextState();
}

class _RecordSpeechToTextState extends State<RecordSpeechToText> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var provider =
          Provider.of<RecordSpeechToTextController>(context, listen: false);
      print("Before getDir()");
      provider.getDir().then((_) {
        print("After getDir()");
        provider.initialiseControllers().then((_) {
          print("After initialiseControllers()");
          provider.setLoading(false);
        });
      });
    });
  }

  @override
  void dispose() {
    var provider =
        Provider.of<RecordSpeechToTextController>(context, listen: false);
    provider.recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordSpeechToTextController>(
      builder: (context, provider, child) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Speech to Text',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Consumer<RecordSpeechToTextController>(
                          builder: (context, value, child) => ListView.builder(
                              itemCount: value.messageList.length,
                              itemBuilder: (context, index) => ListTile(
                                    leading: const NetworkImageWidget(imageUrl: ''),
                                    title: const Text(
                                      'Ask:',
                                      style: TextStyle(
                                          color: Color(0xff94969C),
                                          fontSize: 18),
                                    ),
                                    subtitle: Flexible(
                                      child: Text(
                                        value.messageList[index],
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                  ))),
                    ),
                    // if (provider.isRecordingCompleted)
                    //   WaveBubble(
                    //     path: provider.path,
                    //     isSender: true,
                    //     appDirectory: provider.appDirectory,
                    //   ),
                    const SendMessageWidget(),
                  ],
                ),
              ),
      ),
    );
  }
}
