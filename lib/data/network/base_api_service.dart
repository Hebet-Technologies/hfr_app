abstract class BaseApiService{

  Future<dynamic> getGetApiResponse(String url);

  Future<dynamic> getPostApiResponse(String url, dynamic data);

  Future<dynamic> getGetApiResponseWithToken(String url);

  Future<dynamic> getGetApiResponseWithTokenById(String url, dynamic id);

  Future<dynamic> getPostApiResponseWithToken(String url, dynamic data);

  Future<dynamic> getLogoutApiResponseWithToken(String url);
}