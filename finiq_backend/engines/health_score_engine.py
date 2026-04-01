def calculate_health_score(profile):
    scores = {}
    
    # 1. Emergency Fund (weight 25%, max 20pts)
    try:
        months = float(profile.get('current_savings', 0)) / max(float(profile.get('monthly_expense', 1)), 1)
    except:
        months = 0
    if months >= 6: scores['emergency_fund'] = 20
    elif months >= 3: scores['emergency_fund'] = 12
    elif months >= 1: scores['emergency_fund'] = 6
    else: scores['emergency_fund'] = 0
    
    # 2. Insurance (weight 20%, max 20pts)
    # Read the CORRECT field names from onboarding profile
    has_health = profile.get('has_health_insurance', False)
    has_term = profile.get('has_term_insurance', False)
    # Handle both bool and string representations
    if isinstance(has_health, str):
        has_health = has_health.lower() in ('true', 'yes', '1')
    if isinstance(has_term, str):
        has_term = has_term.lower() in ('true', 'yes', '1')
    if has_health and has_term: scores['insurance'] = 20
    elif has_health or has_term: scores['insurance'] = 10
    else: scores['insurance'] = 0
    
    # 3. Debt Health (weight 20%, max 20pts)
    try:
        total_emi = float(profile.get('total_emi', 0))
        income = float(profile.get('monthly_salary', 1))
        if income <= 0: income = 1
        emi_ratio = total_emi / income
    except:
        emi_ratio = 0
    if emi_ratio < 0.2: scores['debt_health'] = 20
    elif emi_ratio < 0.4: scores['debt_health'] = 12
    elif emi_ratio < 0.6: scores['debt_health'] = 4
    else: scores['debt_health'] = 0
    
    # 4. Tax Efficiency (weight 15%, max 20pts)
    try:
        investment_80c = float(profile.get('section_80c', 0))
    except:
        investment_80c = 0
        
    try:
        annual_income = float(profile.get('annual_income', 0))
        if annual_income <= 0:
            annual_income = float(profile.get('monthly_salary', 0)) * 12
    except:
        annual_income = 0
        
    if annual_income < 300000:
        scores['tax_efficiency'] = 20  # Below taxable threshold = perfect
    else:
        if investment_80c >= 150000: scores['tax_efficiency'] = 20
        elif investment_80c >= 100000: scores['tax_efficiency'] = 14
        elif investment_80c >= 50000: scores['tax_efficiency'] = 8
        else: scores['tax_efficiency'] = 2
    
    # 5. Diversification (weight 10%, max 20pts)
    # Count asset classes the user actually has
    asset_count = 0
    try:
        if float(profile.get('section_80c', 0)) > 0: asset_count += 1  # ELSS/PPF/LIC
    except: pass
    try:
        if float(profile.get('nps_contribution', 0)) > 0: asset_count += 1  # NPS
    except: pass
    try:
        if float(profile.get('current_savings', 0)) > 0: asset_count += 1  # Savings
    except: pass
    try:
        if float(profile.get('premium_80d', 0)) > 0: asset_count += 1  # Insurance (investment)
    except: pass
    
    if asset_count >= 4: scores['diversification'] = 20
    elif asset_count == 3: scores['diversification'] = 15
    elif asset_count == 2: scores['diversification'] = 10
    elif asset_count == 1: scores['diversification'] = 4
    else: scores['diversification'] = 0
    
    # 6. Retirement (weight 10%, max 20pts)
    try:
        has_nps = float(profile.get('nps_contribution', 0)) > 0
    except:
        has_nps = False
    has_80c = investment_80c > 0  # Could include PPF
    if has_nps and has_80c: scores['retirement'] = 20
    elif has_nps or has_80c: scores['retirement'] = 10
    else: scores['retirement'] = 0
    
    weights = {
        'emergency_fund': 0.25,
        'insurance': 0.20,
        'debt_health': 0.20,
        'tax_efficiency': 0.15,
        'diversification': 0.10,
        'retirement': 0.10
    }
    
    total = sum(scores[k] * weights[k] * 5 for k in weights)
    
    if total >= 80: grade = 'A'
    elif total >= 60: grade = 'B'
    elif total >= 40: grade = 'C'
    elif total >= 20: grade = 'D'
    else: grade = 'F'

    grade_labels = {
        'A': 'Excellent! Maintain your financial discipline.',
        'B': 'Good shape — a few tweaks will push you to A.',
        'C': 'Decent foundation. Focus on weak dimensions.',
        'D': 'Needs attention. Start with insurance & emergency fund.',
        'F': 'Critical — take action on the priority items below.'
    }
    
    # Priority actions sorted by urgency
    priority_actions = sorted(
        [{'dimension': k, 'score': scores[k], 
          'max': 20, 'weight': weights[k]} 
         for k in scores],
        key=lambda x: x['score']
    )
    
    return {
        'total_score': round(total),
        'grade': grade,
        'grade_label': grade_labels.get(grade, ''),
        'dimensions': scores,
        'priority_actions': priority_actions
    }
