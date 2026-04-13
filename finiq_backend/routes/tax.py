from flask import Blueprint, request, jsonify
from models.firebase import verify_token
from models.database import tax_reports_collection
from models.user_model import get_user_by_uid
from engines.tax_engine import compare_regimes

tax_bp = Blueprint('tax', __name__)

@tax_bp.route('/tax/compare', methods=['POST'])
def get_tax_report():
    auth_header = request.headers.get('Authorization')
    decoded = verify_token(auth_header)
    uid = decoded.get('uid') if decoded else 'demo_user'

    data = request.json or {}
    annual_income = data.get('annual_income')

    # Accept inline deduction overrides from "Add My Deductions" mode
    deduction_80c = data.get('investment_80c', None)
    deduction_80d = data.get('premium_80d', None)
    deduction_nps = data.get('nps_contribution', None)
    deduction_hra = data.get('hra', None)
    deduction_home = data.get('home_loan_interest', None)

    # If user sent a custom income from Tax Wizard, recalculate live
    if annual_income is not None and float(annual_income) > 0:
        # Fetch user's actual deductions from profile for personalised comparison
        user = get_user_by_uid(uid)
        profile = user.get('profile', {}) if user else {}

        result = compare_regimes(
            income=float(annual_income),
            investment_80c=float(deduction_80c if deduction_80c is not None
                                 else profile.get('section_80c', 0)),
            premium_80d=float(deduction_80d if deduction_80d is not None
                              else profile.get('premium_80d', 0)),
            nps_contribution=float(deduction_nps if deduction_nps is not None
                                   else profile.get('nps_contribution', 0)),
            hra=float(deduction_hra if deduction_hra is not None
                      else profile.get('hra', 0)),
            home_loan_interest=float(deduction_home if deduction_home is not None
                                     else profile.get('home_loan_interest', 0)),
        )

        old_tax = result['old_regime']['total_tax']
        new_tax = result['new_regime']['total_tax']
        recommended = result['recommended_regime']
        saving = result['tax_saving_by_switching']

        # Build Artha verdict
        if result.get('below_threshold'):
            artha_verdict = (
                'Your income is below the taxable threshold. '
                'No tax is applicable under either regime!'
            )
        else:
            total_deductions = result['old_regime'].get('total_deductions', 0)
            total_potential = result['total_potential_saving']
            if total_deductions <= 50000:  # Only standard deduction
                artha_verdict = (
                    f'With no active deductions, the {recommended.capitalize()} Regime '
                    f'saves you ₹{saving:,}. Maximize 80C + 80D + NPS to potentially '
                    f'save ₹{total_potential:,} more in the Old Regime.'
                )
            else:
                artha_verdict = (
                    f'With your deductions of ₹{total_deductions:,}, the '
                    f'{recommended.capitalize()} Regime saves you ₹{saving:,}. '
                    f'You can still save ₹{total_potential:,} by '
                    f'using remaining deduction headroom.'
                )

        # Build enhanced missed_deductions for Flutter
        missed_deductions_response = []
        for d in result.get('missed_deductions', []):
            utilised = d.get('utilised', 0)
            maximum = d.get('maximum', 0)
            remaining = d.get('remaining', 0)
            status = d.get('status', 'NOT_UTILISED')

            # Status label for Flutter
            if status == 'MAXIMISED':
                status_label = 'MAXIMISED'
            elif status == 'PARTIAL':
                status_label = 'PARTIAL'
            else:
                status_label = 'NOT UTILIZED'

            missed_deductions_response.append({
                'name': f"Section {d['section']}",
                'subtitle': d['description'],
                'amount': d['tax_saving'],
                'status': status_label,
                'icon': ('account_balance' if '80C' in d['section']
                         else ('health_and_safety' if '80D' in d['section']
                               else 'savings')),
                # Enhanced fields for v2 UI
                'utilised': utilised,
                'maximum': maximum,
                'remaining': remaining,
                'tax_saving_if_maximised': d.get('tax_saving_if_maximised', 0),
                'monthly_to_maximise': d.get('monthly_to_maximise', 0),
                'deduction_status': status,
            })

        return jsonify({
            'old_regime': {
                'label': 'Old Regime',
                'tax_payable': old_tax,
                'effective_rate': result['old_regime']['effective_rate'],
                'deductions_applied': result['old_regime'].get('total_deductions', 0),
                'is_recommended': recommended == 'old',
            },
            'new_regime': {
                'label': 'New Regime',
                'tax_payable': new_tax,
                'effective_rate': result['new_regime']['effective_rate'],
                'deductions_applied': 0,
                'is_recommended': recommended == 'new',
            },
            'recommended_regime': recommended,
            'tax_saving_by_switching': saving,
            'total_potential_saving': result['total_potential_saving'],
            'marginal_rate': result.get('marginal_rate', 0.3),
            'missed_deductions': missed_deductions_response,
            'old_regime_with_max_deductions': result.get('old_regime_with_max_deductions', {}),
            'artha_verdict': artha_verdict,
            'below_threshold': result.get('below_threshold', False),
        }), 200

    # Otherwise return the pre-computed report from onboarding
    doc = tax_reports_collection.find_one({'firebase_uid': uid}, {'_id': 0})
    if doc:
        doc.pop('firebase_uid', None)
        doc.pop('created_at', None)
        return jsonify(doc), 200

    return jsonify({'error': 'Tax report not found. Complete onboarding first.'}), 404
