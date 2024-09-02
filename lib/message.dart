import 'value_util.dart';

//// 对应的常量

const MSG_HEARTBEAT = 1;
const MSG_AUTH_STATUS = 3;
const MSG_IM = 4;
const MSG_ACK = 5;
const MSG_GROUP_NOTIFICATION = 7;
const MSG_GROUP_IM = 8;
const MSG_PING = 13;
const MSG_PONG = 14;
const MSG_AUTH_TOKEN = 15;
const MSG_RT = 17;
const MSG_ENTER_ROOM = 18;
const MSG_LEAVE_ROOM = 19;
const MSG_ROOM_IM = 20;
const MSG_SYSTEM = 21;
const MSG_UNREAD_COUNT = 22;
const MSG_CUSTOMER = 24;
const MSG_CUSTOMER_SUPPORT = 25;
//客户端->服务端
const MSG_SYNC = 26; //同步消息
//服务端->客服端
const MSG_SYNC_BEGIN = 27;
const MSG_SYNC_END = 28;
//通知客户端有新消息
const MSG_SYNC_NOTIFY = 29;

//客户端->服务端
const MSG_SYNC_GROUP = 30; //同步超级群消息
//服务端->客服端
const MSG_SYNC_GROUP_BEGIN = 31;
const MSG_SYNC_GROUP_END = 32;
//通知客户端有新消息
const MSG_SYNC_GROUP_NOTIFY = 33;

//客服端->服务端
const MSG_SYNC_KEY = 34;
const MSG_GROUP_SYNC_KEY = 35;

const MSG_METADATA = 37;

const PLATFORM_IOS = 1;
const PLATFORM_ANDROID = 2;
const PLATFORM_WEB = 3;

//message flag
const MSG_FLAG_TEXT = 1;
const MSG_FLAG_UNPERSISTENT = 2;
const MSG_FLAG_GROUP = 4;
const MSG_FLAG_SELF = 8;
const MSG_FLAG_PUSH = 0x10;
const MSG_FLAG_SUPER_GROUP = 0x20;

//message ack
const MSG_ACK_SUCCESS = 0;
const MSG_ACK_NOT_MY_FRIEND = 1;
const MSG_ACK_NOT_YOUR_FRIEND = 2;
const MSG_ACK_IN_YOUR_BLACKLIST = 3;
const MSg_ACK_NOT_GROUP_MEMBER = 64;

class IMMessage {
  String sender ="";
  String receiver="";
  int timestamp=0;
  int msgLocalID=0;
  String content="";
  String plainContent="";
  bool secret=false;
  bool isText=false;
  bool isSelf=false;
  bool isGroupNotification=false;

  IMMessage.fromMap(Map json) {
    sender = ValueUtil.toStr(json['sender']);
    receiver = ValueUtil.toStr(json['receiver']);
    timestamp = ValueUtil.toInt(json['timestamp']);
    msgLocalID = ValueUtil.toInt(json['msgLocalID']);
    content = ValueUtil.toStr(json['content']);
    plainContent = ValueUtil.toStr(json['plainContent']);
    secret = ValueUtil.toBool(json['secret']);
    isText = ValueUtil.toBool(json['isText']);
    isSelf = ValueUtil.toBool(json['isSelf']);
    isGroupNotification = ValueUtil.toBool(json['isGroupNotification']);
  }
}

enum MessageType {
  MESSAGE_UNKNOWN,
  MESSAGE_TEXT,
  MESSAGE_IMAGE,
  MESSAGE_AUDIO,
  MESSAGE_LOCATION,
  MESSAGE_GROUP_NOTIFICATION, // 群通知
  MESSAGE_LINK,
  MESSAGE_HEADLINE, // 客服标题
  MESSAGE_VOIP,
  MESSAGE_GROUP_VOIP,
  MESSAGE_P2P_SESSION,
  MESSAGE_SECRET,
  MESSAGE_VIDEO,
  MESSAGE_FILE,
  MESSAGE_REVOKE,
  MESSAGE_ACK,
  MESSAGE_CLASSROOM, // 群课堂
  MESSAGE_TIME_BASE, // 虚拟的消息，不会存入磁盘
  MESSAGE_ATTACHMENT, // 消息附件， 只存在本地磁盘
}

extension MessageTypeStringParse on String {
  MessageType get messageType {
    switch (this) {
      case "MESSAGE_UNKNOWN":
        return MessageType.MESSAGE_UNKNOWN;
      case "MESSAGE_TEXT":
        return MessageType.MESSAGE_TEXT;
      case "MESSAGE_IMAGE":
        return MessageType.MESSAGE_IMAGE;
      case "MESSAGE_AUDIO":
        return MessageType.MESSAGE_AUDIO;
      case "MESSAGE_LOCATION":
        return MessageType.MESSAGE_LOCATION;
      case "MESSAGE_GROUP_NOTIFICATION":
        return MessageType.MESSAGE_GROUP_NOTIFICATION;
      case "MESSAGE_LINK":
        return MessageType.MESSAGE_LINK;
      case "MESSAGE_HEADLINE":
        return MessageType.MESSAGE_HEADLINE;
      case "MESSAGE_VOIP":
        return MessageType.MESSAGE_VOIP;
      case "MESSAGE_GROUP_VOIP":
        return MessageType.MESSAGE_GROUP_VOIP;
      case "MESSAGE_P2P_SESSION":
        return MessageType.MESSAGE_P2P_SESSION;
      case "MESSAGE_SECRET":
        return MessageType.MESSAGE_SECRET;
      case "MESSAGE_VIDEO":
        return MessageType.MESSAGE_VIDEO;
      case "MESSAGE_FILE":
        return MessageType.MESSAGE_FILE;
      case "MESSAGE_REVOKE":
        return MessageType.MESSAGE_REVOKE;
      case "MESSAGE_ACK":
        return MessageType.MESSAGE_ACK;
      case "MESSAGE_CLASSROOM":
        return MessageType.MESSAGE_CLASSROOM;
      case "MESSAGE_TIME_BASE":
        return MessageType.MESSAGE_TIME_BASE;
      case "MESSAGE_ATTACHMENT":
        return MessageType.MESSAGE_ATTACHMENT;
      default:
        return MessageType.MESSAGE_UNKNOWN;
    }
  }
}

extension MessageTypeParse on int {
  MessageType get messageType {
    switch (this) {
      case 1:
        return MessageType.MESSAGE_TEXT;
      case 2:
        return MessageType.MESSAGE_IMAGE;
      case 3:
        return MessageType.MESSAGE_AUDIO;
      case 4:
        return MessageType.MESSAGE_LOCATION;
      case 5:
        return MessageType.MESSAGE_GROUP_NOTIFICATION; // 群通知
      case 6:
        return MessageType.MESSAGE_LINK;
      case 7:
        return MessageType.MESSAGE_HEADLINE; // 客服标题
      case 8:
        return MessageType.MESSAGE_VOIP;
      case 9:
        return MessageType.MESSAGE_GROUP_VOIP;
      case 10:
        return MessageType.MESSAGE_P2P_SESSION;
      case 11:
        return MessageType.MESSAGE_SECRET;
      case 12:
        return MessageType.MESSAGE_VIDEO;
      case 13:
        return MessageType.MESSAGE_FILE;
      case 14:
        return MessageType.MESSAGE_REVOKE;
      case 15:
        return MessageType.MESSAGE_ACK;
      case 16:
        return MessageType.MESSAGE_CLASSROOM; // 群课堂
      case 254:
        return MessageType.MESSAGE_TIME_BASE; // 虚拟的消息，不会存入磁盘
      case 255:
        return MessageType.MESSAGE_ATTACHMENT;
      default:
        return MessageType.MESSAGE_UNKNOWN;
    }
  }
}

class SendInfo {
  String avatarURL="";
  String uid="";
  String name="";
  String identifier="";
  SendInfo.fromMap(Map json) {
    avatarURL = ValueUtil.toStr(json['avatarURL']);
    uid = ValueUtil.toStr(json['uid']);
    name = ValueUtil.toStr(json['name']);
    identifier = ValueUtil.toStr(json['identifier']);
  }
}

class Message {
  bool isFailure=false;
  bool uploading=false;
  bool secret=false;
  bool geocoding=false;
  String uuid="";
  bool isOutgoing=false;
  SendInfo? sendInfo;
  MessageType? type;
  int flags=0;
  int progress=0;
  int playing=0;
  int timestamp=0;
  int msgLocalID=0;
  String sender="";
  int msgId=0;
  String receiver="";
  bool isACK=false;
  String rawContent="";
  bool isListened=false;
  bool isIncomming=false;
  bool downloading=false;
  Map? content;
  Message.fromMap(Map json) {
    isFailure = ValueUtil.toBool(json['isFailure']);
    uploading = ValueUtil.toBool(json['uploading']);
    secret = ValueUtil.toBool(json['secret']);
    geocoding = ValueUtil.toBool(json['geocoding']);
    uuid = ValueUtil.toStr(json['uuid']);
    isOutgoing = ValueUtil.toBool(json['isOutgoing']);
    sendInfo = SendInfo.fromMap(ValueUtil.toMap(json['sendInfo']));
    var typeobj = json['type'];

    if (typeobj is num) {
      type = ValueUtil.toInt(typeobj).messageType;
    } else {
      type = ValueUtil.toStr(typeobj).messageType;
    }
    flags = ValueUtil.toInt(json['flags']);
    progress = ValueUtil.toInt(json['progress']);
    playing = ValueUtil.toInt(json['playing']);
    timestamp = ValueUtil.toInt(json['timestamp']);
    msgLocalID = ValueUtil.toInt(json['msgLocalID']);
    sender = ValueUtil.toStr(json['sender']);
    msgId = ValueUtil.toInt(json['msgId']);
    receiver = ValueUtil.toStr(json['receiver']);
    isACK = ValueUtil.toBool(json['isACK']);
    rawContent = ValueUtil.toStr(json['rawContent']);
    isListened = ValueUtil.toBool(json['isListened']);
    isIncomming = ValueUtil.toBool(json['isIncomming']);
    downloading = ValueUtil.toBool(json['downloading']);
    content = ValueUtil.toMap(json['content']);
  }
}
