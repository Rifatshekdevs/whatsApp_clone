import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class ShowImageWidget extends StatelessWidget {
  final String? image, fileName;

  const ShowImageWidget({Key? key, this.image, this.fileName}) : super(key: key);

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
          fileName!,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
        ),
      ),
      body: Container(
        color: Colors.black,
        height: double.infinity,
        alignment: Alignment.center,
        child: PhotoView(imageProvider: NetworkImage(image!)),
      ),
    );
  }
}
