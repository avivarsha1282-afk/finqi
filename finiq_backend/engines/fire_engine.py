import math


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
    # ── Validation ───────────────────────────────────────────
    if target_amount is None or target_amount <= 0:
        target_amount = 10000000  # Default ₹1Cr
    if years is None or years <= 0:
        years = 7
    if current_savings is None or current_savings < 0:
        current_savings = 0
    if monthly_income is None or monthly_income < 0:
        monthly_income = 1  # Prevent division by zero

    monthly_rate = annual_return / 12
    months = years * 12

    # Future value of current savings
    fv_savings = current_savings * ((1 + monthly_rate) ** months) if current_savings > 0 else 0

    # Remaining corpus needed from SIP
    remaining = max(0, target_amount - fv_savings)

    # Goal already achievable with current savings
    if remaining <= 0:
        return {
            'required_monthly_sip': 0,
            'target_amount': target_amount,
            'target_years': years,
            'current_savings': current_savings,
            'annual_return': round(annual_return * 100, 1),
            'achievability': 'ALREADY_ACHIEVABLE',
            'recommendation': ('Your current savings already cover this goal! '
                               'Consider a more ambitious target or invest the surplus.'),
            'timeline': [{'year': 0, 'corpus': round(current_savings)},
                         {'year': years, 'corpus': round(fv_savings)}],
            'scenarios': [],
            'asset_allocation': [
                {'type': 'Equity', 'percentage': 40, 'color': '00C896'},
                {'type': 'Index Funds', 'percentage': 30, 'color': '3B82F6'},
                {'type': 'Gold / Debt', 'percentage': 20, 'color': 'F59E0B'},
                {'type': 'Intl. Funds', 'percentage': 10, 'color': '8B5CF6'},
            ]
        }

    # Required SIP calculation
    if monthly_rate > 0 and months > 0:
        required_sip = remaining * monthly_rate / (
            ((1 + monthly_rate) ** months) - 1
        )
    elif months > 0:
        required_sip = remaining / months
    else:
        required_sip = remaining

    # ── Achievability ────────────────────────────────────────
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

    # ── Generate timeline (year 0 through final year) ────────
    timeline = []
    corpus = current_savings
    # Add year 0 (starting point)
    timeline.append({
        'year': 0,
        'corpus': round(corpus)
    })
    for month in range(1, months + 1):
        corpus = corpus * (1 + monthly_rate) + required_sip
        if month % 12 == 0:
            timeline.append({
                'year': month // 12,
                'corpus': round(corpus)
            })

    # ── Scenarios (3 options) ────────────────────────────────
    aggressive_years = max(3, years - 4)
    conservative_years = years + 3

    scenarios = [
        {
            'label': f'{aggressive_years} Years — Aggressive',
            'years': aggressive_years,
            'risk': 'HIGH RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, aggressive_years, current_savings, 0.14)
        },
        {
            'label': f'{years} Years — Sustainable',
            'years': years,
            'risk': 'RECOMMENDED',
            'required_sip': round(required_sip)
        },
        {
            'label': f'{conservative_years} Years — Conservative',
            'years': conservative_years,
            'risk': 'LOW RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, conservative_years, current_savings, 0.10)
        }
    ]

    return {
        'required_monthly_sip': round(required_sip),
        'target_amount': target_amount,
        'target_years': years,
        'current_savings': current_savings,
        'annual_return': round(annual_return * 100, 1),
        'achievability': achievability,
        'recommendation': recommendation,
        'timeline': timeline,
        'scenarios': scenarios,
        'asset_allocation': [
            {'type': 'Equity', 'percentage': 40, 'color': '00C896'},
            {'type': 'Index Funds', 'percentage': 30, 'color': '3B82F6'},
            {'type': 'Gold / Debt', 'percentage': 20, 'color': 'F59E0B'},
            {'type': 'Intl. Funds', 'percentage': 10, 'color': '8B5CF6'},
        ]
    }
