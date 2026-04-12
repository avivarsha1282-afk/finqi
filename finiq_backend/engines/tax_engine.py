NEW_REGIME_SLABS = [
    (400000, 0.00),
    (800000, 0.05),
    (1200000, 0.10),
    (1600000, 0.15),
    (2000000, 0.20),
    (2400000, 0.25),
    (float('inf'), 0.30)
]

OLD_REGIME_SLABS = [
    (250000, 0.00),
    (500000, 0.05),
    (1000000, 0.20),
    (float('inf'), 0.30)
]

def calculate_tax_new(income):
    std_deduction = 75000
    taxable = max(0, income - std_deduction)
    return _apply_slabs(taxable, NEW_REGIME_SLABS)

def calculate_tax_old(income, deductions):
    std_deduction = 50000
    total_deductions = std_deduction + deductions
    taxable = max(0, income - total_deductions)
    return _apply_slabs(taxable, OLD_REGIME_SLABS)

def _apply_slabs(taxable_income, slabs):
    tax = 0
    prev_limit = 0
    for limit, rate in slabs:
        if taxable_income <= prev_limit:
            break
        slab_income = min(taxable_income, limit) - prev_limit
        tax += slab_income * rate
        prev_limit = limit
    cess = tax * 0.04
    return round(tax + cess)

def compare_regimes(income, investment_80c=0, premium_80d=0,
                    nps_contribution=0, hra=0):
    if income < 300000:
        return {
            'old_regime': {
                'total_tax': 0,
                'effective_rate': 0,
                'total_deductions': 0
            },
            'new_regime': {
                'total_tax': 0,
                'effective_rate': 0
            },
            'recommended_regime': 'new',
            'tax_saving_by_switching': 0,
            'missed_deductions': [],
            'total_potential_saving': 0,
            'below_threshold': True
        }

    total_deductions = (min(investment_80c, 150000) + 
                       min(premium_80d, 25000) + 
                       min(nps_contribution, 50000) + hra)
    
    old_tax = calculate_tax_old(income, total_deductions)
    new_tax = calculate_tax_new(income)
    
    if old_tax < new_tax:
        recommended = 'old'
        saving = new_tax - old_tax
    else:
        recommended = 'new'
        saving = old_tax - new_tax
    
    # Calculate ACTUAL marginal rate based on user's income slab (Old Regime)
    # This determines the real tax saving per rupee of deduction
    if income <= 250000:     marginal_rate = 0.0
    elif income <= 500000:   marginal_rate = 0.052   # 5% + 4% cess
    elif income <= 1000000:  marginal_rate = 0.208   # 20% + 4% cess
    else:                    marginal_rate = 0.312   # 30% + 4% cess

    missed_deductions = []
    if investment_80c < 150000:
        potential = min(150000 - investment_80c, 150000)
        missed_deductions.append({
            'section': '80C',
            'description': 'ELSS, PPF, LIC',
            'potential_deduction': potential,
            'tax_saving': round(potential * marginal_rate)
        })
    if premium_80d < 25000:
        gap = 25000 - premium_80d
        missed_deductions.append({
            'section': '80D',
            'description': 'Health Insurance Premium',
            'potential_deduction': gap,
            'tax_saving': round(gap * marginal_rate)
        })
    if nps_contribution < 50000:
        gap = 50000 - nps_contribution
        missed_deductions.append({
            'section': '80CCD(1B)',
            'description': 'NPS Contribution',
            'potential_deduction': gap,
            'tax_saving': round(gap * marginal_rate)
        })
    
    total_potential_saving = sum(d['tax_saving'] 
                                  for d in missed_deductions)
    
    return {
        'old_regime': {
            'total_tax': old_tax,
            'effective_rate': round(old_tax / income * 100, 1) if income > 0 else 0,
            'total_deductions': total_deductions
        },
        'new_regime': {
            'total_tax': new_tax,
            'effective_rate': round(new_tax / income * 100, 1) if income > 0 else 0
        },
        'recommended_regime': recommended,
        'tax_saving_by_switching': saving,
        'missed_deductions': missed_deductions,
        'total_potential_saving': total_potential_saving,
        'below_threshold': False
    }
