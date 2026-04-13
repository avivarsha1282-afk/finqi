"""
FinIQ Tax Engine — Production v2 (FY2025-26)
Verified against Indian Income Tax slabs.
All numbers are pre-computed — LLM never calculates.
"""


def calculate_tax_new(income):
    """Calculate tax under New Regime (FY2025-26 Budget)."""
    std_deduction = 75000
    taxable = max(0, income - std_deduction)
    tax = _compute_slab_tax(taxable, _NEW_SLABS)
    # Section 87A rebate: full rebate if taxable income ≤ ₹12L
    if taxable <= 1200000:
        tax = 0
    cess = tax * 0.04
    return round(tax + cess)


def calculate_tax_old(income, total_deductions):
    """Calculate tax under Old Regime."""
    taxable = max(0, income - total_deductions)
    tax = _compute_slab_tax(taxable, _OLD_SLABS)
    # Section 87A rebate: full rebate if taxable income ≤ ₹5L
    if taxable <= 500000:
        tax = 0
    cess = tax * 0.04
    return round(tax + cess)


# ── Slab definitions (width-based, not cumulative) ───────────────────────────

# New Regime FY2025-26 (Union Budget)
_NEW_SLABS = [
    (300000,        0.00),   # 0 - 3L: 0%
    (400000,        0.05),   # 3L - 7L: 5%
    (300000,        0.10),   # 7L - 10L: 10%
    (200000,        0.15),   # 10L - 12L: 15%
    (300000,        0.20),   # 12L - 15L: 20%
    (float('inf'),  0.30),   # Above 15L: 30%
]

# Old Regime
_OLD_SLABS = [
    (250000,        0.00),   # 0 - 2.5L: 0%
    (250000,        0.05),   # 2.5L - 5L: 5%
    (500000,        0.20),   # 5L - 10L: 20%
    (float('inf'),  0.30),   # Above 10L: 30%
]


def _compute_slab_tax(taxable, slabs):
    """Apply progressive slab rates to taxable income."""
    tax = 0.0
    remaining = taxable
    for slab_width, rate in slabs:
        if remaining <= 0:
            break
        taxed = min(remaining, slab_width)
        tax += taxed * rate
        remaining -= taxed
    return tax


def _get_marginal_rate(taxable):
    """Get the marginal tax rate for old regime based on taxable income."""
    if taxable <= 250000:
        return 0.00
    if taxable <= 500000:
        return 0.05
    if taxable <= 1000000:
        return 0.20
    return 0.30


def _get_status(utilised, maximum):
    """Return deduction utilisation status."""
    if utilised == 0:
        return 'NOT_UTILISED'
    if utilised < maximum:
        return 'PARTIAL'
    return 'MAXIMISED'


def _fmt_inr(n):
    """Format number in Indian notation."""
    n = int(n)
    if n >= 10000000:
        return f"₹{n / 10000000:.2f}Cr"
    if n >= 100000:
        return f"₹{n / 100000:.2f}L"
    if n >= 1000:
        return f"₹{n / 1000:.1f}K"
    return f"₹{n}"


def compare_regimes(income, investment_80c=0, premium_80d=0,
                    nps_contribution=0, hra=0, home_loan_interest=0):
    """
    Full dual-regime tax comparison with deduction opportunities.
    Returns everything the Flutter Tax Wizard needs in one call.
    """
    if income < 300000:
        return {
            'old_regime': {'total_tax': 0, 'effective_rate': 0, 'total_deductions': 0},
            'new_regime': {'total_tax': 0, 'effective_rate': 0},
            'recommended_regime': 'new',
            'tax_saving_by_switching': 0,
            'missed_deductions': [],
            'total_potential_saving': 0,
            'below_threshold': True,
        }

    # ── Validate & cap deductions ────────────────────────────────────────
    d_80c = min(float(investment_80c), 150000)
    d_80d = min(float(premium_80d), 50000)
    d_80ccd = min(float(nps_contribution), 50000)
    d_hra = min(float(hra), income * 0.5)  # Cap at 50% of income
    d_home = min(float(home_loan_interest), 200000)
    old_std = 50000

    total_deductions = old_std + d_80c + d_80d + d_80ccd + d_hra + d_home

    # ── Calculate both regimes ───────────────────────────────────────────
    old_tax = calculate_tax_old(income, total_deductions)
    new_tax = calculate_tax_new(income)

    old_taxable = max(0, income - total_deductions)
    new_taxable = max(0, income - 75000)

    if old_tax < new_tax:
        recommended = 'old'
        saving = new_tax - old_tax
    else:
        recommended = 'new'
        saving = old_tax - new_tax

    # ── Marginal rate for deduction tax savings ──────────────────────────
    marginal_rate = _get_marginal_rate(old_taxable)
    marginal_rate_with_cess = marginal_rate * 1.04

    # ── Deduction opportunities ──────────────────────────────────────────
    rem_80c = 150000 - d_80c
    rem_80d = 25000 - min(d_80d, 25000)  # Self+family limit
    rem_nps = 50000 - d_80ccd

    missed_deductions = []
    if d_80c < 150000:
        tax_save = round(rem_80c * marginal_rate_with_cess)
        missed_deductions.append({
            'section': '80C',
            'description': 'ELSS, PPF, LIC, EPF',
            'potential_deduction': rem_80c,
            'tax_saving': tax_save,
            'utilised': d_80c,
            'maximum': 150000,
            'remaining': rem_80c,
            'tax_saving_if_maximised': tax_save,
            'monthly_to_maximise': round(rem_80c / 12),
            'status': _get_status(d_80c, 150000),
        })
    if d_80d < 25000:
        tax_save = round(rem_80d * marginal_rate_with_cess)
        missed_deductions.append({
            'section': '80D',
            'description': 'Health Insurance Premium',
            'potential_deduction': rem_80d,
            'tax_saving': tax_save,
            'utilised': d_80d,
            'maximum': 25000,
            'remaining': rem_80d,
            'tax_saving_if_maximised': tax_save,
            'monthly_to_maximise': round(rem_80d / 12),
            'status': _get_status(d_80d, 25000),
        })
    if d_80ccd < 50000:
        tax_save = round(rem_nps * marginal_rate_with_cess)
        missed_deductions.append({
            'section': '80CCD(1B)',
            'description': 'NPS Tier 1 Contribution',
            'potential_deduction': rem_nps,
            'tax_saving': tax_save,
            'utilised': d_80ccd,
            'maximum': 50000,
            'remaining': rem_nps,
            'tax_saving_if_maximised': tax_save,
            'monthly_to_maximise': round(rem_nps / 12),
            'status': _get_status(d_80ccd, 50000),
        })

    total_potential_saving = sum(d['tax_saving'] for d in missed_deductions)

    # ── Old regime with MAX deductions (what-if) ────────────────────────
    max_additional_deductions = rem_80c + rem_80d + rem_nps
    old_tax_if_maximised = calculate_tax_old(
        income, total_deductions + max_additional_deductions
    )
    additional_savings_if_maximised = old_tax - old_tax_if_maximised

    old_eff_if_max = round(
        old_tax_if_maximised / income * 100, 1
    ) if income > 0 else 0

    return {
        'old_regime': {
            'total_tax': old_tax,
            'effective_rate': round(old_tax / income * 100, 1) if income > 0 else 0,
            'total_deductions': round(total_deductions),
            'taxable_income': round(old_taxable),
            'breakdown': {
                'standard_deduction': old_std,
                '80c': d_80c,
                '80d': d_80d,
                '80ccd': d_80ccd,
                'hra': d_hra,
                'home_loan_interest': d_home,
            },
        },
        'new_regime': {
            'total_tax': new_tax,
            'effective_rate': round(new_tax / income * 100, 1) if income > 0 else 0,
            'taxable_income': round(new_taxable),
            'standard_deduction': 75000,
        },
        'recommended_regime': recommended,
        'tax_saving_by_switching': saving,
        'missed_deductions': missed_deductions,
        'total_potential_saving': total_potential_saving,
        'marginal_rate': marginal_rate,
        'old_regime_with_max_deductions': {
            'tax': old_tax_if_maximised,
            'additional_savings': additional_savings_if_maximised,
            'effective_rate_if_maximised': old_eff_if_max,
        },
        'below_threshold': False,
    }
