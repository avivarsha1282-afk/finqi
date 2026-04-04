import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_prefs_service.dart';

/// Central user data service — reads/writes via UID-prefixed UserPrefsService.
/// Ensures complete data isolation between users.
class UserDataService {
  UserDataService._();

  /// Get the user's profile from UID-prefixed SharedPreferences.
  /// Falls back to onboarding_data JSON, then Firebase, then defaults.
  static Future<Map<String, dynamic>> getUserProfile() async {
    final firebaseName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'User';

    // First try individual keys (written by processing screen)
    final userName = await UserPrefsService.getString('user_name');
    if (userName != null) {
      return {
        'name': userName,
        'age': (await UserPrefsService.getInt('user_age')) ?? 25,
        'city': (await UserPrefsService.getString('user_city')) ?? 'India',
        'occupation':
            (await UserPrefsService.getString('user_occupation')) ?? 'Salaried',
        'monthly_income':
            (await UserPrefsService.getDouble('monthly_income')) ?? 0.0,
        'annual_income':
            (await UserPrefsService.getDouble('annual_income')) ?? 0.0,
        'monthly_expense':
            (await UserPrefsService.getDouble('monthly_expense')) ?? 0.0,
        'monthly_rent':
            (await UserPrefsService.getDouble('monthly_rent')) ?? 0.0,
        'current_savings':
            (await UserPrefsService.getDouble('current_savings')) ?? 0.0,
        'mutual_funds':
            (await UserPrefsService.getDouble('mutual_funds')) ?? 0.0,
        'ppf_balance':
            (await UserPrefsService.getDouble('ppf_balance')) ?? 0.0,
        'nps_balance':
            (await UserPrefsService.getDouble('nps_balance')) ?? 0.0,
        'deduction_80c':
            (await UserPrefsService.getDouble('deduction_80c')) ?? 0.0,
        'deduction_80d':
            (await UserPrefsService.getDouble('deduction_80d')) ?? 0.0,
        'annual_nps':
            (await UserPrefsService.getDouble('annual_nps')) ?? 0.0,
        'has_health_insurance':
            (await UserPrefsService.getBool('has_health_insurance')) ?? false,
        'has_term_insurance':
            (await UserPrefsService.getBool('has_term_insurance')) ?? false,
        'total_emi':
            (await UserPrefsService.getDouble('total_emi')) ?? 0.0,
        'home_loan_emi':
            (await UserPrefsService.getDouble('home_loan_emi')) ?? 0.0,
        'goal_type':
            (await UserPrefsService.getString('goal_type')) ?? 'Wealth',
        'goal_name':
            (await UserPrefsService.getString('goal_name')) ??
                'Financial Freedom',
        'goal_amount':
            (await UserPrefsService.getDouble('goal_amount')) ?? 1000000.0,
        'goal_years':
            (await UserPrefsService.getInt('goal_years')) ?? 5,
        'risk_appetite':
            (await UserPrefsService.getString('risk_appetite')) ?? 'Moderate',
      };
    }

    // Fallback: try onboarding_data JSON blob
    final raw = await UserPrefsService.getString('onboarding_data');
    if (raw != null) {
      try {
        final data = json.decode(raw) as Map<String, dynamic>;
        return {
          'name': data['name'] ?? firebaseName,
          'age': data['age'] ?? 25,
          'city': data['city'] ?? 'India',
          'occupation': data['occupation'] ?? 'Salaried',
          'monthly_income': (data['monthly_income'] ?? 0).toDouble(),
          'annual_income': (data['annual_income'] ?? 0).toDouble(),
          'monthly_expense': (data['monthly_expense'] ?? 0).toDouble(),
          'monthly_rent': (data['monthly_rent'] ?? 0).toDouble(),
          'current_savings': (data['current_savings'] ?? 0).toDouble(),
          'mutual_funds': (data['mutual_funds'] ?? 0).toDouble(),
          'ppf_balance': (data['ppf'] ?? 0).toDouble(),
          'nps_balance': (data['nps'] ?? 0).toDouble(),
          'deduction_80c': (data['annual_80c'] ?? 0).toDouble(),
          'deduction_80d': (data['annual_80d'] ?? 0).toDouble(),
          'annual_nps': (data['annual_nps'] ?? 0).toDouble(),
          'has_health_insurance': data['has_health_insurance'] ?? false,
          'has_term_insurance': data['has_term_insurance'] ?? false,
          'total_emi': (data['total_emi'] ?? 0).toDouble(),
          'home_loan_emi': (data['home_loan_emi'] ?? 0).toDouble(),
          'goal_type': data['goal_type'] ?? 'Wealth',
          'goal_name': data['goal_name'] ?? 'Financial Freedom',
          'goal_amount': (data['goal_amount'] ?? 1000000).toDouble(),
          'goal_years': data['goal_years'] ?? 5,
          'risk_appetite': data['risk_appetite'] ?? 'Moderate',
        };
      } catch (_) {}
    }

    // Last fallback: Firebase name + defaults
    return {
      'name': firebaseName,
      'age': 25,
      'city': 'India',
      'occupation': 'Salaried',
      'monthly_income': 0.0,
      'annual_income': 0.0,
      'monthly_expense': 0.0,
      'monthly_rent': 0.0,
      'current_savings': 0.0,
      'mutual_funds': 0.0,
      'ppf_balance': 0.0,
      'nps_balance': 0.0,
      'deduction_80c': 0.0,
      'deduction_80d': 0.0,
      'annual_nps': 0.0,
      'has_health_insurance': false,
      'has_term_insurance': false,
      'total_emi': 0.0,
      'home_loan_emi': 0.0,
      'goal_type': 'Wealth',
      'goal_name': 'Financial Freedom',
      'goal_amount': 1000000.0,
      'goal_years': 5,
      'risk_appetite': 'Moderate',
    };
  }

  /// Get just the first name for greeting
  static Future<String> getFirstName() async {
    final profile = await getUserProfile();
    final name = profile['name'] as String;
    return name.split(' ').first;
  }

  /// Save all onboarding data as individual UID-prefixed SharedPreferences keys.
  /// Handles both old-format keys (from Firestore sync) and new-format keys
  /// (from corrected onboarding provider).
  static Future<void> persistOnboardingData(
      Map<String, dynamic> data) async {
    // Personal
    await UserPrefsService.setString('user_name', data['name'] ?? 'User');
    await UserPrefsService.setInt('user_age', data['age'] ?? 25);
    await UserPrefsService.setString('user_city', data['city'] ?? 'India');
    await UserPrefsService.setString(
        'user_occupation', data['occupation'] ?? 'Salaried');

    // Income — accept both `monthly_salary` (new) and `monthly_income` (old)
    final monthlyIncome = (data['monthly_salary'] ?? data['monthly_income'] ?? 0).toDouble();
    await UserPrefsService.setDouble('monthly_income', monthlyIncome);
    await UserPrefsService.setDouble('annual_income', monthlyIncome * 12);
    await UserPrefsService.setDouble(
        'monthly_expense', (data['monthly_expense'] ?? data['monthly_expenses'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'monthly_rent', (data['monthly_rent'] ?? data['house_rent'] ?? 0).toDouble());

    // Savings & Investments
    await UserPrefsService.setDouble(
        'current_savings', (data['current_savings'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'mutual_funds', (data['mutual_funds'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'ppf_balance', (data['ppf'] ?? data['ppf_balance'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'nps_balance', (data['nps'] ?? data['nps_balance'] ?? data['nps_contribution'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'deduction_80c', (data['section_80c'] ?? data['annual_80c'] ?? data['deduction_80c'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'deduction_80d', (data['premium_80d'] ?? data['annual_80d'] ?? data['deduction_80d'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'annual_nps', (data['nps_contribution'] ?? data['annual_nps'] ?? 0).toDouble());

    // Insurance & Debt — accept both bool and string "Yes"/"No"
    final healthIns = data['has_health_insurance'] ?? data['health_insurance'] ?? false;
    final termIns = data['has_term_insurance'] ?? data['life_insurance'] ?? false;
    await UserPrefsService.setBool(
        'has_health_insurance', _toBool(healthIns));
    await UserPrefsService.setBool(
        'has_term_insurance', _toBool(termIns));
    await UserPrefsService.setDouble(
        'home_loan_emi', (data['home_loan_emi'] ?? 0).toDouble());
    await UserPrefsService.setDouble(
        'total_emi', (data['total_emi'] ?? data['emis'] ?? 0).toDouble());

    // Goals
    await UserPrefsService.setString(
        'goal_type', data['goal_type'] ?? 'Wealth');
    await UserPrefsService.setString(
        'goal_name', data['financial_goal'] ?? data['goal_name'] ?? 'Financial Freedom');
    await UserPrefsService.setDouble(
        'goal_amount', (data['financial_goal_amount'] ?? data['goal_amount'] ?? 1000000).toDouble());
    await UserPrefsService.setInt('goal_years', data['target_timeline'] ?? data['goal_years'] ?? 5);
    await UserPrefsService.setString(
        'risk_appetite', data['risk_appetite'] ?? 'Moderate');

    // Also store the raw JSON blob for backward compat
    await UserPrefsService.setString(
        'onboarding_data', json.encode(data));
  }

  /// Convert various truthy values to bool
  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase().trim() == 'yes' || value.toLowerCase().trim() == 'true';
    if (value is num) return value > 0;
    return false;
  }

  /// Run local financial analysis and save to UID-prefixed SharedPreferences
  static Future<void> calculateAndSaveLocally(
      Map<String, dynamic> profile) async {
    final income = (profile['monthly_salary'] ?? profile['monthly_income'] ?? 0).toDouble();
    final expense = (profile['monthly_expense'] ?? profile['monthly_expenses'] ?? 0).toDouble();
    final savings = (profile['current_savings'] ?? 0).toDouble();
    final emi = (profile['total_emi'] ?? profile['emis'] ?? 0).toDouble();
    final has80c = (profile['section_80c'] ?? profile['annual_80c'] ?? profile['deduction_80c'] ?? 0).toDouble();
    final has80d = (profile['premium_80d'] ?? profile['annual_80d'] ?? profile['deduction_80d'] ?? 0).toDouble();
    final hasHealth = _toBool(profile['has_health_insurance'] ?? profile['health_insurance'] ?? false);
    final hasTerm = _toBool(profile['has_term_insurance'] ?? profile['life_insurance'] ?? false);

    // Emergency Fund dimension (0-20)
    int emergencyScore = 0;
    final emergencyTarget = expense * 6;
    if (emergencyTarget > 0) {
      if (savings >= emergencyTarget) {
        emergencyScore = 20;
      } else if (savings >= emergencyTarget * 0.5) {
        emergencyScore = 12;
      } else if (savings >= emergencyTarget * 0.25) {
        emergencyScore = 6;
      } else if (savings > 0) {
        emergencyScore = 3;
      }
    }

    // Insurance dimension (0-20)
    int insuranceScore = 0;
    if (hasHealth == true && hasTerm == true) {
      insuranceScore = 20;
    } else if (hasHealth == true || hasTerm == true) {
      insuranceScore = 8;
    }

    // Investment Mix dimension (0-20)
    int investmentScore = 8; // baseline
    final mf = (profile['mutual_funds'] ?? 0).toDouble();
    final ppf = (profile['ppf'] ?? profile['ppf_balance'] ?? 0).toDouble();
    final nps = (profile['nps'] ?? profile['nps_contribution'] ?? profile['nps_balance'] ?? 0).toDouble();
    int assetCount = 0;
    if (mf > 0) assetCount++;
    if (ppf > 0) assetCount++;
    if (nps > 0) assetCount++;
    if (savings > 0) assetCount++;
    if (assetCount >= 3) {
      investmentScore = 18;
    } else if (assetCount >= 2) {
      investmentScore = 12;
    }

    // Debt Health dimension (0-20)
    int debtScore = 20;
    if (income > 0) {
      final debtRatio = emi / income;
      if (debtRatio > 0.5) {
        debtScore = 5;
      } else if (debtRatio > 0.3) {
        debtScore = 12;
      }
    }

    // Tax Efficiency dimension (0-10)
    int taxScore = 0;
    if (has80c >= 150000) {
      taxScore = 10;
    } else if (has80c >= 75000) {
      taxScore = 5;
    } else if (has80c > 0) {
      taxScore = 2;
    }

    // FIRE Progress dimension (0-10)
    int fireScore = 2;
    final goalAmount = (profile['financial_goal_amount'] ?? profile['goal_amount'] ?? 1000000).toDouble();
    if (goalAmount > 0 && savings > 0) {
      final progress = savings / goalAmount;
      if (progress >= 0.5) {
        fireScore = 8;
      } else if (progress >= 0.2) {
        fireScore = 5;
      } else if (progress >= 0.05) {
        fireScore = 3;
      }
    }

    final totalScore = (emergencyScore +
            insuranceScore +
            investmentScore +
            debtScore +
            taxScore +
            fireScore)
        .clamp(0, 100);

    String grade = 'F';
    if (totalScore >= 80) {
      grade = 'A';
    } else if (totalScore >= 65) {
      grade = 'B';
    } else if (totalScore >= 50) {
      grade = 'C';
    } else if (totalScore >= 35) {
      grade = 'D';
    }

    // SIP calculation
    final goalYears = profile['target_timeline'] ?? profile['goal_years'] ?? 5;
    final r = 0.01; // 12% pa monthly
    final n = (goalYears as int) * 12;
    double sip = 0;
    if (n > 0) {
      final fvSavings = savings * _pow(1 + r, n);
      final remaining = goalAmount - fvSavings;
      if (remaining > 0) {
        sip = remaining * r / (_pow(1 + r, n) - 1);
      }
    }

    // Emergency fund gap
    final emergencyGap =
        (expense * 6 - savings).clamp(0.0, double.infinity);

    // Tax saving opportunity — use ACTUAL user deductions
    final missed80c = (150000 - has80c).clamp(0.0, 150000.0);
    final missed80d = (25000 - has80d).clamp(0.0, 25000.0);
    final annualNps = (profile['nps_contribution'] ?? profile['annual_nps'] ?? 0).toDouble();
    final missedNps = (50000 - annualNps).clamp(0.0, 50000.0);
    final annualIncome = income * 12;
    final marginalRate = annualIncome > 1000000
        ? 0.312
        : annualIncome > 500000
            ? 0.208
            : 0.05;
    final taxSaving =
        (missed80c + missed80d + missedNps) * marginalRate;

    // Generate brief
    final name = (profile['name'] ?? 'User').toString().split(' ').first;
    String brief;
    if (insuranceScore == 0) {
      brief =
          '$name, your score of $totalScore reflects critical gaps. Zero insurance '
          'coverage is your biggest risk. A term plan + health cover could push '
          'your score to ${(totalScore + 20).clamp(0, 100)}+ quickly.';
    } else if (taxScore < 5) {
      brief =
          '$name, you\'re missing out on ₹${taxSaving.toInt()} in tax savings. '
          'Starting a ₹12,500/mo ELSS SIP today could recover significant tax '
          'this financial year.';
    } else {
      brief =
          '$name, your score of $totalScore shows a solid foundation. Focus on '
          'growing your investment mix and maximizing retirement contributions '
          'to reach Grade A status.';
    }

    // Priority actions
    String action1, action2, action3;
    if (insuranceScore == 0) {
      action1 = 'Get term insurance — ₹1Cr cover costs ~₹800/mo';
      action2 = 'Get health insurance — ₹5L cover at your age';
      action3 =
          'Start ELSS SIP ₹12,500/mo for ₹${(missed80c * marginalRate).toInt()} tax saving';
    } else if (taxScore < 5) {
      action1 =
          'Start ELSS SIP ₹12,500/mo for ₹${(missed80c * marginalRate).toInt()} tax saving';
      action2 = 'Open NPS account for extra ₹50K deduction';
      action3 =
          'Build emergency fund to ₹${(expense * 6).toInt()} (${income > 0 ? (expense * 6 / income).toStringAsFixed(0) : "6"} months)';
    } else {
      action1 =
          'Increase SIP to ₹${sip.toInt()}/mo for your ${profile['goal_name']} goal';
      action2 = 'Diversify into international index funds';
      action3 = 'Review and rebalance portfolio quarterly';
    }

    // Save everything via UserPrefsService (UID-prefixed!)
    await UserPrefsService.setInt('health_score', totalScore);
    await UserPrefsService.setString('grade', grade);
    await UserPrefsService.setString('artha_brief', brief);
    await UserPrefsService.setDouble(
        'emergency_fund_gap', emergencyGap.toDouble());
    await UserPrefsService.setDouble('net_worth', savings);
    await UserPrefsService.setDouble('monthly_sip_needed', sip.abs());
    await UserPrefsService.setDouble(
        'tax_saving_opportunity', taxSaving);
    await UserPrefsService.setString('priority_action_1', action1);
    await UserPrefsService.setString('priority_action_2', action2);
    await UserPrefsService.setString('priority_action_3', action3);
    await UserPrefsService.setInt('dim_emergency', emergencyScore);
    await UserPrefsService.setInt('dim_insurance', insuranceScore);
    await UserPrefsService.setInt('dim_investment', investmentScore);
    await UserPrefsService.setInt('dim_debt', debtScore);
    await UserPrefsService.setInt('dim_tax', taxScore);
    await UserPrefsService.setInt('dim_fire', fireScore);
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  /// One-time migration to fix corrupted financial data from the
  /// CurrencyInputFormatter double-formatting bug.
  /// Returns true if corruption was detected and fixed (so UI can show banner).
  static Future<bool> migrateCorruptedData() async {
    final migrated = await UserPrefsService.getBool('data_migrated_v1');
    if (migrated == true) return false;

    bool foundCorruption = false;

    // Sanity caps — raised to accommodate HNIs/business owners
    const incomeMax = 500000000.0;   // ₹5 Crore/month
    const savingsMax = 500000000.0;  // ₹50 Crore
    const goalMax = 1000000000.0;    // ₹100 Crore

    final fieldsToCheck = {
      'monthly_income': incomeMax,
      'monthly_expense': incomeMax,
      'current_savings': savingsMax,
      'goal_amount': goalMax,
      'annual_income': incomeMax * 12,
    };

    for (final entry in fieldsToCheck.entries) {
      final raw = await UserPrefsService.getDouble(entry.key);
      if (raw != null && raw > entry.value) {
        await UserPrefsService.setDouble(entry.key, 0.0);
        foundCorruption = true;
      }
    }

    await UserPrefsService.setBool('data_migrated_v1', true);
    return foundCorruption;
  }
}
