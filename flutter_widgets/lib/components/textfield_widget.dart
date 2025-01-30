import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_of_the_week/controllers/record_speech_to_text_controller.dart';

class SendMessageWidget extends StatefulWidget {
  const SendMessageWidget({super.key});

  @override
  State<SendMessageWidget> createState() => _SendMessageWidgetState();
}

class _SendMessageWidgetState extends State<SendMessageWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecordSpeechToTextController>(
        builder: (context, value, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: TextFormField(
          controller: value.messageTextController,
          focusNode: value.messageTextFocusNode,
          cursorColor: const Color(0xff2B2B2B),
          minLines: 1,
          maxLines: 5,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
          decoration: InputDecoration(
              hintText: "Type Something...",
              hintStyle: const TextStyle(color: Color(0xff94969C)),
              contentPadding:
                  const EdgeInsets.only(left: 20, top: 10, bottom: 10),
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(50.0),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        value.startRecording(context);
                        showModalBottomSheet(
                          isDismissible: true,
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          builder: (context) => Container(
                            width: double.infinity,
                            height: 232.7,
                            color: const Color(0xff232323),
                            child: Consumer<RecordSpeechToTextController>(
                              builder: (context, provider, child) => Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 6),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: provider.isRecording
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: provider.refreshWave,
                                                icon: Icon(
                                                  provider.isRecording
                                                      ? Icons.refresh
                                                      : Icons.send,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              AudioWaveforms(
                                                padding: const EdgeInsets.only(
                                                    bottom: 6, top: 6),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 12),
                                                enableGesture: true,
                                                size: Size(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1.6,
                                                    70),
                                                recorderController:
                                                    provider.recorderController,
                                                waveStyle: const WaveStyle(
                                                  waveColor: Color(0xffEF6820),
                                                  extendWaveform: true,
                                                  showMiddleLine: false,
                                                ),
                                              ),
                                            ],
                                          )
                                        : WaveBubble(
                                            path: provider.path,
                                            isSender: true,
                                            appDirectory: provider.appDirectory,
                                          ),
                                  ),
                                  const SizedBox(height: 30),
                                  if (provider.isRecording)
                                    Column(
                                      children: [
                                        GestureDetector(
                                            onTap: () =>
                                                provider.stopRecording(context),
                                            child: Container(
                                                height: 48,
                                                width: 48,
                                                decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xff4C4C4C)),
                                                child: Center(
                                                  child: Container(
                                                    height: 17,
                                                    width: 17,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.5),
                                                        color: const Color(
                                                            0xffF97066)),
                                                  ),
                                                ))),
                                        const Text(
                                          'Stop Recording',
                                          style: TextStyle(
                                              color: Color(0xff94969C),
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  if (provider
                                      .loading) // Show loading indicator while transcribing
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Converting to text!',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  if (provider.errorMessage != null)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          provider.errorMessage.toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                        ),
                                        ElevatedButton(
                                            onPressed: () {
                                              value.transcribeAudio(
                                                  context, value.path!);
                                            },
                                            child: const Text('Retry'))
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ).whenComplete(() {
                          // Perform actions when the bottom sheet is dismissed
                          value.stopRecording(context);
                          value.clearRecording().then((_) {
                            value.stopTranscription(context);
                          });
                        });
                      },
                      icon: const Icon(
                        Icons.mic_none_rounded,
                        color: Color(0xff94969C),
                      )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          value.addMessageToMessageList(
                              value.messageTextController.text.trim());
                        },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xff94969C),
                        )),
                  ),
                ],
              )),
          onChanged: (value) {},
        ),
      );
    });
  }
}

class WaveBubble extends StatefulWidget {
  final bool isSender;
  final int? index;
  final String? path;
  final double? width;
  final Directory appDirectory;

  const WaveBubble({
    super.key,
    required this.appDirectory,
    this.width,
    this.index,
    this.isSender = false,
    this.path,
  });

  @override
  State<WaveBubble> createState() => _WaveBubbleState();
}

class _WaveBubbleState extends State<WaveBubble> {
  File? file;

  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Color(0xffEF6820),
    liveWaveColor: Color(0xffEF6820),
    spacing: 6,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    // Opening file from assets folder
    if (widget.index != null) {
      file = File('${widget.appDirectory.path}/audio${widget.index}.mp3');
      await file?.writeAsBytes(
          (await rootBundle.load('assets/audios/audio${widget.index}.mp3'))
              .buffer
              .asUint8List());
    }
    if (widget.index == null && widget.path == null && file?.path == null) {
      return;
    }
    // Prepare player with extracting waveform if index is even.
    controller.preparePlayer(
      path: widget.path ?? file!.path,
      shouldExtractWaveform: widget.index?.isEven ?? true,
    );
    // Extracting waveform separately if index is odd.
    if (widget.index?.isOdd ?? false) {
      controller
          .extractWaveformData(
            path: widget.path ?? file!.path,
            noOfSamples:
                playerWaveStyle.getSamplesForWidth(widget.width ?? 200),
          )
          .then((waveformData) => debugPrint(waveformData.toString()));
    }
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.path != null || file?.path != null
        ? Container(
            padding: EdgeInsets.only(
              bottom: 6,
              right: widget.isSender ? 0 : 10,
              top: 6,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: widget.isSender ? Colors.transparent : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!controller.playerState.isStopped)
                  IconButton(
                    onPressed: () async {
                      controller.playerState.isPlaying
                          ? await controller.pausePlayer()
                          : await controller.startPlayer(
                              finishMode: FinishMode.loop,
                            );
                    },
                    icon: Icon(
                      controller.playerState.isPlaying
                          ? Icons.stop
                          : Icons.play_arrow,
                    ),
                    color: const Color(0xffEF6820),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width / 1.6, 70),
                  playerController: controller,
                  waveformType: widget.index?.isOdd ?? false
                      ? WaveformType.fitWidth
                      : WaveformType.long,
                  playerWaveStyle: playerWaveStyle,
                  backgroundColor: const Color(0xffEF6820),
                ),
                // if (widget.isSender) const SizedBox(width: 10),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
