import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';

//cached_video_player: ^2.0.4
//add this package to use the below code
// and add this in info.plist
// <key>NSAppTransportSecurity</key>
//     <dict>
//         <key>NSAllowsArbitraryLoads</key>
//         <true/>
//     </dict>

class CachedVideoPlayerWidget extends StatefulWidget {
  const CachedVideoPlayerWidget({super.key});

  @override
  State<CachedVideoPlayerWidget> createState() => _CachedVideoPlayerWidgetState();
}

class _CachedVideoPlayerWidgetState extends State<CachedVideoPlayerWidget> {
  late PageController _pageController;
  late List<CachedVideoPlayerController> _controllers;
  late int _currentPage = 0;

  List videos = [
    "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controllers = List.generate(
      videos.length,
      (index) => CachedVideoPlayerController.network(
        videos[index],
      ),
    );

    Future.wait(_controllers.map((controller) => controller.initialize()))
        .then((_) {
      // ignore: avoid_function_literals_in_foreach_calls
      _controllers.forEach(
          (controller) => controller.pause()); // Pause all videos initially
      _controllers[_currentPage].play(); // Play the first video
      setState(() {});
    });

    _pageController.addListener(() {
      int newPage = _pageController.page!.toInt();
      if (newPage != _currentPage) {
        _controllers[_currentPage].pause(); // Pause the previous video
        _controllers[newPage].play(); // Play the new video
        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // ignore: avoid_function_literals_in_foreach_calls
    _controllers.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: PageView.builder(
        controller: _pageController,
        // ignore: avoid_print
        onPageChanged: (int page) => {print('page changed to $page')},
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return Center(
            child: _controllers[index].value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controllers[index].value.aspectRatio,
                    child: CachedVideoPlayer(_controllers[index]),
                  )
                : const CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
