import 'dart:convert';
import 'dart:io';


import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';

import '../../helper/data_process_helper.dart';
import '../../ui/ui_helper/maintains_mood_widgets.dart';
import '../models/settings.dart';

class APIProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = APIURLConstants.baseUrl;
    httpClient.maxAuthRetries = 3;
    httpClient.timeout = const Duration(seconds: 60);
    super.onInit();
  }

  /// *** Common Server Request *** ///
  Future<ServerResponse> postRequest(String url, Map body, Map<String, String> headers, {bool? isDynamic}) async {
    printFunction("postRequest body", body);
    printFunction("postRequest headers", headers);
    final response = await post(url, body, headers: headers);
    GetUtils.printFunction("postRequest url", response.request?.url, "");
    return handleResponse(response, isDynamic: isDynamic);
  }

  Future<ServerResponse> getRequest(String url, Map<String, String> headers, {Map<String, dynamic>? query, bool? isDynamic}) async {
    printFunction("getRequest query", query);
    printFunction("getRequest headers", headers);
    final response = await get(url, headers: headers, query: query);
    printFunction("getRequest url ", response.request?.url);
    return handleResponse(response, isDynamic: isDynamic);
  }

  Future<ServerResponse> postRequestFormData(String url, Map<String, dynamic> body, Map<String, String> headers, {bool? isDynamic}) async {
    printFunction("postRequestFormData body", body);
    printFunction("postRequestFormData headers", headers);
    final response = await post(url, FormData(body), headers: headers);
    printFunction("postRequestFormData url", response.request?.url);
    return handleResponse(response, isDynamic: isDynamic);
  }

  Future<ServerResponse> uploadFile(String url, List<int> img, String filename, Map<String, String> headers) async {
    printFunction("uploadFile headers", headers);
    final avatar = MultipartFile(img, filename: filename);
    final response = await post(url, FormData({APIKeyConstants.vProfilePhotoPath: avatar}), headers: headers);
    printFunction("uploadFile url", response.request?.url);
    return handleResponse(response);
  }

  Future<ServerResponse> handleResponse(Response response, {bool? isDynamic}) async {
    printFunction("handleResponse statusText", response.statusText);
    printFunction("handleResponse statusCode", response.statusCode);
    printFunction("handleResponse hasError", response.status.hasError);
    if (response.statusCode == 401) {
      logOutActions();
      return ServerResponse(success: false, message: response.statusText ?? "Unauthorized");
    }

    if (response.status.hasError) {
      if (response.status.connectionError) {
        return ServerResponse(success: false, message: "Please verify your internet connection and try again".tr);
      }
      final text = response.statusText ?? "Something went wrong";
      return ServerResponse(success: false, message: text);
    } else {
      printFunction("handleResponse body", response.body);
      Maintenance? maintenance = DataProcessHelper.checkMaintenanceMood(response.body);
      if (maintenance != null) {
        Get.offAll(()=> MaintainsMoodOnScreen(maintenance: maintenance));
        return Future.error(maintenance.maintenanceModeTitle ?? "Exchange is unavailable due to maintenance".tr);
      } else if (isDynamic != null && isDynamic) {
        return ServerResponse(success: true, message: "", data: response.body);
      }
      return ServerResponse.fromJson(response.body);
    }
  }
}

/// Dedicated HTTP client for Spot API calls.
/// Uses dart:io HttpClient directly to avoid GetConnect baseUrl prepending issues.
class SpotAPIProvider {
  static const _timeout = Duration(seconds: 30);

  Future<ServerResponse> getRequest(String url, Map<String, String> headers, {Map<String, dynamic>? query}) async {
    try {
      var uri = Uri.parse(url);
      if (query != null && query.isNotEmpty) {
        final q = query.map((k, v) => MapEntry(k, v.toString()));
        uri = uri.replace(queryParameters: {...uri.queryParameters, ...q});
      }
      printFunction("SpotAPI GET", uri.toString());
      final request = await HttpClient().getUrl(uri);
      headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close().timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      printFunction("SpotAPI GET error", e);
      return ServerResponse(success: false, message: e.toString());
    }
  }

  Future<ServerResponse> postRequest(String url, Map<String, dynamic> body, Map<String, String> headers) async {
    try {
      final uri = Uri.parse(url);
      printFunction("SpotAPI POST", uri.toString());
      printFunction("SpotAPI POST body", body);
      final request = await HttpClient().postUrl(uri);
      request.headers.contentType = ContentType.json;
      headers.forEach((k, v) => request.headers.set(k, v));
      request.write(json.encode(body));
      final response = await request.close().timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      printFunction("SpotAPI POST error", e);
      return ServerResponse(success: false, message: e.toString());
    }
  }

  Future<ServerResponse> deleteRequest(String url, Map<String, String> headers) async {
    try {
      final uri = Uri.parse(url);
      printFunction("SpotAPI DELETE", uri.toString());
      final request = await HttpClient().deleteUrl(uri);
      headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close().timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      printFunction("SpotAPI DELETE error", e);
      return ServerResponse(success: false, message: e.toString());
    }
  }

  Future<ServerResponse> _handleResponse(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    printFunction("SpotAPI response status", response.statusCode);
    printFunction("SpotAPI response body", body);
    if (response.statusCode == 401) {
      logOutActions();
      return ServerResponse(success: false, message: "Unauthorized");
    }

    dynamic decoded;
    try {
      decoded = json.decode(body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Extract error message from body if available
      String errMsg = "HTTP ${response.statusCode}";
      if (decoded is Map) {
        errMsg = decoded['message']?.toString()
            ?? decoded['error']?.toString()
            ?? errMsg;
        if (decoded['errors'] is Map) {
          final errs = decoded['errors'] as Map;
          errMsg = errs.values.first?.toString() ?? errMsg;
        }
      }
      return ServerResponse(success: false, message: errMsg, data: decoded);
    }
    if (decoded == null) {
      return ServerResponse(success: false, message: "Invalid response");
    }
    return ServerResponse(success: true, message: "", data: decoded);
  }
}
