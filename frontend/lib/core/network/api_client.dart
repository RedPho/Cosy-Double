import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  // Use localhost:8000 by default (change to 10.0.2.2:8000 for Android emulator if needed)
  final String baseUrl = 'http://localhost:8000';
  final String wsUrl = 'ws://localhost:8000';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _wrapRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on SocketException catch (_) {
      throw NetworkException("Cannot connect to server. Check your internet connection.");
    } on TimeoutException catch (_) {
      throw NetworkException("Connection timed out. Please try again.");
    } on http.ClientException catch (e) {
      throw NetworkException("Network connection error: ${e.message}");
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('Connection failed')) {
        throw NetworkException("Cannot connect to server. Check your internet connection.");
      }
      rethrow;
    }
  }

  Future<http.Response> get(String path) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      return await http.get(url, headers: await _headers());
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      return await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> put(String path, dynamic body) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      return await http.put(
        url,
        headers: await _headers(),
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> delete(String path) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      return await http.delete(
        url,
        headers: await _headers(),
      );
    });
  }

  // WebSocket URL helper
  Future<String> getWebSocketUrl(int roomId) async {
    final token = await _getToken();
    return '$wsUrl/rooms/$roomId/ws?token=$token';
  }
}
