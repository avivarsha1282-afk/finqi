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
      connectTimeout: const Duration(seconds: 60),
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
    } on DioException catch (_) {
      // Return demo model on error for hackathon reliability
      return HealthScoreModel.demo();
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
    } on DioException catch (_) {
      return FirePlanModel.demo();
    }
  }

  // ─── Tax Wizard ────────────────────────────────────────────
  Future<TaxReportModel> compareTax({
    required double annualIncome,
    Map<String, dynamic>? deductions,
  }) async {
    if (ApiConstants.demoMode) return TaxReportModel.demo();
    try {
      final res = await _dio.post('/tax/compare', data: {
        'annual_income': annualIncome,
        'deductions': deductions ?? {},
      });
      return TaxReportModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return TaxReportModel.demo();
    }
  }

  // ─── Chat (routes through Flask backend — rate limiting applied) ─────────
  Future<ChatMessage> sendMessage({
    required String message,
    required List<ChatMessage> history,
    required String language,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Build a compact conversation history (last 8 messages to stay within context limits)
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
      // Surface a friendlier error rather than a raw exception
      final status = e.response?.statusCode;
      final msg = status == 429
          ? 'Artha is busy — try again in a moment 🙏'
          : status == 401
          ? 'Session expired. Please sign in again.'
          : _friendlyError(e);
      throw ApiException(msg, statusCode: status);
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
