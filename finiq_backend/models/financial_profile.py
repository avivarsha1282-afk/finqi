"""
FinancialProfile — Single Source of Truth for all user financial data.
All engines, endpoints, and prompts must use this model.
Never compute or round independently in each screen/route.
"""


class FinancialProfile:
    """Normalised financial profile built from raw MongoDB/request data.
    Accepts BOTH old-format (monthly_salary) and new-format (monthlyIncome) keys.
    """

    def __init__(self, raw: dict):
        self.raw = raw or {}

        # ── Identity ────────────────────────────────────────────────
        self.full_name = (
            self._str('fullName') or self._str('full_name') or
            self._str('name') or 'User'
        )
        self.first_name = self.full_name.strip().split(' ')[0]
        self.age = self._int('age', 25)
        self.occupation = self._str('occupation') or 'Salaried'
        self.city = self._str('city') or 'India'
        self.risk_appetite = (
            self._str('risk_appetite') or self._str('riskAppetite') or 'moderate'
        )

        # ── Income & Cash Flow ──────────────────────────────────────
        self.monthly_income = self._num(
            'monthly_salary', 'monthly_income', 'monthlyIncome', default=0)
        self.monthly_expenses = self._num(
            'monthly_expense', 'monthly_expenses', 'monthlyExpenses', default=0)
        self.monthly_emi = self._num(
            'monthly_emi', 'monthlyEmi', 'total_emi', default=0)
        self.total_loan = self._num(
            'total_loan', 'totalLoan', default=0)
        self.monthly_rent = self._num(
            'monthly_rent', 'monthlyRent', 'house_rent', default=0)

        self.annual_income = self.monthly_income * 12
        self.monthly_surplus = max(0, self.monthly_income - self.monthly_expenses - self.monthly_emi)
        self.annual_surplus = self.monthly_surplus * 12

        # ── Wealth ──────────────────────────────────────────────────
        self.current_savings = self._num(
            'current_savings', 'currentSavings', default=0)
        self.mutual_funds = self._num('mutual_funds', default=0)
        self.ppf_balance = self._num('ppf', 'ppf_balance', default=0)
        self.nps_balance = self._num('nps', 'nps_balance', 'nps_contribution', default=0)

        # ── Insurance ───────────────────────────────────────────────
        self.has_health_insurance = self._bool(
            'has_health_insurance', 'health_insurance')
        self.has_term_insurance = self._bool(
            'has_term_insurance', 'life_insurance', 'term_insurance')

        # ── Tax Deductions ──────────────────────────────────────────
        self.section_80c = self._num(
            'section_80c', 'annual_80c', 'deduction_80c', default=0)
        self.premium_80d = self._num(
            'premium_80d', 'annual_80d', 'deduction_80d', default=0)
        self.nps_contribution = self._num(
            'nps_contribution', 'annual_nps', default=0)

        # ── Goals ───────────────────────────────────────────────────
        self.goal_type = (
            self._str('goal_type') or self._str('goalType') or 'Wealth Building'
        )
        self.goal_name = (
            self._str('financial_goal') or self._str('goal_name') or
            self._str('goalName') or 'Financial Freedom'
        )
        self.goal_amount = self._num(
            'financial_goal_amount', 'goal_amount', 'goalAmount',
            default=10_000_000)
        self.goal_timeline_yrs = self._int_multi(
            'target_timeline', 'goal_years', 'goalTimeline', default=10)

    # ── Computed Ratios ─────────────────────────────────────────────

    @property
    def savings_rate_pct(self) -> float:
        if self.monthly_income <= 0:
            return 0.0
        return round(self.monthly_surplus / self.monthly_income * 100, 1)

    @property
    def emergency_fund_months(self) -> float:
        if self.monthly_expenses <= 0:
            return 0.0
        return round(self.current_savings / self.monthly_expenses, 1)

    @property
    def emi_pct_of_income(self) -> float:
        """Monthly EMI as percentage of monthly income (correct metric)."""
        if self.monthly_income <= 0:
            return 0.0
        return round(self.monthly_emi / self.monthly_income * 100, 1)

    @property
    def loan_to_annual_income(self) -> float:
        """Total outstanding loan as ratio of annual income."""
        if self.annual_income <= 0:
            return 0.0
        return round(self.total_loan / self.annual_income, 2)

    @property
    def goal_achieved(self) -> bool:
        return self.current_savings >= self.goal_amount > 0

    @property
    def tax_bracket_pct(self) -> int:
        """Marginal tax rate based on annual income (New Regime FY25-26)."""
        ai = self.annual_income
        if ai <= 400_000:   return 0
        if ai <= 800_000:   return 5
        if ai <= 1_200_000: return 10
        if ai <= 1_600_000: return 15
        if ai <= 2_000_000: return 20
        if ai <= 2_400_000: return 25
        return 30

    @property
    def tax_saving_80c(self) -> int:
        """Potential tax saving from maximising 80C (old regime)."""
        return round(min(150_000, max(0, 150_000 - self.section_80c)) * self.tax_bracket_pct / 100)

    @property
    def tax_saving_80d(self) -> int:
        return round(min(25_000, max(0, 25_000 - self.premium_80d)) * self.tax_bracket_pct / 100)

    @property
    def tax_saving_nps(self) -> int:
        return round(min(50_000, max(0, 50_000 - self.nps_contribution)) * self.tax_bracket_pct / 100)

    @property
    def total_tax_saving(self) -> int:
        return self.tax_saving_80c + self.tax_saving_80d + self.tax_saving_nps

    # ── Formatting ──────────────────────────────────────────────────

    @staticmethod
    def format_inr(amount, compact: bool = True) -> str:
        """
        SINGLE formatting function used by ALL backend screens.
        compact=True:  ₹4.25Cr, ₹11.25L, ₹12.5K
        compact=False: ₹4,25,00,000 (Indian comma format)
        """
        try:
            amount = abs(int(float(amount or 0)))
        except (TypeError, ValueError):
            return '₹0'

        if compact:
            if amount >= 10_000_000:
                return f'₹{amount / 10_000_000:.2f}Cr'
            elif amount >= 100_000:
                return f'₹{amount / 100_000:.2f}L'
            elif amount >= 1_000:
                return f'₹{amount / 1_000:.2f}K'
            return f'₹{amount}'
        else:
            s = str(amount)
            if len(s) <= 3:
                return f'₹{s}'
            result = s[-3:]
            s = s[:-3]
            while len(s) > 2:
                result = s[-2:] + ',' + result
                s = s[:-2]
            if s:
                result = s + ',' + result
            return f'₹{result}'

    # ── Private helpers ─────────────────────────────────────────────

    def _num(self, *keys, default=0):
        """Get first non-None numeric value from multiple possible keys."""
        for k in keys:
            v = self.raw.get(k)
            if v is not None:
                try:
                    return int(float(v))
                except (TypeError, ValueError):
                    continue
        return int(default)

    def _int(self, key, default=0):
        v = self.raw.get(key)
        if v is not None:
            try:
                return int(float(v))
            except (TypeError, ValueError):
                pass
        return default

    def _int_multi(self, *keys, default=0):
        for k in keys:
            v = self.raw.get(k)
            if v is not None:
                try:
                    return int(float(v))
                except (TypeError, ValueError):
                    continue
        return default

    def _str(self, key):
        v = self.raw.get(key)
        if v and isinstance(v, str) and v.strip():
            return v.strip()
        return None

    def _bool(self, *keys):
        for k in keys:
            v = self.raw.get(k)
            if v is None:
                continue
            if isinstance(v, bool):
                return v
            if isinstance(v, str):
                return v.lower().strip() in ('true', 'yes', '1')
            if isinstance(v, (int, float)):
                return v > 0
        return False
