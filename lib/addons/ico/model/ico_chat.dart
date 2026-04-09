import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

class IcoChatData {
  List<Conversation>? conversationList;
  List<Admin>? adminList;

  IcoChatData({
    this.conversationList,
    this.adminList,
  });

  factory IcoChatData.fromJson(Map<String, dynamic> json) => IcoChatData(
        conversationList:
            json["conversation_list"] == null ? null : List<Conversation>.from(json["conversation_list"].map((x) => Conversation.fromJson(x))),
        adminList: json["admin_list"] == null ? null : List<Admin>.from(json["admin_list"].map((x) => Admin.fromJson(x))),
      );
}

class Admin {
  int? id;
  String? firstName;
  String? lastName;
  String? photo;
  String? name;

  Admin({this.id, this.firstName, this.lastName, this.photo, this.name});

  factory Admin.fromJson(Map<String, dynamic> json) =>
      Admin(id: json["id"], firstName: json["first_name"], lastName: json["last_name"], photo: json["photo"], name: json["name"]);

  String getName() {
    if (name.isValid) return name!;
    if (firstName.isValid && lastName.isValid) return "$firstName $lastName";
    if (firstName.isValid) return "$firstName";
    if (lastName.isValid) return "$lastName";
    return "";
  }
}

class Conversation {
  int? id;
  int? senderId;
  int? receiverId;
  int? conversationType;
  int? conversationTypeId;
  String? message;
  String? fileName;
  int? isSeen;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? time;
  String? filePath;
  String? senderImg;
  String? receiverImg;
  String? fileType;
  String? senderImgWeb;
  String? receiverImgWeb;
  String? filePathWeb;

  Conversation({
    this.id,
    this.senderId,
    this.receiverId,
    this.conversationType,
    this.conversationTypeId,
    this.message,
    this.fileName,
    this.isSeen,
    this.createdAt,
    this.updatedAt,
    this.time,
    this.filePath,
    this.senderImg,
    this.receiverImg,
    this.fileType,
    this.senderImgWeb,
    this.receiverImgWeb,
    this.filePathWeb,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json["id"],
        senderId: makeInt(json["sender_id"]),
        receiverId: makeInt(json["receiver_id"]),
        conversationType: json["conversation_type"],
        conversationTypeId: json["conversation_type_id"],
        message: json["message"],
        fileName: json["file_name"],
        isSeen: json["is_seen"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        time: json["time"],
        filePath: json["file_path"],
        senderImg: json["sender_img"],
        receiverImg: json["receiver_img"],
        fileType: json["file_type"],
        senderImgWeb: json["sender_img_web"],
        receiverImgWeb: json["receiver_img_web"],
        filePathWeb: json["file_path_web"],
      );
}
