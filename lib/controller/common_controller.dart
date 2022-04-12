import 'package:contacts_service/contacts_service.dart';
import 'package:get/get.dart';
import 'package:zapp_app/model/chat_list_model.dart';
import 'package:zapp_app/model/user_model.dart';

class CommonController extends GetxController {
  List<ChatListModel> chatListModel = <ChatListModel>[].obs;
  List<ChatListModel> messageListModel = <ChatListModel>[].obs;
  RxList<Contact> contactsList = <Contact>[].obs;
  List<UserModel> userModel = <UserModel>[].obs;
  UserModel myData = UserModel();
  RxBool hasContactData = false.obs;
  RxBool isShow = false.obs;
  RxBool isFirstTime = true.obs;
}
