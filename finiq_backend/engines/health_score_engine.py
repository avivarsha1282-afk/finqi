def calculate_health_score(profile):
    scores = {}
    
    # 1. Emergency Fund (weight 25%, max 20pts)
    try:
        months = float(profile.get('current_savings', 0)) / max(float(profile.get('monthly_expenses', 1)), 1)
    except:
        months = 0
    if months >= 6: scores['emergency_fund'] = 20
    elif months >= 3: scores['emergency_fund'] = 12
    elif months >= 1: scores['emergency_fund'] = 6
    else: scores['emergency_fund'] = 0
    
    # 2. Insurance (weight 20%, max 20pts)
    has_health = str(profile.get('health_insurance', '')).lower() == 'yes'
    has_term = str(profile.get('life_insurance', '')).lower() != 'no' and profile.get('life_insurance')
    if has_health and has_term: scores['insurance'] = 20
    elif has_health or has_term: scores['insurance'] = 10
    else: scores['insurance'] = 0
    
    # 3. Debt Health (weight 20%, max 20pts)
    try:
        total_emi = float(profile.get('emis', 0))
        income = float(profile.get('monthly_salary', 1))
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
    if investment_80c >= 150000: scores['tax_efficiency'] = 20
    elif investment_80c >= 100000: scores['tax_efficiency'] = 14
    elif investment_80c >= 50000: scores['tax_efficiency'] = 8
    else: scores['tax_efficiency'] = 2
    
    # 5. Diversification (weight 10%, max 20pts)
    investments = str(profile.get('existing_investments', ''))
    asset_count = 0
    if 'mf' in investments.lower() or 'mutual' in investments.lower(): asset_count += 1
    if 'stock' in investments.lower(): asset_count += 1
    if 'fd' in investments.lower(): asset_count += 1
    if 'ppf' in investments.lower(): asset_count += 1
    
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
    has_ppf = 'ppf' in investments.lower()
    if has_nps and has_ppf: scores['retirement'] = 20
    elif has_nps or has_ppf: scores['retirement'] = 10
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
        'dimensions': scores,
        'priority_actions': priority_actions
    }
