import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zapp_app/model/calls_histrory_model.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

import '../../colors.dart';

class CallHistoryFragment extends StatefulWidget {
  const CallHistoryFragment({Key? key}) : super(key: key);

  @override
  _CallHistoryFragmentState createState() => _CallHistoryFragmentState();
}

class _CallHistoryFragmentState extends State<CallHistoryFragment> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: textUtils.bold20('Call History', AppColors.whiteColor, TextAlign.center),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < dummyData.length; i++) showCallHistory(dummyData[i]),
          ],
        ),
      ),
    );
  }

  showCallHistory(CallHistoryModel callHistoryModel) {
    return Column(
      children: [
        ListTile(
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: callHistoryModel.avatarUrl!,
              height: 50,
              width: 50,
              progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                height: 30,
                width: 30,
                child: Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
              ),
              errorWidget: (context, url, error) => Image.asset("assets/images/profile_placeholder.png", height: 50, width: 50),
            ),
          ),
          trailing: Icon(callHistoryModel.type == 'Audio' ? Icons.call : Icons.videocam, color: AppColors.accentColor),
          title: textUtils.bold16(callHistoryModel.name!, AppColors.blackColor, TextAlign.start),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(callHistoryModel.callType == 'Incoming' ? Icons.call_received : Icons.call_made, color: AppColors.accentColor),
              SizedBox(width: 5),
              textUtils.normal14(callHistoryModel.time!, Colors.grey, TextAlign.start)
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }
}
