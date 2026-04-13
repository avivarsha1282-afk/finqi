from engines.tax_engine import compare_regimes
r = compare_regimes(3000000)
print(f"Income: 30L")
print(f"Old Tax: {r['old_regime']['total_tax']:,} ({r['old_regime']['effective_rate']}%)")
print(f"New Tax: {r['new_regime']['total_tax']:,} ({r['new_regime']['effective_rate']}%)")
print(f"Best: {r['recommended_regime']}")
print(f"Saving: {r['tax_saving_by_switching']:,}")
print(f"Missed deductions: {len(r['missed_deductions'])}")
for d in r['missed_deductions']:
    print(f"  {d['section']}: remain={d['remaining']:,} save={d['tax_saving']:,} status={d['status']}")
print(f"Potential saving: {r['total_potential_saving']:,}")
print(f"Old w/ max deductions: tax={r['old_regime_with_max_deductions']['tax']:,}, extra_save={r['old_regime_with_max_deductions']['additional_savings']:,}")
