// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecordSpeechToTextController with ChangeNotifier {
  late final RecorderController recorderController;
  final TextEditingController messageTextController =
      TextEditingController(); // Define the controller
  final FocusNode messageTextFocusNode = FocusNode();
  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool _isUserTappedOutsideOfSheetDuringTranscribing = false;
  bool get isUserTappedOutsideOfSheetDuringTranscribing =>
      _isUserTappedOutsideOfSheetDuringTranscribing;
  setIsUserTappedOutsideOfSheetDuringTranscribing(bool value) {
    _isUserTappedOutsideOfSheetDuringTranscribing = value;
    notifyListeners();
  }

  bool isLoading = true;
  late Directory appDirectory;
  bool _loading = false;
  bool get loading => _loading;
  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  final List<String> _messageList = [];
  List get messageList => _messageList;
  addMessageToMessageList(String value) {
    _messageList.add(value);
    messageTextController.clear();
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<String?> transcribeAudio(BuildContext context, String filePath) async {
    setErrorMessage(null);
    if (filePath == '') {
      setIsUserTappedOutsideOfSheetDuringTranscribing(true);
      return null;
    } else {
      try {
        setLoading(true);
        log('transcribeAudio running');
        // String apiUrl = 'https://api.openai.com/v1/audio/transcriptions';
        String apiUrl = 'https://api.openai.com/v1/audio/translations';
        String apiKey = dotenv.get('OPENAIAPIKEY');
        var audioFile = File(filePath);
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
          ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
          ..fields['model'] = 'whisper-1'
          ..headers['Authorization'] = 'Bearer $apiKey';

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseBody);
          messageTextController.text = jsonResponse['text'];
          notifyListeners();
          // if (_isUserTappedOutsideOfSheetDuringTranscribing) {
          Navigator.pop(context);
          // }
          setLoading(false);
          setErrorMessage(null);
          return jsonResponse['text'];
        } else {
          var errorResponse = await response.stream.bytesToString();
          print(
              'Failed to transcribe audio. Status code: ${response.statusCode}');
          print('Error response body: $errorResponse');
          setErrorMessage(
              'Failed to transcribe audio. Status code: ${response.statusCode}');
          if (_isUserTappedOutsideOfSheetDuringTranscribing) {
            Navigator.pop(context);
          }
          setLoading(false);
          return null;
        }
      } catch (e) {
        print('Error transcribing audio: $e');
        setErrorMessage('Error transcribing audio: $e');
        if (_isUserTappedOutsideOfSheetDuringTranscribing) {
          Navigator.pop(context);
        }
        setLoading(false);
        log('transcribeAudio close');
        return null;
      }
    }
  }

  Future<void> getDir() async {
    setLoading(true);
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setLoading(false);
    return Future.value();
  }

  Future<void> initialiseControllers() async {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    setLoading(false);
    return Future.value();
  }

  void pickFile() async {
    setLoading(true);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      setLoading(false);
      notifyListeners();
    } else {
      debugPrint("File not picked");
    }
  }

  void startRecording(BuildContext context) async {
    setErrorMessage(null);
    try {
      if (!isRecording) {
        // Start recording
        isRecording = true;
        await recorderController.record(path: path);
        setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  void stopRecording(BuildContext context) async {
    try {
      if (isRecording) {
        // Stop recording
        recorderController.reset();
        path = await recorderController.stop(false);
        if (path != null) {
          isRecording = false;
          notifyListeners();
          isRecordingCompleted = true;
          // Transcribe the recorded audio
          String? transcription = await transcribeAudio(context, path!);
          if (transcription != null) {
            // Handle the transcription here
            print('Transcription: $transcription');
          }
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      isRecording = false;
      notifyListeners();
    } finally {
      isRecording = false;
      setLoading(false);
      notifyListeners();
    }
  }

  void refreshWave() {
    if (isRecording) {
      recorderController.refresh();
    }
  }

  Future<void> clearRecording() async {
    try {
      if (isRecording) {
        await recorderController.stop(true);
      }
      if (path != null) {
        File recordingFile = File(path!);
        if (await recordingFile.exists()) {
          await recordingFile.delete();
        }
        path = null;
        isRecordingCompleted = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error clearing recording: $e');
    }
  }

  // Future<void> stopTranscription(BuildContext context) async {
  //   try {
  //     if (isLoading) {
  //       setLoading(false);
  //       notifyListeners();
  //     }
  //     // Call transcribeAudio with an empty filePath to stop the transcription process
  //     await transcribeAudio(context, '');
  //   } catch (e) {
  //     print('Error stopping transcription: $e');
  //   }
  // }
  bool _transcriptionInProgress = false;

  Future<void> stopTranscription(BuildContext context) async {
    try {
      if (!_transcriptionInProgress && isLoading) {
        _transcriptionInProgress =
            true; // Set flag to indicate transcription in progress
        setLoading(false);
        await transcribeAudio(context, '');
        _transcriptionInProgress =
            false; // Reset flag after transcription is complete
      }
    } catch (e) {
      print('Error stopping transcription: $e');
    }
  }
}
