import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/api_config.dart';

class ApiClient {
  late Dio _dio;
  String? _currentBaseUrl;
  
  ApiClient() {
    _initializeDio();
  }
  
  Future<void> _initializeDio() async {
    final basePath = await ApiConfig.getBasePath();
    _currentBaseUrl = basePath;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: basePath,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }
  
  // Reinitialize with new base URL
  Future<void> updateBaseUrl() async {
    await _initializeDio();
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? headers,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Options _mergeOptions(Options? base, Map<String, dynamic>? headers) {
    if (headers == null) return base ?? Options();
    final existing = base?.headers ?? {};
    return (base ?? Options()).copyWith(headers: {...existing, ...headers});
  }
  
  Future<void> _ensureInitialized() async {
    final currentBasePath = await ApiConfig.getBasePath();
    if (_currentBaseUrl != currentBasePath) {
      await _initializeDio();
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Server error';
        
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is String) {
          message = data;
        }
        
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized. Please login again.');
          case 403:
            return Exception('Access denied: $message');
          case 404:
            return Exception('Not found: $message');
          case 409:
            return Exception('Conflict: $message');
          case 422:
            return Exception('Validation error: $message');
          case 500:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('Error ($statusCode): $message');
        }
      
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return Exception('No internet connection. Please check your network.');
        }
        return Exception('Connection failed. Please try again.');
      
      default:
        return Exception('Something went wrong. Please try again.');
    }
  }
}
