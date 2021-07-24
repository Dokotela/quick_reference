import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wvems_protocols/models/models.dart';
import 'package:wvems_protocols/models/temp_messages.dart';

class MessagingController extends GetxController {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late NotificationSettings settings;
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.max,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GetStorage store = GetStorage();

  final messages = <AppMessage>{}.obs;

  final tempMessages = tempMessageSet.obs;

  bool hasNewMessage() {
    final newMessageList = tempMessages.where((element) => !element.beenRead);
    return newMessageList.isNotEmpty;
  }

  void toggleRead(AppMessage appMessage) {
    tempMessages.remove(appMessage);
    tempMessages.add(
      appMessage.copyWith(beenRead: !appMessage.beenRead),
    );
  }

  void removeMessage(AppMessage appMessage) {
    Get.defaultDialog(
      title: 'Delete message?',
      middleText: 'Are you sure you want to delete this message?',
      textConfirm: 'DELETE',
      onConfirm: () {
        Get.back();
        tempMessages.remove(appMessage);
      },
      onCancel: () => Get.back(),
    );
  }

  /// *************** Initialize Class and necessary values ****************///
  @override
  Future<void> onInit() async {
    settings = await _requestPermissions();
    await _createNotificationChannel();
    await loadMessagesFromStore();
    super.onInit();
    listen();
  }

  Future<void> loadMessagesFromStore() async {
    final Map<String, dynamic> storeMessages = store.read('messages') ?? {};
    if (storeMessages.isNotEmpty) {
      // first, convert all messages to JSON prior to storing
      final messagesAsModel = <AppMessage>{};
      storeMessages.forEach(
        (key, value) => messagesAsModel.add(AppMessage.fromJson(value)),
      );
      // messages.addAll(List<AppMessage>.from(storeMessages));
    }
    await saveMessagesToStore();
  }

  Future<void> saveMessagesToStore() async {
    // first, convert all messages to JSON prior to storing
    final messagesAsJson = <String, dynamic>{};
    messages.forEach((e) {
      messagesAsJson[e.title] = e.toJson();
    });
    await store.write('messages', messagesAsJson);
  }

  Future<void> listen() async {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        final RemoteNotification? notification = message.notification;
        final AndroidNotification? android = message.notification?.android;

        // If `onMessage` is triggered with a notification, construct our own
        // local notification to show to users using the created channel.
        // todo: this is currently setup for android only
        // todo: add iOS configuration
        if (notification != null && android != null) {
          print('${notification.title ?? ''} ${notification.body ?? ''}');
          messages.add(
            AppMessage(
              title: notification.title ?? '',
              body: notification.body ?? '',
              dateTime: DateTime.now(),
              beenRead: false,
            ),
          );
          await saveMessagesToStore();

          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channel.description,
                  icon: 'ic_launcher',
                ),
              ));
        }
      },
    );
  }

  /// ************* Initialize Class and necessary values ***************///
  Future<NotificationSettings> _requestPermissions() async =>
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

  Future<void> _createNotificationChannel() async =>
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
}
