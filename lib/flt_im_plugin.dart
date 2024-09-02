import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class FltImPlugin {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  static FltImPlugin? _instance;

  factory FltImPlugin() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel('flt_im_plugin');
      final EventChannel eventChannel = const EventChannel('flt_im_plugin_event');
      _instance = FltImPlugin.private(methodChannel, eventChannel);
    }
    return _instance!;
  }
  FltImPlugin.private(this._methodChannel, this._eventChannel);

  Stream<dynamic>? _listener;

  Stream<dynamic> get onBroadcast {
    if (_listener == null) {
      _listener = _eventChannel.receiveBroadcastStream().map((event) {
        return event;
      });
    }
    return _listener!;
  }

  /// 初始化
  Future<Map?> init({required String host, required String apiURL}) {
    return _methodChannel.invokeMapMethod('init', {'host': host, 'apiURL': apiURL});
  }

  /// 登录
  /// uid 用户id（数字），
  /// token: 用户token,
  Future<Map?> login({required String appid,required String uid, required String token}) async {
    return _methodChannel.invokeMapMethod('login', {'appid': appid,'uid': uid, 'token': token});
  }

  Future<Map?> createConversion({
    required String currentUID,
    required String peerUID,
    bool secret = false,
  }) async {
    return _methodChannel.invokeMethod('createConversion', {
      "currentUID": currentUID,
      "peerUID": peerUID,
      "secret": secret ? 1 : 0,
    });
  }
  Future<Map?> createGroupConversion({
    required String currentUID,
    required String groupUID,
    bool secret = false,
  }) async {
    return _methodChannel.invokeMethod('createGroupConversion', {
      "currentUID": currentUID,
      "groupUID": groupUID,
      "secret": secret ? 1 : 0,
    });
  }
  Future<Map?> createCustomerConversion({
    required String currentUID,
    required String peerUID,
    bool secret = false,
  }) async {
    return _methodChannel.invokeMethod('createCustomerConversion', {
      "currentUID": currentUID,
      "peerUID": peerUID,
      "secret": secret ? 1 : 0,
    });
  }

  Future<Map?> loadData({required String messageID}) {
    return _methodChannel.invokeMapMethod('loadData', {
      'messageID': messageID,
    });
  }

  Future<Map?> loadEarlierData({required String messageID}) {
    return _methodChannel.invokeMapMethod('loadEarlierData', {
      'messageID': messageID,
    });
  }

  Future<Map?> loadLateData({required String messageID}) {
    return _methodChannel.invokeMapMethod('loadLateData', {
      'messageID': messageID,
    });
  }
  Future<Map?> loadCustomerData({required String appId,required String uid,required String messageID}) {
    return _methodChannel.invokeMapMethod('loadCustomerData', {
      'appId': appId,
      'uid': uid,
      'messageID': messageID,
    });
  }

  Future<Map?> loadCustomerEarlierData({required String appId,required String uid,required String messageID}) {
    return _methodChannel.invokeMapMethod('loadCustomerEarlierData', {
      'appId': appId,
      'uid': uid,
      'messageID': messageID,
    });
  }

  Future<Map?> loadCustomerLateData({required String appId,required String uid,required String messageID}) {
    return _methodChannel.invokeMapMethod('loadCustomerLateData', {
      'appId': appId,
      'uid': uid,
      'messageID': messageID,
    });
  }
  /// 登出
  Future<Map?> logout() async {
    return _methodChannel.invokeMethod('logout');
  }

  Future<Map?> sendTextMessage({required bool secret, required String sender, required String receiver, required String rawContent}) async {
    return sendMessage(type: 1, message: {
      'sender': sender,
      'receiver': receiver,
      'rawContent': rawContent,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendRevokeMessage({required bool secret, required String sender, required String receiver, required String uuid}) async {
    return sendMessage(type: 14, message: {
      'sender': sender,
      'receiver': receiver,
      'uuid': uuid,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendGroupRevokeMessage({required bool secret, required String sender, required String receiver, required String uuid}) async {
    return sendGroupMessage(type: 14, message: {
      'sender': sender,
      'receiver': receiver,
      'uuid': uuid,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendImageMessage({required bool secret, required String sender, required String receiver, required Uint8List image}) async {
    return sendMessage(type: 2, message: {
      'sender': sender,
      'receiver': receiver,
      'image': image,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendVideoMessage({
    required  String path,
    required String thumbPath, // android 必传
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendMessage(type: 12, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'thumbPath': thumbPath,
    });
  }

  Future<Map?> sendAudioMessage({
    required String path,
    required int second, // ios 必传
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendMessage(type: 3, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'second': second,
    });
  }

  Future<Map?> sendLocationMessage({
    required double latitude,
    required double longitude,
    required String address,
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendMessage(type: 4, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }

  /// type: 1-text, 2-image, 3-audio, 4-location, 5-group-noti, 6-link
  Future<Map?> sendMessage({
    required int type,
    required Map message,
  }) async {
    return _methodChannel.invokeMapMethod('sendMessage', {
      'type': type,
      'message': message,
    });
  }
  Future<Map?> sendGroupTextMessage({required bool secret, required String sender, required String receiver, required String rawContent}) async {
    return sendGroupMessage(type: 1, message: {
      'sender': sender,
      'receiver': receiver,
      'rawContent': rawContent,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendGroupImageMessage({required bool secret, required String sender, required String receiver, required Uint8List image}) async {
    return sendGroupMessage(type: 2, message: {
      'sender': sender,
      'receiver': receiver,
      'image': image,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendGroupVideoMessage({
  required  path,
      required String thumbPath, // android 必传
      required bool secret,
      required String sender,
      required String receiver,
  }) async {
    return sendGroupMessage(type: 12, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'thumbPath': thumbPath,
    });
  }

  Future<Map?> sendGroupAudioMessage({
    required String path,
    required int second, // ios 必传
    required bool secret,
    required String sender,
    required  String receiver,
  }) async {
    return sendGroupMessage(type: 3, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'second': second,
    });
  }

  Future<Map?> sendGroupLocationMessage({
    required double latitude,
    required double longitude,
    required String address,
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendGroupMessage(type: 4, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }
  /// type: 1-text, 2-image, 3-audio, 4-location, 5-group-noti, 6-link
  Future<Map?> sendGroupMessage({
    required int type,
    required Map message,
  }) async {
    return _methodChannel.invokeMapMethod('sendGroupMessage', {
      'type': type,
      'message': message,
    });
  }


  Future<Map?> sendFlutterTextMessage({required bool secret, required String sender, required String receiver, required String rawContent}) async {
    return sendFlutterMessage(type: 1, message: {
      'sender': sender,
      'receiver': receiver,
      'rawContent': rawContent,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendFlutterRevokeMessage({required bool secret, required String sender, required String receiver, required String uuid}) async {
    return sendFlutterMessage(type: 14, message: {
      'sender': sender,
      'receiver': receiver,
      'uuid': uuid,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendFlutterGroupRevokeMessage({required bool secret, required String sender, required String receiver, required String uuid}) async {
    return sendFlutterGroupMessage(type: 14, message: {
      'sender': sender,
      'receiver': receiver,
      'uuid': uuid,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendFlutterImageMessage({required bool secret, required String sender, required String receiver, required String path,required String thumbPath}) async {
    return sendFlutterMessage(type: 2, message: {
      'sender': sender,
      'receiver': receiver,
      'path': path,
      'thumbPath': thumbPath,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendFlutterVideoMessage({
    required  String path,
    required String thumbPath, // android 必传
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendFlutterMessage(type: 12, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'thumbPath': thumbPath,
    });
  }

  Future<Map?> sendFlutterAudioMessage({
    required String path,
    required int second, // ios 必传
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendFlutterMessage(type: 3, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'second': second,
    });
  }

  Future<Map?> sendFlutterLocationMessage({
    required double latitude,
    required double longitude,
    required String address,
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendFlutterMessage(type: 4, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }

  /// type: 1-text, 2-image, 3-audio, 4-location, 5-group-noti, 6-link
  Future<Map?> sendFlutterMessage({
    required int type,
    required Map message,
  }) async {
    return _methodChannel.invokeMapMethod('sendFlutterMessage', {
      'type': type,
      'message': message,
    });
  }
  Future<Map?> sendFlutterGroupTextMessage({required bool secret, required String sender, required String receiver, required String rawContent}) async {
    return sendGroupMessage(type: 1, message: {
      'sender': sender,
      'receiver': receiver,
      'rawContent': rawContent,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendFlutterGroupImageMessage({required bool secret, required String sender, required String receiver, required String path,required String thumbPath}) async {
    return sendGroupMessage(type: 2, message: {
      'sender': sender,
      'receiver': receiver,
      'path': path,
      'thumbPath': thumbPath,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendFlutterGroupVideoMessage({
    required  path,
    required String thumbPath, // android 必传
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendFlutterGroupMessage(type: 12, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'thumbPath': thumbPath,
    });
  }

  Future<Map?> sendFlutterGroupAudioMessage({
    required String path,
    required int second, // ios 必传
    required bool secret,
    required String sender,
    required  String receiver,
  }) async {
    return sendFlutterGroupMessage(type: 3, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'second': second,
    });
  }

  Future<Map?> sendFlutterGroupLocationMessage({
    required double latitude,
    required double longitude,
    required String address,
    required bool secret,
    required String sender,
    required String receiver,
  }) async {
    return sendFlutterGroupMessage(type: 4, message: {
      'sender': sender,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }
  /// type: 1-text, 2-image, 3-audio, 4-location, 5-group-noti, 6-link
  Future<Map?> sendFlutterGroupMessage({
    required int type,
    required Map message,
  }) async {
    return _methodChannel.invokeMapMethod('sendFlutterGroupMessage', {
      'type': type,
      'message': message,
    });
  }

  Future<Map?> sendFlutterCustomerTextMessage({required bool secret, required String sender_appid, required String sender, required String receiver_appid, required String receiver, required String rawContent}) async {
    return sendFlutterCustomerMessage(type: 1, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'rawContent': rawContent,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendFlutterCustomerImageMessage({required bool secret, required String sender_appid, required String sender, required String receiver_appid, required String receiver,  required String path,required String thumbPath}) async {
    return sendFlutterCustomerMessage(type: 2, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'path': path,
      'thumbPath': thumbPath,
      'secret': secret ? 1 : 0,
    });
  }

  Future<Map?> sendFlutterCustomerVideoMessage({
    required  path,
    required String thumbPath, // android 必传
    required bool secret,
    required String sender_appid, required String sender, required String receiver_appid, required String receiver,
  }) async {
    return sendFlutterCustomerMessage(type: 12, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'thumbPath': thumbPath,
    });
  }

  Future<Map?> sendFlutterCustomerAudioMessage({
    required String path,
    required int second, // ios 必传
    required bool secret,
    required String sender_appid, required String sender, required String receiver_appid, required String receiver,
  }) async {
    return sendFlutterCustomerMessage(type: 3, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'secret': secret ? 1 : 0,
      'path': path,
      'second': second,
    });
  }

  Future<Map?> sendFlutterCustomerLocationMessage({
    required double latitude,
    required double longitude,
    required String address,
    required bool secret,
    required String sender_appid, required String sender, required String receiver_appid, required String receiver,
  }) async {
    return sendFlutterCustomerMessage(type: 4, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'secret': secret ? 1 : 0,
    });
  }
  Future<Map?> sendCustomerRevokeMessage({  required String sender_appid, required String sender, required String receiver_appid, required String receiver, required String uuid}) async {
    return sendFlutterCustomerMessage(type: 14, message: {
      'sender_appid': sender_appid,
      'sender': sender,
      'receiver_appid': receiver_appid,
      'receiver': receiver,
      'uuid': uuid,
      'secret': 0,
    });
  }
  /// type: 1-text, 2-image, 3-audio, 4-location, 5-group-noti, 6-link
  Future<Map?> sendFlutterCustomerMessage({
    required int type,
    required Map message,
  }) async {
    return _methodChannel.invokeMapMethod('sendFlutterCustomerMessage', {
      'type': type,
      'message': message,
    });
  }


  Future<Map?> getLocalCacheImage({required String url}) async {
    return _methodChannel.invokeMapMethod('getLocalCacheImage', {
      'url': url,
    });
  }
  Future<Map?> getLocalMediaURL({required String url}) async {
    return _methodChannel.invokeMapMethod('getLocalMediaURL', {
      'url': url,
    });
  }


  Future<Map?> clearReadCount({required String cid}) async {
    return _methodChannel.invokeMapMethod('clearReadCount', {
      'cid': cid,
    });
  }
  Future<Map?> clearGroupReadCount({required String cid}) async {
    return _methodChannel.invokeMapMethod('clearGroupReadCount', {
      'cid': cid,
    });
  }
  Future<Map?> clearCustomerReadCount({required String appid,required String cid}) async {
    return _methodChannel.invokeMapMethod('clearCustomerReadCount', {
      'appid': appid,
      'cid': cid,
    });
  }


  Future<Map?> getConversations() async {
    return _methodChannel.invokeMapMethod('getConversations', {});
  }
  Future<Map?> deleteConversation({ required String rowid,required String cid, String appid="0",String type ="0"}) async {
    return _methodChannel.invokeMapMethod('deleteConversation', {'rowid':rowid,'cid': cid, 'appid': appid,'type': type});
  }


  Future<Map?> deletePeerMessage({required String id}) async {
    return _methodChannel.invokeMapMethod('deletePeerMessage', {'id': id});
  }
  Future<Map?> deleteGroupMessage({required String id}) async {
    return _methodChannel.invokeMapMethod('deleteGroupMessage', {'id': id});
  }
  Future<Map?> deleteCustomerMessage({required String id}) async {
    return _methodChannel.invokeMapMethod('deleteCustomerMessage', {'id': id});
  }


  Future<Map?> voiceCall(String peerId) async {
    return _methodChannel.invokeMapMethod('voice_call', {'uid': "1",'peer_id':peerId});
  }
  Future<Map?> voiceReceiveCall() async {
    return _methodChannel.invokeMapMethod('voice_receive_call', {'uid': "uid",'peer_id':"peerId",'channel_id':"channelId"});
  }
  Future<Map?> videoCall(String peerId) async {
    return _methodChannel.invokeMapMethod('video_call', {'uid': "1",'peer_id':peerId});
  }
  Future<Map?> VideoReceiveCall() async {
    return _methodChannel.invokeMapMethod('video_receive_call', {'uid': "1",'peer_id':"peerId",'channel_id':"channelId"});
  }


}
