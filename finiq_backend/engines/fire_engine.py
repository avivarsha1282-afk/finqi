"""
FinIQ FIRE Engine — Production v2
Uses FinancialProfile as single source of truth.

Fixes:
  - Goal already achieved detection (savings >= target)
  - No SIP needed detection (compound growth alone reaches target)
  - SIP label based on surplus ratio (not absolute amount)
  - Graph starts from current savings (not zero)
  - Year labels use actual calendar years
"""

import math
from datetime import datetime
from models.financial_profile import FinancialProfile


def _compound_growth(principal: float, monthly_sip: float,
                     years: int, annual_rate: float) -> float:
    """Calculate future value with monthly compounding + SIP."""
    if years <= 0:
        return principal
    monthly_rate = annual_rate / 12
    months = years * 12
    fv_principal = principal * ((1 + monthly_rate) ** months)
    if monthly_rate > 0 and monthly_sip > 0:
        fv_sip = monthly_sip * (((1 + monthly_rate) ** months) - 1) / monthly_rate
    else:
        fv_sip = monthly_sip * months
    return fv_principal + fv_sip


def calculate_sip_for_years(target_amount, years, current_savings, annual_return):
    """Calculate required monthly SIP for a given target, years, and return rate."""
    if years <= 0 or target_amount <= 0:
        return 0

    monthly_rate = annual_return / 12
    months = years * 12

    fv_savings = current_savings * ((1 + monthly_rate) ** months) if current_savings > 0 else 0
    remaining = max(0, target_amount - fv_savings)

    if remaining <= 0:
        return 0

    if monthly_rate > 0:
        required_sip = remaining * monthly_rate / (
            ((1 + monthly_rate) ** months) - 1
        )
    else:
        required_sip = remaining / max(months, 1)

    return round(required_sip)


def calculate_fire_plan(target_amount, years, current_savings,
                        annual_return=0.12, monthly_income=0):
    """Calculate FIRE plan with robust edge-case handling.

    Never crashes — always returns a valid response even with
    zero savings, zero income, or extreme targets.
    """
    # ── Validation ────────────────────────────────────────
    if target_amount is None or target_amount <= 0:
        target_amount = 10_000_000  # Default ₹1Cr
    if years is None or years <= 0:
        years = 7
    if current_savings is None or current_savings < 0:
        current_savings = 0
    if monthly_income is None or monthly_income < 0:
        monthly_income = 1  # Prevent division by zero

    monthly_rate = annual_return / 12
    months = years * 12
    current_year = datetime.now().year

    # ── CHECK 1: Goal already exceeded by current savings ──
    if current_savings >= target_amount:
        projected = _compound_growth(current_savings, 0, years, annual_return)
        return {
            'required_monthly_sip': 0,
            'target_amount': target_amount,
            'target_years': years,
            'current_savings': current_savings,
            'annual_return': round(annual_return * 100, 1),
            'achievability': 'ALREADY_ACHIEVED',
            'goal_status': 'ALREADY_ACHIEVED',
            'sip_label': 'ALREADY_ACHIEVED',
            'goal_status_message': (
                f'You have already exceeded your '
                f'{FinancialProfile.format_inr(target_amount)} goal! '
                f'Your current savings of '
                f'{FinancialProfile.format_inr(current_savings)} '
                f'already surpasses it. Consider setting a higher target.'),
            'recommendation': (
                'Your current savings already cover this goal! '
                'Consider a more ambitious target or invest the surplus.'),
            'projected_corpus': round(projected),
            'timeline': _generate_timeline(current_savings, 0, years, annual_return, current_year),
            'scenarios': [],
            'asset_allocation': _default_allocation(),
        }

    # ── CHECK 2: Current savings reach the goal with ₹0 SIP ──
    projected_no_sip = _compound_growth(current_savings, 0, years, annual_return)
    if projected_no_sip >= target_amount:
        return {
            'required_monthly_sip': 0,
            'target_amount': target_amount,
            'target_years': years,
            'current_savings': current_savings,
            'annual_return': round(annual_return * 100, 1),
            'achievability': 'NO_SIP_NEEDED',
            'goal_status': 'NO_SIP_NEEDED',
            'sip_label': 'ALREADY_ACHIEVABLE',
            'goal_status_message': (
                f'Your existing savings will grow to '
                f'{FinancialProfile.format_inr(round(projected_no_sip))} '
                f'in {years} years at {annual_return*100:.0f}% returns '
                f'without any additional investment.'),
            'recommendation': (
                'No SIP needed — compound growth does the work. '
                'Consider investing your surplus to build beyond the goal.'),
            'projected_corpus': round(projected_no_sip),
            'timeline': _generate_timeline(current_savings, 0, years, annual_return, current_year),
            'scenarios': [],
            'asset_allocation': _default_allocation(),
        }

    # ── Normal SIP calculation ────────────────────────────
    fv_savings = current_savings * ((1 + monthly_rate) ** months) if current_savings > 0 else 0
    remaining = max(0, target_amount - fv_savings)

    if monthly_rate > 0 and months > 0:
        required_sip = remaining * monthly_rate / (
            ((1 + monthly_rate) ** months) - 1
        )
    elif months > 0:
        required_sip = remaining / months
    else:
        required_sip = remaining

    # ── SIP Label based on SURPLUS ratio (not absolute amount) ──
    monthly_surplus = max(1, monthly_income * 0.5)  # Assume 50% as baseline if no expense data
    sip_ratio = required_sip / monthly_surplus if monthly_surplus > 0 else 999

    if sip_ratio < 0.25:
        sip_label = 'COMFORTABLE'
    elif sip_ratio < 0.50:
        sip_label = 'MANAGEABLE'
    elif sip_ratio < 0.75:
        sip_label = 'STRETCH'
    else:
        sip_label = 'DIFFICULT'

    # ── Achievability ─────────────────────────────────────
    sip_to_income = required_sip / monthly_income if monthly_income > 0 else 999
    if sip_to_income > 0.7:
        achievability = 'STRETCH'
        recommendation = (f'Needs {sip_to_income*100:.0f}% of income. '
                         f'Consider extending to {years+3} years instead.')
    elif sip_to_income > 0.4:
        achievability = 'CHALLENGING'
        recommendation = 'Ambitious but achievable with discipline.'
    else:
        achievability = 'ACHIEVABLE'
        recommendation = 'Comfortably achievable on your income!'

    # ── Generate timeline ─────────────────────────────────
    timeline = _generate_timeline(current_savings, required_sip, years, annual_return, current_year)

    # ── Scenarios (3 options) ─────────────────────────────
    aggressive_years = max(3, years - 4)
    conservative_years = years + 3

    scenarios = [
        {
            'label': f'{aggressive_years} Years — Aggressive',
            'years': aggressive_years,
            'risk': 'HIGH RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, aggressive_years, current_savings, 0.14),
        },
        {
            'label': f'{years} Years — Sustainable',
            'years': years,
            'risk': 'RECOMMENDED',
            'required_sip': round(required_sip),
        },
        {
            'label': f'{conservative_years} Years — Conservative',
            'years': conservative_years,
            'risk': 'LOW RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, conservative_years, current_savings, 0.10),
        },
    ]

    return {
        'required_monthly_sip': round(required_sip),
        'target_amount': target_amount,
        'target_years': years,
        'current_savings': current_savings,
        'annual_return': round(annual_return * 100, 1),
        'achievability': achievability,
        'goal_status': 'IN_PROGRESS',
        'sip_label': sip_label,
        'goal_status_message': '',
        'recommendation': recommendation,
        'projected_corpus': round(_compound_growth(current_savings, required_sip, years, annual_return)),
        'timeline': timeline,
        'scenarios': scenarios,
        'asset_allocation': _default_allocation(),
    }


def _generate_timeline(current_savings, monthly_sip, years, annual_return, start_year):
    """Generate year-by-year projection data points."""
    monthly_rate = annual_return / 12
    months = years * 12
    corpus = current_savings
    timeline = []

    # Year 0 starting point
    timeline.append({
        'year': 0,
        'calendar_year': start_year,
        'corpus': round(corpus),
    })

    for month in range(1, months + 1):
        corpus = corpus * (1 + monthly_rate) + monthly_sip
        if month % 12 == 0:
            timeline.append({
                'year': month // 12,
                'calendar_year': start_year + (month // 12),
                'corpus': round(corpus),
            })

    return timeline


def _default_allocation():
    return [
        {'type': 'Equity', 'percentage': 40, 'color': '00C896'},
        {'type': 'Index Funds', 'percentage': 30, 'color': '3B82F6'},
        {'type': 'Gold / Debt', 'percentage': 20, 'color': 'F59E0B'},
        {'type': 'Intl. Funds', 'percentage': 10, 'color': '8B5CF6'},
    ]
