class IcoLunchDynamicForm {
  String? dynamicFormForIcoTitle;
  String? dynamicFormForIcoDescription;
  List<DynamicForm>? dynamicForm;

  IcoLunchDynamicForm({
    this.dynamicFormForIcoTitle,
    this.dynamicFormForIcoDescription,
    this.dynamicForm,
  });

  factory IcoLunchDynamicForm.fromJson(Map<String, dynamic> json) => IcoLunchDynamicForm(
        dynamicFormForIcoTitle: json["dynamic_form_for_ico_title"] is String? ? json["dynamic_form_for_ico_title"] : null,
        dynamicFormForIcoDescription: json["dynamic_form_for_ico_description"] is String? ? json["dynamic_form_for_ico_description"] : null,
        dynamicForm: json["dynamic_form"] == null ? null : List<DynamicForm>.from(json["dynamic_form"].map((x) => DynamicForm.fromJson(x))),
      );
}

class DynamicForm {
  int? id;
  dynamic name;
  String? title;
  int? type;
  int? required;
  int? isOption;
  List<String>? optionList;
  int? isFile;
  String? fileType;
  dynamic fileLink;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic value;

  DynamicForm({
    this.id,
    this.name,
    this.title,
    this.type,
    this.required,
    this.isOption,
    this.optionList,
    this.isFile,
    this.fileType,
    this.fileLink,
    this.createdAt,
    this.updatedAt,
    this.value
  });

  factory DynamicForm.fromJson(Map<String, dynamic> json) => DynamicForm(
        id: json["id"],
        name: json["name"],
        title: json["title"],
        type: json["type"],
        required: json["required"],
        isOption: json["is_option"],
        optionList: json["optionList"] == null ? null : List<String>.from(json["optionList"].map((x) => x)),
        isFile: json["is_file"],
        fileType: json["file_type"],
        fileLink: json["file_link"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}
