class CallHistoryModel {
  final String? name, type, callType, time, avatarUrl;

  CallHistoryModel({this.name, this.type, this.callType, this.time, this.avatarUrl});
}

List<CallHistoryModel> dummyData = [
  CallHistoryModel(
      name: 'Salman Ashfaq',
      type: 'Audio',
      time: 'Yesterday, 11:20 PM',
      callType: 'Incoming',
      avatarUrl: "https://cdn.pixabay.com/photo/2015/06/22/08/40/child-817373__340.jpg"),
  CallHistoryModel(
      name: 'Junaid Khan',
      type: 'Audio',
      time: 'December 19, 6:17 PM',
      callType: 'Outgoing',
      avatarUrl: "https://cdn.pixabay.com/photo/2015/03/03/20/42/man-657869__340.jpg"),
  CallHistoryModel(
      name: 'Anser Iqbal',
      type: 'Audio',
      time: 'December 19, 11:20 PM',
      callType: 'Incoming',
      avatarUrl: "https://cdn.pixabay.com/photo/2019/08/21/16/03/panda-4421395__340.jpg"),
  CallHistoryModel(
      name: 'Kashif Nazeer',
      type: 'Video',
      time: 'December 19, 11:30 PM',
      callType: 'Outgoing',
      avatarUrl: "https://cdn.pixabay.com/photo/2018/02/06/08/11/animal-world-3134166__340.jpg"),
  CallHistoryModel(
      name: 'Arslan Cornolius',
      type: 'Audio',
      time: 'December 19, 05:30 PM',
      callType: 'Incoming',
      avatarUrl: "https://cdn.pixabay.com/photo/2015/03/26/10/39/teapot-691729__340.jpg"),
  CallHistoryModel(
      name: 'Asfand Naveed',
      type: 'Audio',
      time: 'December 16, 1:15 PM',
      callType: 'Incoming',
      avatarUrl: "https://cdn.pixabay.com/photo/2017/05/30/14/08/stefan-2357089__340.jpg"),
  CallHistoryModel(
      name: 'Amanullah',
      type: 'Video',
      time: 'December 15, 2:45 PM',
      callType: 'Incoming',
      avatarUrl: "https://cdn.pixabay.com/photo/2014/01/18/19/23/bodyguard-247682__340.jpg")
];
