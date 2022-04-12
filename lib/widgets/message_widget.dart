import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/widgets/play_audio.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/chat_list_model.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/widgets/show_image_widget.dart';
import 'package:zapp_app/widgets/show_map_on_message.dart';
import 'package:zapp_app/widgets/show_video_widget.dart';

class MessageWidget extends StatefulWidget {
  final ChatListModel? messageModel;
  final String? image;

  const MessageWidget({Key? key, this.messageModel, this.image}) : super(key: key);

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final utils = AppUtils();
  final commonController = Get.find<CommonController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: widget.messageModel!.sender! == utils.getUserId() ? rightMessageWidget() : leftMessageWidget(),
    );
  }

  leftMessageWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          child: widget.image != null && widget.image != 'default'
              ? CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: widget.image!,
                  height: 30,
                  width: 30,
                  progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                    height: 20,
                    width: 20,
                    child: Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                  ),
                  errorWidget: (context, url, error) => Image.asset("assets/images/profile_placeholder.png", height: 30, width: 30),
                )
              : Image.asset("assets/images/profile_placeholder.png", height: 30, width: 30),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: boxDecoration(AppColors.whiteColor, 'left'),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: showContent(AppColors.primaryColor, 'left')),
              Container(
                margin: const EdgeInsets.only(top: 5, left: 15),
                child: Text(
                  utils.timeAgoSinceDate('', int.parse(widget.messageModel!.time!)),
                  style: const TextStyle(color: Colors.grey, fontSize: 10.0, fontFamily: 'HelveticaNeue'),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  rightMessageWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: boxDecoration(AppColors.primaryColor, 'right'),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: showContent(AppColors.whiteColor, 'right'),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5, right: 10),
                child: Text(
                  utils.timeAgoSinceDate('', int.parse(widget.messageModel!.time!)),
                  style: const TextStyle(color: Colors.grey, fontSize: 10.0, fontFamily: 'HelveticaNeue'),
                ),
              )
            ],
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          child: commonController.myData.profilePicture != null && commonController.myData.profilePicture != 'default'
              ? CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: commonController.myData.profilePicture!,
                  height: 30,
                  width: 30,
                  progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                    height: 20,
                    width: 20,
                    child: Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                  ),
                  errorWidget: (context, url, error) => Image.asset("assets/images/profile_placeholder.png", height: 30, width: 30),
                )
              : Image.asset("assets/images/profile_placeholder.png", height: 30, width: 30),
        ),
      ],
    );
  }

  boxDecoration(color, side) {
    if (widget.messageModel!.type == 'text') {
      return BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(side == 'left' ? 0 : 10),
          topRight: Radius.circular(side == 'left' ? 10 : 0),
          bottomRight: Radius.circular(side == 'left' ? 0 : 10),
          bottomLeft: Radius.circular(side == 'left' ? 10 : 0),
        ),
      );
    } else {
      String filePath = widget.messageModel!.message!
          .toString()
          .replaceAll(RegExp(r'https://firebasestorage.googleapis.com/v0/b/zappapp-e751b.appspot.com/o/ChatsDocuments%2F'), '')
          .split('?')[0];
      final extension = p.extension(filePath);
      if (extension == '.jpg' || extension == '.png' || extension == '.jpeg' || extension == '.gif') {
        return const BoxDecoration(color: Colors.transparent);
      } else if (extension == '.mp4' || extension == '.mov' || extension == '.wmv' || extension == '.avi') {
        return const BoxDecoration(color: Colors.transparent);
      } else {
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(side == 'left' ? 0 : 10),
            topRight: Radius.circular(side == 'left' ? 10 : 0),
            bottomRight: Radius.circular(side == 'left' ? 0 : 10),
            bottomLeft: Radius.circular(side == 'left' ? 10 : 0),
          ),
        );
      }
    }
  }

  showContent(color, side) {
    if (widget.messageModel!.type! == 'text') {
      return Text(
        widget.messageModel!.message!,
        style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold),
      );
    } else if (widget.messageModel!.type! == 'location') {
      return InkWell(
        onTap: () {
          openMap(double.parse(widget.messageModel!.message!.split(',').first), double.parse(widget.messageModel!.message!.split(',').last));
        },
        child: ShowMapOnMessage(
          lat: double.parse(widget.messageModel!.message!.split(',').first),
          lng: double.parse(widget.messageModel!.message!.split(',').last),
        ),
      );
    } else if (widget.messageModel!.type! == 'contact') {
      return SizedBox(
        width: 200,
        child: ListTile(
          title: Text(
            widget.messageModel!.message!.split(',')[0],
            style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            widget.messageModel!.message!.split(',')[1],
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: widget.messageModel!.message!.split(',')[2].isNotEmpty
                ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(widget.messageModel!.message!.split(',')[2])), radius: 25)
                : const CircleAvatar(backgroundImage: AssetImage('assets/images/profile_placeholder.png'), radius: 25),
          ),
        ),
      );
    } else if (widget.messageModel!.type == 'audio') {
      return PlayAudio(url: widget.messageModel!.message, color: color);
    } else {
      String filePath = widget.messageModel!.message!
          .replaceAll(RegExp(r'https://firebasestorage.googleapis.com/v0/b/zappapp-e751b.appspot.com/o/ChatsDocuments%2F'), '')
          .split('?')[0];
      final extension = p.extension(filePath);
      if (extension == '.jpg' || extension == '.png' || extension == '.jpeg' || extension == '.gif') {
        return InkWell(
          onTap: () {
            Get.to(() => ShowImageWidget(image: widget.messageModel!.message!, fileName: filePath));
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: widget.messageModel!.message!,
              height: 150,
              width: 200,
              progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                height: 50,
                width: 50,
                child: Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
              ),
            ),
          ),
        );
      } else if (extension == '.mp4' || extension == '.mov' || extension == '.wmv' || extension == '.avi') {
        return FutureBuilder<Widget>(
            future: getVideoThumb(filePath),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
              if (snapshot.hasData) return snapshot.data!;
              return const CircularProgressIndicator();
            });
      } else {
        return InkWell(
          onTap: () {
            _launchURL(widget.messageModel!.message!);
          },
          child: Text(
            filePath,
            style: TextStyle(fontSize: 15, color: color, decoration: TextDecoration.underline),
          ),
        );
      }
    }
  }

  Future<Widget> getVideoThumb(String filePath) async {
    var fileName = await getThumb(widget.messageModel!.message!);
    return InkWell(
      onTap: () {
        Get.to(() => ShowVideoWidget(videoPath: widget.messageModel!.message!, fileName: filePath));
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Image.memory(fileName, fit: BoxFit.cover, height: 150, width: 200),
          ),
          Container(
            height: 150,
            width: 200,
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            child: const Icon(Icons.videocam, color: Colors.white),
          )
        ],
      ),
    );
  }

  Future<void> openMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  getThumb(message) async {
    Uint8List? fileName = await VideoThumbnail.thumbnailData(video: message, imageFormat: ImageFormat.PNG);
    return fileName!;
  }

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
