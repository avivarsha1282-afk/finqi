import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../models/health_score_model.dart';
import '../models/fire_plan_model.dart';
import '../models/tax_report_model.dart';
import '../models/chat_message_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConstants.baseUrl}/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await FirebaseAuth.instance.signOut();
        }
        return handler.next(e);
      },
    ));
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Check your network.';
    }
    final msg = e.response?.data?['message'] ?? e.response?.data?['error'];
    if (msg != null) return msg.toString();
    return 'Something went wrong. Please try again.';
  }

  // ─── Auth ────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyAuth() async {
    try {
      final res = await _dio.post('/auth/verify');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  // ─── Onboarding ───────────────────────────────────────────
  Future<Map<String, dynamic>> saveOnboarding(Map<String, dynamic> answers) async {
    try {
      final res = await _dio.post('/onboarding/save', data: answers);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  // ─── Health Score ──────────────────────────────────────────
  Future<HealthScoreModel> calculateScore() async {
    if (ApiConstants.demoMode) return HealthScoreModel.demo();
    try {
      final res = await _dio.post('/score/calculate');
      return HealthScoreModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // R9: NEVER silently return fake data — throw so UI shows error + retry
      throw ApiException(
        _friendlyError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── FIRE Plan ─────────────────────────────────────────────
  Future<FirePlanModel> getFirePlan({
    required double targetAmount,
    required int targetYears,
    required double currentSavings,
  }) async {
    if (ApiConstants.demoMode) return FirePlanModel.demo();
    try {
      final res = await _dio.post('/fire/plan', data: {
        'target_amount': targetAmount,
        'target_years': targetYears,
        'current_savings': currentSavings,
      });
      return FirePlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _friendlyError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Tax Wizard ────────────────────────────────────────────
  Future<TaxReportModel> compareTax({
    required double annualIncome,
    double? investment80c,
    double? premium80d,
    double? npsContribution,
    double? hra,
    double? homeLoanInterest,
  }) async {
    if (ApiConstants.demoMode) return TaxReportModel.demo();
    try {
      final body = <String, dynamic>{
        'annual_income': annualIncome,
      };
      if (investment80c != null) body['investment_80c'] = investment80c;
      if (premium80d != null) body['premium_80d'] = premium80d;
      if (npsContribution != null) body['nps_contribution'] = npsContribution;
      if (hra != null) body['hra'] = hra;
      if (homeLoanInterest != null) body['home_loan_interest'] = homeLoanInterest;

      final res = await _dio.post('/tax/compare', data: body);
      return TaxReportModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _friendlyError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Artha Conversations (CRUD) ────────────────────────────
  Future<Map<String, dynamic>> createConversation() async {
    try {
      final res = await _dio.post('/artha/conversations');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> getConversations({int limit = 20}) async {
    try {
      final res = await _dio.get('/artha/conversations', queryParameters: {'limit': limit});
      final data = res.data['conversations'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final res = await _dio.get('/artha/conversations/$conversationId/messages');
      final msgs = res.data['messages'] as List<dynamic>? ?? [];
      return msgs.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ChatMessage> sendArthaMessage({
    required String conversationId,
    required String message,
    required String language,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final res = await _dio.post('/artha/conversations/$conversationId/messages', data: {
        'message': message,
        'language': language,
        'userProfile': userContext ?? {},
      });
      final content = res.data['response'] ?? 'No response';
      return ChatMessage.artha(content.toString());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = status == 429
          ? 'Artha is busy — try again in a moment 🙏'
          : status == 401
          ? 'Session expired. Please sign in again.'
          : _friendlyError(e);
      throw ApiException(msg, statusCode: status);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete('/artha/conversations/$conversationId');
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }


  // ─── Dashboard ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _dio.get('/user/dashboard');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e));
    }
  }

  // ─── Old Chat Integration (Deprecated) ─────────────────────
  Future<ChatMessage> sendMessage({
    required String message,
    required List<ChatMessage> history,
    required String language,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final recentHistory = history.where((m) => !m.isLoading && m.content.isNotEmpty).toList();
      final trimmed = recentHistory.length > 8
          ? recentHistory.sublist(recentHistory.length - 8)
          : recentHistory;

      final res = await _dio.post('/chat/message', data: {
        'message': message,
        'language': language,
        'user_context': userContext ?? {},
        'conversation_history': trimmed.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }).toList(),
      });

      final content = res.data['content'] ?? res.data['reply'] ?? 'No response';
      return ChatMessage.artha(content.toString());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = status == 429
          ? 'Artha is busy — try again in a moment 🙏'
          : status == 401
          ? 'Session expired. Please sign in again.'
          : _friendlyError(e);
      throw ApiException(msg, statusCode: status);
    }
  }

  // ─── Generic PUT helper ────────────────────────────────────
  Future<Map<String, dynamic>> putData(String path, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }
  
  // ─── Profile Integration ────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/user/profile', data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  // ─── Generic POST helper ────────────────────────────────────
  Future<Map<String, dynamic>> postData(String path, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }

  // ─── Generic GET helper ─────────────────────────────────────
  Future<Map<String, dynamic>> getData(String path) async {
    try {
      final res = await _dio.get(path);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(_friendlyError(e), statusCode: e.response?.statusCode);
    }
  }
}
