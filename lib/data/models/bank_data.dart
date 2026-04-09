import 'dynamic_form.dart';

class DynamicBank {
  int? id;
  int? formId;
  int? userId;
  Map<String, DynamicItem>? bank;
  String? access;
  int? status;
  int? isAdmin;
  DateTime? createdAt;
  DateTime? updatedAt;
  BankForm? bankForm;

  DynamicBank({
    this.id,
    this.formId,
    this.userId,
    this.bank,
    this.access,
    this.status,
    this.isAdmin,
    this.createdAt,
    this.updatedAt,
    this.bankForm,
  });

  factory DynamicBank.fromJson(Map<String, dynamic> json) {
    final bankData = json["bank"];
    final bankMap = <String, DynamicItem>{};
    if(bankData != null && bankData is Map<String, dynamic>){
      bankData.forEach((key, value) {
        bankMap[key] = DynamicItem.fromJson(value);
      });
    }

    return DynamicBank(
    id: json["id"],
    formId: json["form_id"],
    userId: json["user_id"],
    bank: bankMap,
    access: json["access"],
    status: json["status"],
    isAdmin: json["is_admin"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    bankForm: json["bank_form"] == null ? null : BankForm.fromJson(json["bank_form"]),
  );
  }

  String toCopy() {
    String value = '';
    if(bank != null){
      for(String slug in bank!.keys){
        final item = bank![slug];
        if(item != null) value = "$value ${item.title ?? ''}: ${item.value ?? ''}";
      }
    }
    return value;
  }

}



class BankForm {
  int? id;
  String? title;
  String? access;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<DynamicField>? fields;
  int? bankIdL;

  BankForm({
    this.id,
    this.title,
    this.access,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.fields,
    this.bankIdL,
  });

  factory BankForm.fromJson(Map<String, dynamic> json) => BankForm(
    id: json["id"],
    title: json["title"],
    access: json["access"],
    status: json["status"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    fields: json["fields"] == null ? [] : List<DynamicField>.from(json["fields"]!.map((x) => DynamicField.fromJson(x))),
  );

  Map<String, dynamic> toJsonSave() {
    Map<String, dynamic> saveMap = { "id": bankIdL, "form_id": id, "access_type": access};
    for(DynamicField field in fields ?? []){
      saveMap[field.slug ?? ''] = field.controllerL?.text.trim() ?? '';
    }
    return saveMap;
  }
}

