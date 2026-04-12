"""
FinIQ Health Score Engine — Production v2
Uses FinancialProfile as single source of truth.

Dimensions (6):
  Emergency Fund   25%  (0-20)
  Insurance        20%  (0-20)
  Debt Health      20%  (0-20)
  Tax Efficiency   15%  (0-20)
  Savings Rate     10%  (0-20)   ← NEW (replaces old diversification)
  Retirement       10%  (0-20)

Fixes from audit:
  - No more bare except: clauses
  - Missing EMI = no debt = 20/20 (not 0)
  - Savings rate dimension rewards high savers
  - Age-adjusted scoring for 18-25 year olds
  - Every dimension includes a reason string
  - Uses FinancialProfile for normalised data
"""

from models.financial_profile import FinancialProfile


def calculate_health_score(profile_data: dict) -> dict:
    """Calculate the comprehensive financial health score.

    Args:
        profile_data: Raw profile dict from MongoDB or request.

    Returns:
        Dict with total_score, grade, dimensions (with reasons), priority_actions.
    """
    p = FinancialProfile(profile_data)
    scores = {}
    reasons = {}

    # ═══════════════════════════════════════════════════════════
    # 1. Emergency Fund (weight 25%, max 20 pts)
    # ═══════════════════════════════════════════════════════════
    ef_months = p.emergency_fund_months
    if ef_months >= 6:
        scores['emergency_fund'] = 20
        reasons['emergency_fund'] = (
            f'{ef_months:.0f} months covered — excellent.'
            + (' Consider investing excess beyond 12 months.' if ef_months > 12 else ''))
    elif ef_months >= 3:
        scores['emergency_fund'] = 12
        reasons['emergency_fund'] = (
            f'{ef_months:.0f} months covered — decent. '
            f'Target 6 months of expenses ({FinancialProfile.format_inr(p.monthly_expenses * 6)}).')
    elif ef_months >= 1:
        scores['emergency_fund'] = 6
        reasons['emergency_fund'] = (
            f'Only {ef_months:.0f} months covered. '
            f'Build to 6 months ({FinancialProfile.format_inr(p.monthly_expenses * 6)}) urgently.')
    else:
        scores['emergency_fund'] = 0
        reasons['emergency_fund'] = (
            'No emergency fund. Start saving 6 months of expenses immediately.')

    # ═══════════════════════════════════════════════════════════
    # 2. Insurance (weight 20%, max 20 pts)
    # ═══════════════════════════════════════════════════════════
    if p.has_health_insurance and p.has_term_insurance:
        scores['insurance'] = 20
        reasons['insurance'] = 'Both health and term insurance in place — well protected.'
    elif p.has_health_insurance:
        scores['insurance'] = 10
        reasons['insurance'] = (
            'Health insurance ✓ but no term insurance. '
            'A ₹1Cr term plan costs ~₹800/mo at your age.')
    elif p.has_term_insurance:
        scores['insurance'] = 10
        reasons['insurance'] = (
            'Term insurance ✓ but no health insurance. '
            'Get a ₹5L health cover — hospitalisation without it is devastating.')
    else:
        scores['insurance'] = 0
        reasons['insurance'] = (
            'Zero insurance coverage — your highest financial risk. '
            'Get term + health insurance before any investment.')

    # ═══════════════════════════════════════════════════════════
    # 3. Debt Health (weight 20%, max 20 pts)
    #    FIXED: Missing EMI = no debt = perfect score
    #    FIXED: Uses monthly_emi / monthly_income (not total_loan / monthly)
    # ═══════════════════════════════════════════════════════════
    emi_pct = p.emi_pct_of_income
    if p.monthly_emi == 0 and p.total_loan == 0:
        scores['debt_health'] = 20
        reasons['debt_health'] = 'No debt obligations — perfect score.'
    elif p.monthly_income <= 0:
        scores['debt_health'] = 10
        reasons['debt_health'] = 'Income data missing — cannot assess debt ratio.'
    elif emi_pct < 20:
        scores['debt_health'] = 20
        reasons['debt_health'] = (
            f'EMI is {emi_pct:.0f}% of income — very healthy. Keep it under 30%.')
    elif emi_pct < 35:
        scores['debt_health'] = 14
        reasons['debt_health'] = (
            f'EMI is {emi_pct:.0f}% of income — manageable but watch it.')
    elif emi_pct < 50:
        scores['debt_health'] = 8
        reasons['debt_health'] = (
            f'EMI is {emi_pct:.0f}% of income — stretching. '
            f'Consider restructuring to bring under 35%.')
    else:
        scores['debt_health'] = 2
        reasons['debt_health'] = (
            f'EMI is {emi_pct:.0f}% of income — DANGER zone. '
            f'Prioritise debt reduction before new investments.')

    # ═══════════════════════════════════════════════════════════
    # 4. Tax Efficiency (weight 15%, max 20 pts)
    #    FIXED: Uses actual marginal rate from FinancialProfile
    #    FIXED: Below threshold = perfect, age grace for 18-25
    # ═══════════════════════════════════════════════════════════
    if p.annual_income < 300_000:
        scores['tax_efficiency'] = 20
        reasons['tax_efficiency'] = 'Income below taxable threshold — no tax action needed.'
    else:
        utilisation_80c = min(p.section_80c / 150_000, 1.0) if p.section_80c > 0 else 0
        utilisation_nps = min(p.nps_contribution / 50_000, 1.0) if p.nps_contribution > 0 else 0
        tax_util = utilisation_80c * 0.7 + utilisation_nps * 0.3  # weighted

        if tax_util >= 0.8:
            scores['tax_efficiency'] = 20
            reasons['tax_efficiency'] = (
                f'Strong tax planning — 80C at {FinancialProfile.format_inr(p.section_80c)}.')
        elif tax_util >= 0.5:
            scores['tax_efficiency'] = 14
            reasons['tax_efficiency'] = (
                f'Decent tax planning. You can save ₹{p.total_tax_saving:,}/yr more.')
        elif tax_util >= 0.2:
            scores['tax_efficiency'] = 8
            reasons['tax_efficiency'] = (
                f'Under-utilising tax deductions. '
                f'₹{p.total_tax_saving:,}/yr in potential savings available.')
        else:
            # Age grace: 18-25 get a floor of 5 (just starting career)
            base = 5 if p.age <= 25 else 2
            scores['tax_efficiency'] = base
            reasons['tax_efficiency'] = (
                f'Minimal tax planning. Start a ₹12,500/mo ELSS SIP to save '
                f'₹{p.tax_saving_80c:,}/yr in tax.')

    # ═══════════════════════════════════════════════════════════
    # 5. Savings Rate (weight 10%, max 20 pts) — NEW DIMENSION
    #    Rewards high savings rate (replaces old diversification)
    # ═══════════════════════════════════════════════════════════
    sr = p.savings_rate_pct
    if p.monthly_income <= 0:
        scores['savings_rate'] = 5
        reasons['savings_rate'] = 'Income data missing — cannot calculate savings rate.'
    elif sr >= 50:
        scores['savings_rate'] = 20
        reasons['savings_rate'] = (
            f'Outstanding {sr:.0f}% savings rate! '
            f'Surplus of {FinancialProfile.format_inr(p.monthly_surplus)}/mo to invest.')
    elif sr >= 30:
        scores['savings_rate'] = 15
        reasons['savings_rate'] = (
            f'Healthy {sr:.0f}% savings rate. '
            f'{FinancialProfile.format_inr(p.monthly_surplus)}/mo available for SIP.')
    elif sr >= 15:
        scores['savings_rate'] = 8
        reasons['savings_rate'] = (
            f'{sr:.0f}% savings rate — room to improve. Target 30%+ for wealth building.')
    elif sr > 0:
        scores['savings_rate'] = 4
        reasons['savings_rate'] = (
            f'Low {sr:.0f}% savings rate. Reduce discretionary spending to free up SIP capacity.')
    else:
        scores['savings_rate'] = 0
        reasons['savings_rate'] = 'Zero or negative surplus. Review expenses urgently.'

    # ═══════════════════════════════════════════════════════════
    # 6. Retirement (weight 10%, max 20 pts)
    #    FIXED: Age-adjusted — lower weight for 18-25
    # ═══════════════════════════════════════════════════════════
    has_nps = p.nps_contribution > 0
    has_80c = p.section_80c > 0  # Could include PPF/ELSS

    if has_nps and has_80c:
        scores['retirement'] = 20
        reasons['retirement'] = 'NPS + 80C investments in place — retirement on track.'
    elif has_nps or has_80c:
        scores['retirement'] = 10
        instrument = 'NPS' if has_nps else '80C investments'
        reasons['retirement'] = (
            f'{instrument} started. Add {"80C investments" if has_nps else "NPS"} '
            f'for extra ₹50K deduction.')
    else:
        base = 5 if p.age <= 25 else 0
        scores['retirement'] = base
        if p.age <= 25:
            reasons['retirement'] = (
                'No retirement investments yet — but you have time on your side. Start now for max compounding.')
        else:
            reasons['retirement'] = (
                'No dedicated retirement savings. Open NPS + start ELSS SIP immediately.')

    # ═══════════════════════════════════════════════════════════
    # TOTAL SCORE CALCULATION
    # ═══════════════════════════════════════════════════════════
    weights = {
        'emergency_fund': 0.25,
        'insurance':      0.20,
        'debt_health':    0.20,
        'tax_efficiency': 0.15,
        'savings_rate':   0.10,
        'retirement':     0.10,
    }

    total = sum(scores[k] * weights[k] * 5 for k in weights)
    total = round(min(100, max(0, total)))

    if total >= 80:   grade = 'A'
    elif total >= 60: grade = 'B'
    elif total >= 40: grade = 'C'
    elif total >= 20: grade = 'D'
    else:             grade = 'F'

    grade_labels = {
        'A': 'Excellent! Maintain your financial discipline.',
        'B': 'Good shape — a few tweaks will push you to A.',
        'C': 'Decent foundation. Focus on weak dimensions.',
        'D': 'Needs attention. Start with insurance & emergency fund.',
        'F': 'Critical — take action on the priority items below.',
    }

    # Build dimension list with reasons, sorted by urgency (lowest score first)
    dimensions = {}
    for k in scores:
        dimensions[k] = scores[k]

    priority_actions = sorted(
        [
            {
                'dimension': k.replace('_', ' ').title(),
                'score': scores[k],
                'max': 20,
                'weight': weights[k],
                'reason': reasons.get(k, ''),
            }
            for k in scores
        ],
        key=lambda x: x['score'],
    )

    return {
        'total_score': total,
        'grade': grade,
        'grade_label': grade_labels.get(grade, ''),
        'dimensions': dimensions,
        'reasons': reasons,
        'priority_actions': priority_actions,
    }
