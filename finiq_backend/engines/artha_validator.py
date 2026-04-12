"""
Artha Response Validator — Post-processing math check.
Catches known LLM errors (e.g. ₹52,500 for 80C monthly)
before the response reaches the user.
"""

import re
from models.financial_profile import FinancialProfile


# Known wrong patterns that LLMs commonly generate
KNOWN_WRONG_PATTERNS = [
    {
        'pattern': r'₹\s*52[,.]?500.*(?:month|per\s*month|/mo)',
        'error': '80C monthly SIP stated as ₹52,500',
        'correction': '**Correction:** Section 80C monthly SIP = ₹1,50,000 ÷ 12 = **₹12,500/month**, not ₹52,500.',
    },
    {
        'pattern': r'₹\s*52[,.]?500.*(?:ELSS|80C)',
        'error': '80C/ELSS amount of ₹52,500',
        'correction': '**Correction:** Maximum 80C investment is ₹1,50,000/year = **₹12,500/month**.',
    },
]


def validate_artha_response(response: str, profile_data: dict) -> str:
    """Post-process Artha's response to catch known math errors.

    If an error is detected, the incorrect statement is flagged
    and the correct information is appended.

    Args:
        response: Raw LLM response text.
        profile_data: User's profile dict for context.

    Returns:
        Validated (and possibly corrected) response text.
    """
    if not response:
        return response

    for check in KNOWN_WRONG_PATTERNS:
        if re.search(check['pattern'], response, re.IGNORECASE):
            print(f"[ARTHA_VALIDATOR] Error detected: {check['error']}")
            # Replace the wrong amount inline if possible
            response = re.sub(
                r'₹\s*52[,.]?500',
                '₹12,500',
                response,
            )

    # Validate EMI ratio isn't calculated as total_loan / monthly_income
    p = FinancialProfile(profile_data)
    if p.total_loan > 0 and p.monthly_income > 0:
        wrong_ratio = round(p.total_loan / p.monthly_income * 100)
        correct_ratio = p.emi_pct_of_income
        # If the response mentions the wrong ratio (> 100%), flag it
        wrong_pct_str = f'{wrong_ratio}%'
        if wrong_ratio > 100 and wrong_pct_str in response:
            print(f"[ARTHA_VALIDATOR] Wrong EMI ratio detected: {wrong_pct_str}")
            response = response.replace(
                wrong_pct_str,
                f'{correct_ratio:.0f}% (monthly EMI / monthly income)',
            )

    return response
