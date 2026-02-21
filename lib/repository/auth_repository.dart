import 'package:staffportal/data/network/network_api_service.dart';
import 'package:staffportal/utils/api_call.dart';

class AuthRepository{

  final NetworkApiService _apiService = NetworkApiService();

  Future<dynamic> loginApi(dynamic data) async{
    try{
      dynamic response = await _apiService.getPostApiResponse(ApiCall.loginApi, data);
      return response;
    }catch(e){
      rethrow;
    }

  }

  Future<dynamic> defaultDashboard() async{
    try{
      dynamic response = await _apiService.getGetApiResponseWithToken(ApiCall.defaultDashboard);
      return response;
    }catch(e){
      rethrow;
    }
  }

  Future<dynamic> selectedDashboard(int id) async{
    try{
      dynamic response = await _apiService.getGetApiResponseWithTokenById(ApiCall.selectedDashboard, id);
      return response;
    }catch(e){
      rethrow;
    }
  }

  Future<dynamic> getWorkStation() async{
    try{
      dynamic response = await _apiService.getGetApiResponseWithToken(ApiCall.getWorkStation);
      return response;
    }catch(e){
      rethrow;
    }
  }

}