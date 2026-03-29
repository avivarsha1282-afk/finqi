def calculate_sip_for_years(target_amount, years, current_savings, annual_return):
    monthly_rate = annual_return / 12
    months = years * 12
    
    fv_savings = current_savings * ((1 + monthly_rate) ** months)
    remaining = max(0, target_amount - fv_savings)
    
    if monthly_rate > 0:
        required_sip = remaining * monthly_rate / (
            ((1 + monthly_rate) ** months - 1) * (1 + monthly_rate)
        )
    else:
        required_sip = remaining / months
        
    return round(required_sip)

def calculate_fire_plan(target_amount, years, current_savings, 
                        annual_return=0.12):
    monthly_rate = annual_return / 12
    months = years * 12
    
    # Future value of current savings
    fv_savings = current_savings * ((1 + monthly_rate) ** months)
    
    # Remaining corpus needed from SIP
    remaining = max(0, target_amount - fv_savings)
    
    # Reverse SIP formula
    if monthly_rate > 0:
        required_sip = remaining * monthly_rate / (
            ((1 + monthly_rate) ** months - 1) * (1 + monthly_rate)
        )
    else:
        required_sip = remaining / months
    
    # Generate timeline (monthly data points)
    timeline = []
    corpus = current_savings
    for month in range(1, months + 1):
        corpus = corpus * (1 + monthly_rate) + required_sip
        if month % 12 == 0:
            timeline.append({
                'year': month // 12,
                'corpus': round(corpus)
            })
    
    # 3 scenarios
    scenarios = [
        {
            'label': '3 Years — Aggressive',
            'years': 3,
            'risk': 'HIGH RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, 3, current_savings, 0.15)
        },
        {
            'label': f'{years} Years — Sustainable',
            'years': years,
            'risk': 'RECOMMENDED',
            'required_sip': round(required_sip)
        },
        {
            'label': f'{years + 3} Years — Conservative',
            'years': years + 3,
            'risk': 'LOW RISK',
            'required_sip': calculate_sip_for_years(
                target_amount, years + 3, current_savings, 0.10)
        }
    ]
    
    return {
        'required_monthly_sip': round(required_sip),
        'timeline': timeline,
        'scenarios': scenarios,
        'asset_allocation': {
            'equity': 40,
            'index_funds': 30,
            'gold_debt': 20,
            'international': 10
        },
        'achievability': 'achievable' if required_sip < 200000 
                        else 'stretch'
    }
