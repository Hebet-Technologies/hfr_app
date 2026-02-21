import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:staffportal/data/app_exception.dart';
import 'package:staffportal/data/network/base_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkApiService extends BaseApiService{

  @override
  Future getGetApiResponse(String url) async{
    dynamic jsonResponse;
    try{
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      jsonResponse = returnResponse(response);
    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  @override
  Future getPostApiResponse(String url, data) async{
    dynamic jsonResponse;
    try{
    Response response = await http.post(
      Uri.parse(url),
      body: data
    ).timeout(const Duration(seconds: 10));

    jsonResponse = returnResponse(response);

    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  @override
  Future getGetApiResponseWithToken(String url) async{
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString("token")!;

    dynamic jsonResponse;
    try{
      final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          }
      ).timeout(const Duration(seconds: 10));
      jsonResponse = returnResponse(response);
    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  @override
  Future getGetApiResponseWithTokenById(String url, id) async{
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString("token")!;

    dynamic jsonResponse;
    try{
      final response = await http.get(
          Uri.parse('$url/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          }
      ).timeout(const Duration(seconds: 10));
      jsonResponse = returnResponse(response);
    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  @override
  Future getPostApiResponseWithToken(String url, data) async{
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString("token")!;

    dynamic jsonResponse;
    try{
      Response response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: data
      ).timeout(const Duration(seconds: 10));

      jsonResponse = returnResponse(response);

    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  @override
  Future getLogoutApiResponseWithToken(String url) async{
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString("token")!;

    dynamic jsonResponse;
    try{
      Response response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
      ).timeout(const Duration(seconds: 10));

      jsonResponse = returnResponse(response);

    }on SocketException{
      throw ExceptionHandling("No Internet Connection");
    }
    return jsonResponse;
  }

  dynamic returnResponse(http.Response response){

    switch(response.statusCode){
      case 200:
        dynamic jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      case 400:
        throw ExceptionHandling(response.body.toString());
      case 500:
        throw ExceptionHandling(response.body.toString());
      default:
        throw ExceptionHandling("Error while communicating with server with status code ${response.statusCode.toString()}");
    }
  }

}