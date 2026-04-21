import 'dart:convert';

import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import 'api_repository.dart';

class HttpAPIProvider{

  Future<ServerResponse> postRequest(String url, Map<String, dynamic> body, Map<String, String> headers, {bool? isDynamic}) async {
    printFunction("postRequest body", body);
    headers[APIKeyConstants.contentType] = APIKeyConstants.vApplicationJson;
    printFunction("postRequest headers", headers);
    final response = await http.post(Uri.parse(url), body: jsonEncode(body), headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => http.Response('Timeout', 408),
    );
    GetUtils.printFunction("postRequest url", response.request?.url.toString(), "");
    printFunction("postRequest status", response.statusCode);
    return handleResponse(response, isDynamic: isDynamic);
  }

  Future<ServerResponse> getRequest(String baseUrl, String path,  { Map<String, dynamic>? query, bool? isDynamic}) async {
    printFunction("getRequest query", query);
    Map<String, String> headers = APIRepository().authHeader();
    headers[APIKeyConstants.contentType] = APIKeyConstants.vApplicationJson;
    printFunction("getRequest headers", headers);
    final uri = Uri.https(baseUrl.split("/").last, path, query);
    final response = await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => http.Response('Timeout', 408),
    );
    GetUtils.printFunction("getRequest url", response.request?.url.toString(), "");
    printFunction("getRequest status", response.statusCode);
    return handleResponse(response, isDynamic: isDynamic);
  }

  Future<ServerResponse> handleResponse(http.Response response, {bool? isDynamic}) async {
    printFunction("handleResponse statusCode", response.statusCode);
    if (response.statusCode == 408) {
      return ServerResponse(success: false, message: "Request timeout. Please check your network.");
    }
    if (response.statusCode == 401) {
      logOutActions();
      return Future.error(response.reasonPhrase ?? response.statusCode);
    }

    if (response.statusCode != 200) {
      return ServerResponse(success: false, message: response.reasonPhrase ?? "Server error: ${response.statusCode}");
    } else {
      printFunction("handleResponse body", response.body);
      final body = json.decode(response.body);
      if (isDynamic != null && isDynamic) {
        return ServerResponse(success: true, message: "", data: body);
      }  else {
        return ServerResponse.fromJson(body);
      }
    }
  }
}

///dio: ^4.0.6
// Future<ServerResponse> getRequestWithFullUrl(String url, {Map<String, dynamic>? query}) async {
//   try {
//     var response = await dio.Dio().get(url, queryParameters: query);
//     printFunction("getRequestWithFullUrl statusCode", response.statusCode);
//     if (response.statusCode == 200) {
//       return ServerResponse(success: true, message: "", data: response.data);
//     } else {
//       return ServerResponse(success: false, message: "Sorry! Data not found".tr);
//     }
//   } on SocketException catch (_) {
//     return Future.error("Please verify your internet connection and try again".tr);
//   } on dio.DioError catch (e) {
//     if (dio.DioErrorType.receiveTimeout == e.type || dio.DioErrorType.connectTimeout == e.type) {
//       return Future.error("Please verify your internet connection and try again".tr);
//     } else if (dio.DioErrorType.other == e.type) {
//       if (e.message.contains('SocketException')) {
//         return Future.error("Please verify your internet connection and try again".tr);
//       } else if (e.message.contains('connection closed before full header')) {
//         return Future.error("");
//       }
//     }
//     return Future.error(e.message);
//   }
// }

/// PLEASE DO NOT DELETE ///
/*httpClient.addRequestModifier((request) {
      request.headers['apikey'] = '12345678';
      return request;
    });*/
/*httpClient.addAuthenticator((request) async {
      final response = await get("http://yourapi/token");
      final token = response.body['token'];
      request.headers['Authorization'] = "$token";
      request.headers['Accept'] = "application/json";
      return request;
    });*/
/*httpClient.addResponseModifier<CasesModel>((request, response) {
      CasesModel model = response.body;
      if (model.countries.contains('Brazil')) {
        model.countries.remove('Brazilll');
      }
    });*/