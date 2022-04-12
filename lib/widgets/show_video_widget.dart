import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_viewer/video_viewer.dart';

class ShowVideoWidget extends StatefulWidget {
  final String? videoPath, fileName;

  const ShowVideoWidget({Key? key, this.videoPath, this.fileName}) : super(key: key);

  @override
  _ShowVideoWidgetState createState() => _ShowVideoWidgetState();
}

class _ShowVideoWidgetState extends State<ShowVideoWidget> {
  final VideoViewerController controller = VideoViewerController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.arrow_back, size: 25, color: Colors.white),
          ),
        ),
        title: Text(
          widget.fileName!,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
        ),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        color: Colors.black,
        child: VideoViewer(
          controller: controller,
          onFullscreenFixLandscape: true,
          enableFullscreenScale: true,
          autoPlay: true,
          source: {
            widget.videoPath!: VideoSource(
              video: VideoPlayerController.network(widget.videoPath!),
            ),
          },
        ),
      ),
    );
  }
}
