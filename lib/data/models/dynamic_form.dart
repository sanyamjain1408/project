import 'package:flutter/cupertino.dart';

class DynamicField {
  int? id;
  int? formId;
  String? title;
  String? slug;
  String? dataType;
  int? required;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? errorL;
  TextEditingController? controllerL;

  DynamicField({
    this.id,
    this.formId,
    this.title,
    this.slug,
    this.dataType,
    this.required,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.errorL,
    this.controllerL,
  });

  factory DynamicField.fromJson(Map<String, dynamic> json) => DynamicField(
    id: json["id"],
    formId: json["form_id"],
    title: json["title"],
    slug: json["slug"],
    dataType: json["data_type"],
    required: json["required"],
    status: json["status"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "form_id": formId,
    "title": title,
    "slug": slug,
    "data_type": dataType,
    "required": required,
    "status": status,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class DynamicItem {
  String? title;
  String? value;

  DynamicItem({
    this.title,
    this.value,
  });

  factory DynamicItem.fromJson(Map<String, dynamic> json) => DynamicItem(
    title: json["title"],
    value: (json["value"] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "value": value,
  };
}