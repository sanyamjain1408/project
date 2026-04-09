import 'package:flutter/material.dart';
import 'package:get/get.dart';

List getApprovedStatusData(int? status) {
  switch (status) {
    case 0:
      return ["Pending".tr, Colors.amber];
    case 1:
      return ["Accepted".tr, Colors.green];
    case 2:
      return ["Rejected".tr, Colors.red];
  }
  return ["N/A".tr, Get.theme.primaryColor];
}

String getCurrencyTypeText(int? status) {
  switch (status) {
    case 1:
      return "Fiat".tr;
    case 2:
      return "Crypto".tr;
  }
  return "N/A".tr;
}
