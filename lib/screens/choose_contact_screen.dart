import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:get/get.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class ChooseContactScreen extends StatefulWidget {
  const ChooseContactScreen({Key? key}) : super(key: key);

  @override
  _ChooseContactScreenState createState() => _ChooseContactScreenState();
}

class _ChooseContactScreenState extends State<ChooseContactScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  RxBool search = false.obs;
  CommonController commonController = Get.find<CommonController>();
  RxList<Contact> searchedContacts = <Contact>[].obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;

  @override
  void initState() {
    super.initState();
    getContacts();
  }

  getContacts() async {
    print("Getting contacts");
    commonController.contactsList.value = await ContactsService.getContacts();
    print("Success");
    commonController.hasContactData.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          centerTitle: false,
          title: search.value
              ? TextFormField(
                  controller: searchController.value,
                  cursorColor: AppColors.whiteColor,
                  keyboardType: TextInputType.text,
                  autofocus: true,
                  textAlign: TextAlign.start,
                  onChanged: onSearchTextChanged,
                  style: const TextStyle(
                      color: AppColors.whiteColor, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        fontSize: 16,
                        color: AppColors.whiteColor,
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w500),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.whiteColor)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.whiteColor)),
                  ),
                )
              : textUtils.bold20(
                  'Select Contact', AppColors.whiteColor, TextAlign.center),
          elevation: 0.0,
          actions: [
            if (search.value)
              IconButton(
                onPressed: () {
                  search.value = false;
                  searchController.value.text = "";
                },
                icon: const Icon(Icons.close, color: AppColors.whiteColor),
              ),
            if (!search.value)
              IconButton(
                onPressed: () {
                  search.value = true;
                },
                icon: const Icon(Icons.search, color: AppColors.whiteColor),
              ),
          ],
        ),
        body: Obx(() {
          if (commonController.hasContactData.value) {
            if (commonController.contactsList.isNotEmpty) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    if (searchController.value.text.isEmpty)
                      for (int i = 0;
                          i < commonController.contactsList.length;
                          i++)
                        showContact(commonController.contactsList[i]),
                    if (searchController.value.text.isNotEmpty)
                      for (int i = 0; i < searchedContacts.length; i++)
                        showContact(searchedContacts[i]),
                  ],
                ),
              );
            } else {
              return Center(
                  child: textUtils.bold20('No Users Found',
                      AppColors.primaryColor, TextAlign.center));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(
                  backgroundColor: AppColors.whiteColor,
                  color: AppColors.primaryColor),
            );
          }
        }),
      );
    });
  }

  showContact(Contact contact) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.back(result: contact);
          },
          child: ListTile(
            title: textUtils.normal16(contact.displayName ?? '',
                AppColors.blackColor, TextAlign.start),
            leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              child: contact.avatar != null && contact.avatar!.isNotEmpty
                  ? CircleAvatar(backgroundImage: MemoryImage(contact.avatar!))
                  : CircleAvatar(child: Text(contact.initials())),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }

  onSearchTextChanged(String text) {
    searchedContacts.clear();
    if (text.isEmpty) {
      return;
    }

    for (var users in commonController.contactsList) {
      if (users.displayName!.toLowerCase().contains(text.toLowerCase())) {
        setState(() {
          searchedContacts.add(users);
        });
      }
    }
  }
}
