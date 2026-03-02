import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_models.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? _resolveBaseUrl();

  final String _baseUrl;

  static String _resolveBaseUrl() {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<LoginResponse> login(String phone, String password) async {
    final res = await http.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final json = _decodeJson(res);
    return LoginResponse.fromJson(json);
  }

  Future<DashboardData> getDashboard(String token) async {
    final res = await http.get(_uri('/api/dashboard'), headers: _auth(token));
    return DashboardData.fromJson(_decodeJson(res));
  }

  Future<List<HomeworkItemDto>> getHomeworks(String token) async {
    final res = await http.get(_uri('/api/homework', {'status': 'all'}), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => HomeworkItemDto.fromJson(e)).toList();
  }

  Future<List<GradeDto>> getGrades(String token) async {
    final res = await http.get(_uri('/api/grades'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => GradeDto.fromJson(e)).toList();
  }

  Future<List<NoteDto>> getNotes(String token) async {
    final res = await http.get(_uri('/api/notes'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => NoteDto.fromJson(e)).toList();
  }

  Future<NoteDto> createNote(String token, String title, String content) async {
    final res = await http.post(
      _uri('/api/notes'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    return NoteDto.fromJson(_decodeJson(res));
  }

  Future<NoteDto> updateNote(String token, int noteId, String title, String content) async {
    final res = await http.put(
      _uri('/api/notes/$noteId'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    return NoteDto.fromJson(_decodeJson(res));
  }

  Future<void> deleteNote(String token, int noteId) async {
    final res = await http.delete(_uri('/api/notes/$noteId'), headers: _auth(token));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
    }
  }

  Future<List<ScheduleItemDto>> getTimetable(String token) async {
    final res = await http.get(_uri('/api/timetable'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => ScheduleItemDto.fromJson(e)).toList();
  }

  Future<List<ChatThreadDto>> getChatThreads(String token) async {
    final res = await http.get(_uri('/api/chat/threads'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => ChatThreadDto.fromJson(e)).toList();
  }

  Future<List<ChatUserDto>> getChatUsers(String token) async {
    final res = await http.get(_uri('/api/chat/users'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => ChatUserDto.fromJson(e)).toList();
  }

  Future<ChatThreadDto> createDirectChat(String token, String phone) async {
    final res = await http.post(
      _uri('/api/chat/direct'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return ChatThreadDto.fromJson(_decodeJson(res));
  }

  Future<ChatThreadDto> createGroupChat(String token, String name, List<String> memberPhones) async {
    final res = await http.post(
      _uri('/api/chat/groups'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'memberPhones': memberPhones}),
    );
    return ChatThreadDto.fromJson(_decodeJson(res));
  }

  Future<ChatThreadDto> inviteToGroup(String token, int conversationId, String phone) async {
    final res = await http.post(
      _uri('/api/chat/groups/$conversationId/invite'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return ChatThreadDto.fromJson(_decodeJson(res));
  }

  Future<List<ChatMessageDto>> getChatMessages(String token, int threadId) async {
    final res = await http.get(_uri('/api/chat/threads/$threadId/messages'), headers: _auth(token));
    final list = _decodeList(res);
    return list.map((e) => ChatMessageDto.fromJson(e)).toList();
  }

  Future<ChatMessageDto> sendChatMessage(String token, int threadId, String text) async {
    final res = await http.post(
      _uri('/api/chat/threads/$threadId/messages'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    return ChatMessageDto.fromJson(_decodeJson(res));
  }

  Future<UserProfile> getProfile(String token) async {
    final res = await http.get(_uri('/api/me/profile'), headers: _auth(token));
    return UserProfile.fromJson(_decodeJson(res));
  }

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
    }
    return (jsonDecode(res.body) as Map).cast<String, dynamic>();
  }

  List<Map<String, dynamic>> _decodeList(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
    }
    final data = jsonDecode(res.body) as List;
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  String _errorMessage(http.Response res) {
    final mappedByStatus = <int, String>{
      400: 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại dữ liệu.',
      401: 'Bạn chưa đăng nhập hoặc phiên đăng nhập đã hết hạn.',
      403: 'Bạn không có quyền thực hiện thao tác này.',
      404: 'Không tìm thấy dữ liệu hoặc chức năng bạn yêu cầu.',
      409: 'Dữ liệu bị xung đột. Vui lòng tải lại và thử lại.',
      422: 'Dữ liệu nhập vào chưa đúng định dạng.',
      500: 'Máy chủ đang gặp lỗi. Vui lòng thử lại sau.',
      502: 'Không kết nối được đến máy chủ.',
      503: 'Dịch vụ tạm thời gián đoạn. Vui lòng thử lại sau.',
      504: 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
    };
    final baseMessage = mappedByStatus[res.statusCode] ?? 'Có lỗi xảy ra khi xử lý yêu cầu.';

    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] != null) {
        final serverMessage = data['message'].toString();
        if (serverMessage.trim().isNotEmpty) {
          return '$baseMessage Chi tiết: $serverMessage';
        }
      }
    } catch (_) {
      // ignore decode error
    }
    return baseMessage;
  }
}
