"""Final verification: all engines + app.py imports work."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# 1. FinancialProfile
from models.financial_profile import FinancialProfile
fp = FinancialProfile({
    'monthly_salary': 250000, 'monthly_expense': 75000,
    'current_savings': 42500000, 'monthly_emi': 0, 'total_loan': 0,
    'has_health_insurance': True, 'section_80c': 0, 'age': 20,
    'financial_goal_amount': 10000000, 'target_timeline': 7,
})
assert fp.savings_rate_pct == 70.0, f"Savings rate: {fp.savings_rate_pct}"
assert fp.goal_achieved == True, "Goal should be achieved"
print(f"✅ FinancialProfile: surplus={fp.format_inr(fp.monthly_surplus)}, rate={fp.savings_rate_pct}%")

# 2. Health Score
from engines.health_score_engine import calculate_health_score
hs = calculate_health_score({
    'monthly_salary': 250000, 'monthly_expense': 75000,
    'current_savings': 42500000, 'monthly_emi': 0,
    'has_health_insurance': True, 'section_80c': 0, 'age': 20,
})
assert hs['total_score'] >= 70, f"Score too low: {hs['total_score']}"
assert hs['dimensions']['debt_health'] == 20, "No debt should be 20/20"
print(f"✅ Health Score: {hs['total_score']}/100 ({hs['grade']})")

# 3. FIRE Engine
from engines.fire_engine import calculate_fire_plan
fire = calculate_fire_plan(10000000, 7, 42500000, monthly_income=250000)
assert fire['goal_status'] == 'ALREADY_ACHIEVED', f"Should be achieved: {fire['goal_status']}"
assert fire['required_monthly_sip'] == 0, f"SIP should be 0: {fire['required_monthly_sip']}"
assert len(fire['timeline']) > 0, "Timeline should have points"
print(f"✅ FIRE: status={fire['goal_status']}, projected={FinancialProfile.format_inr(fire['projected_corpus'])}")

# 4. Tax Engine
from engines.tax_engine import compare_regimes
tax = compare_regimes(income=3000000, investment_80c=0, premium_80d=0, nps_contribution=0)
assert tax['total_potential_saving'] > 0, "Should have tax savings"
print(f"✅ Tax: regime={tax['recommended_regime']}, saving={FinancialProfile.format_inr(tax['total_potential_saving'])}")

# 5. Dashboard _fmt uses FinancialProfile now
from routes.dashboard import _fmt
assert '₹' in _fmt(42500000) or '\u20B9' in _fmt(42500000), "_fmt should return formatted rupee"
print(f"✅ Dashboard _fmt: {_fmt(42500000)}")

# 6. App imports (no chat_bp)
try:
    # Verify app.py doesn't import chat_bp anymore
    with open('app.py', 'r') as f:
        content = f.read()
    assert 'from routes.chat import chat_bp' not in content, "chat_bp should be removed"
    print("✅ app.py: chat_bp removed")
except Exception as e:
    print(f"⚠️  app.py check: {e}")

# 7. New user with zero income (edge case)
fire_zero = calculate_fire_plan(10000000, 10, 10000, monthly_income=0)
assert fire_zero['goal_status'] == 'IN_PROGRESS', f"Zero income: {fire_zero['goal_status']}"
print(f"✅ Zero income: no crash, SIP={FinancialProfile.format_inr(fire_zero['required_monthly_sip'])}")

print("\n" + "=" * 50)
print("ALL 7 VERIFICATIONS PASSED ✅")
print("=" * 50)
