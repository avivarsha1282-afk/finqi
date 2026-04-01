import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../models/expense_model.dart';
import '../../../services/expense_service.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final _selectedTabProvider = StateProvider<int>((ref) => 0);

final _monthKeyProvider = Provider<String>((ref) {
  final date = ref.watch(_selectedDateProvider);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
});

final _todayExpensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final date = ref.watch(_selectedDateProvider);
  ref.watch(_refreshTrigger);
  return ExpenseService.getExpensesForDate(date);
});

final _monthlySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final monthKey = ref.watch(_monthKeyProvider);
  ref.watch(_refreshTrigger);
  return ExpenseService.getMonthlySummary(monthKey);
});

final _monthlyBudgetProvider = FutureProvider.autoDispose<double>((ref) async {
  return ExpenseService.getMonthlyBudget();
});

final _monthExpensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final monthKey = ref.watch(_monthKeyProvider);
  ref.watch(_refreshTrigger);
  return ExpenseService.getExpensesForMonth(monthKey);
});

// Simple refresh trigger
final _refreshTrigger = StateProvider<int>((ref) => 0);

// ── Screen ───────────────────────────────────────────────────────────────────

class ExpenseTrackerScreen extends ConsumerStatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  ConsumerState<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends ConsumerState<ExpenseTrackerScreen>
    with TickerProviderStateMixin {
  // ── Category filter state ─────────────────────────────────
  String? _selectedCategory;
  int _selectedCategoryIndex = -1;
  bool _isCategorySelected = false;

  late AnimationController _barAnimController;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    super.dispose();
  }

  void _onCategoryTapped(int index) {
    final cat = ExpenseModel.categories[index];
    final category = cat['name'] as String;
    HapticFeedback.lightImpact();

    if (_selectedCategory == category) {
      // Same card tapped → deselect (State 3)
      _barAnimController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _selectedCategory = null;
            _selectedCategoryIndex = -1;
            _isCategorySelected = false;
          });
        }
      });
      return;
    }

    final wasAlreadyOpen = _isCategorySelected;

    if (wasAlreadyOpen) {
      // Category switch (State 2B) — bar exits then re-enters
      _barAnimController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _selectedCategory = category;
            _selectedCategoryIndex = index;
          });
          _barAnimController.forward();
        }
      });
    } else {
      // Fresh open (State 1 → State 2)
      setState(() {
        _selectedCategory = category;
        _selectedCategoryIndex = index;
        _isCategorySelected = true;
      });
      _barAnimController.forward();
    }
  }

  void _clearFilter() {
    _barAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedCategory = null;
          _selectedCategoryIndex = -1;
          _isCategorySelected = false;
        });
      }
    });
  }

  Map<String, dynamic>? get _selectedCatInfo {
    if (_selectedCategoryIndex < 0 ||
        _selectedCategoryIndex >= ExpenseModel.categories.length) return null;
    return ExpenseModel.categories[_selectedCategoryIndex];
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(_selectedTabProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 22),
            onPressed: () => _pickDate(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthlyOverviewCard(
            filteredCategory: _selectedCategory,
            filteredCategoryIcon: _selectedCatInfo?['icon'],
          ),
          const SizedBox(height: 8),
          _buildTabBar(ref, selectedTab),
          const SizedBox(height: 8),
          Expanded(
            child: selectedTab == 0
                ? _TodayTab(
                    selectedCategory: _selectedCategory,
                    selectedCategoryIndex: _selectedCategoryIndex,
                    isCategorySelected: _isCategorySelected,
                    barAnimController: _barAnimController,
                    onCategoryTap: _onCategoryTapped,
                    onClearFilter: _clearFilter,
                  )
                : selectedTab == 1
                    ? _HistoryTab()
                    : _AnalyticsTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_expense_sheet',
        backgroundColor: AppColors.primaryTeal,
        onPressed: () => _showAddExpenseSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, int selected) {
    const tabs = ['Today', 'History', 'Analytics'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(_selectedTabProvider.notifier).state = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(_selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(_selectedDateProvider.notifier).state = picked;
    }
  }
}

// ── Monthly Overview Card ────────────────────────────────────────────────────

class _MonthlyOverviewCard extends ConsumerWidget {
  final String? filteredCategory;
  final String? filteredCategoryIcon;

  const _MonthlyOverviewCard({
    this.filteredCategory,
    this.filteredCategoryIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_monthlySummaryProvider);
    final budgetAsync = ref.watch(_monthlyBudgetProvider);
    final date = ref.watch(_selectedDateProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(date).toUpperCase();
    final monthName = DateFormat('MMMM').format(date);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.primaryTeal, width: 3)),
      ),
      child: summaryAsync.when(
        data: (summary) {
          final totalSpent = summary['total_spent'] as double;
          final byCategory = summary['by_category'] as Map<String, double>? ?? {};
          final budget = budgetAsync.valueOrNull ?? 10000;

          // Compute display values based on filter
          final displayTotal = filteredCategory != null
              ? (byCategory[filteredCategory] ?? 0.0)
              : totalSpent;
          final progress = budget > 0 ? (displayTotal / budget).clamp(0.0, 1.5) : 0.0;
          final remaining = budget - displayTotal;
          final isOverBudget = remaining < 0;

          // Days remaining in month
          final now = DateTime.now();
          final lastDay = DateTime(date.year, date.month + 1, 0);
          final daysLeft = lastDay.day - now.day;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month label + optional filter dot
              Row(
                children: [
                  if (filteredCategory != null) ...[
                    Container(
                      width: 4, height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(monthLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 8),

              // Main amount row with AnimatedSwitcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey('header_${filteredCategory ?? 'all'}_$displayTotal'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    filteredCategory != null
                        ? Text('${filteredCategoryIcon ?? ''} $filteredCategory — ₹${_formatAmount(displayTotal)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))
                        : Text('₹${_formatAmount(displayTotal)} spent',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    if (filteredCategory == null)
                      Text('of ₹${_formatAmount(budget)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle: "spent this month" or "of budget"
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: filteredCategory != null
                    ? Text('spent this month in $monthName',
                        key: ValueKey('sub_$filteredCategory'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                    : const SizedBox.shrink(key: ValueKey('sub_none')),
              ),
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1F2937),
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.8 ? const Color(0xFFFF4444) : AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverBudget
                        ? '₹${_formatAmount(remaining.abs())} over budget!'
                        : '₹${_formatAmount(remaining)} remaining',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isOverBudget ? const Color(0xFFFF4444) : const Color(0xFF00C896),
                    ),
                  ),
                  Text('$daysLeft days left',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))),
        error: (_, __) => const Text('Could not load summary', style: TextStyle(color: AppColors.textSecondary)),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }
}

// ── Today Tab ────────────────────────────────────────────────────────────────

class _TodayTab extends ConsumerWidget {
  final String? selectedCategory;
  final int selectedCategoryIndex;
  final bool isCategorySelected;
  final AnimationController barAnimController;
  final void Function(int index) onCategoryTap;
  final VoidCallback onClearFilter;

  const _TodayTab({
    required this.selectedCategory,
    required this.selectedCategoryIndex,
    required this.isCategorySelected,
    required this.barAnimController,
    required this.onCategoryTap,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(_selectedDateProvider);
    final expensesAsync = ref.watch(_todayExpensesProvider);
    final dayLabel = DateFormat('EEEE, d MMMM').format(date);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dayLabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              expensesAsync.when(
                data: (expenses) {
                  final total = expenses.fold(0.0, (s, e) => s + e.amount);
                  return Text('Today: ₹${_formatAmount(total)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryTeal));
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Quick-add tiles
        _QuickAddTiles(
          selectedCategoryIndex: selectedCategoryIndex,
          isCategorySelected: isCategorySelected,
          onCategoryTap: onCategoryTap,
        ),
        const SizedBox(height: 8),

        // ── Glass Info Bar (slides in when category selected) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: isCategorySelected
              ? _GlassInfoBar(
                  selectedCategory: selectedCategory!,
                  selectedCategoryIndex: selectedCategoryIndex,
                  barAnimController: barAnimController,
                  onClearFilter: onClearFilter,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),

        // Expenses section header
        _buildExpensesHeader(),
        const SizedBox(height: 8),

        // Today's expense list (filtered if category selected)
        expensesAsync.when(
          data: (expenses) {
            final displayExpenses = selectedCategory != null
                ? expenses.where((e) => e.category == selectedCategory).toList()
                : expenses;

            if (displayExpenses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      selectedCategory != null
                          ? (ExpenseModel.categories.firstWhere(
                              (c) => c['name'] == selectedCategory,
                              orElse: () => {'icon': '📭'},
                            )['icon'] as String)
                          : '📭',
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedCategory != null
                          ? 'No $selectedCategory expenses yet'
                          : 'No expenses yet${_isToday(date) ? " today" : ""}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCategory != null
                          ? 'Your $selectedCategory transactions will appear here'
                          : 'Tap a category above to add one!',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: displayExpenses.map((e) => _ExpenseRow(expense: e)).toList(),
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          )),
          error: (_, __) => const Text('Failed to load expenses', style: TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }

  Widget _buildExpensesHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Row(
        key: ValueKey('header_${selectedCategory ?? 'all'}'),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedCategory != null
                ? '${selectedCategory!.toUpperCase()} EXPENSES'
                : 'EXPENSES',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textTertiary, letterSpacing: 1),
          ),
          if (selectedCategory != null)
            Consumer(builder: (_, ref, __) {
              final expensesAsync = ref.watch(_todayExpensesProvider);
              final count = expensesAsync.valueOrNull
                  ?.where((e) => e.category == selectedCategory).length ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$count entries',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
              );
            }),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ── Glass Info Bar ───────────────────────────────────────────────────────────

class _GlassInfoBar extends ConsumerWidget {
  final String selectedCategory;
  final int selectedCategoryIndex;
  final AnimationController barAnimController;
  final VoidCallback onClearFilter;

  const _GlassInfoBar({
    required this.selectedCategory,
    required this.selectedCategoryIndex,
    required this.barAnimController,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ExpenseModel.categories[selectedCategoryIndex];
    final icon = cat['icon'] as String;

    final todayExpenses = ref.watch(_todayExpensesProvider);
    final monthExpenses = ref.watch(_monthExpensesProvider);

    final todayTotal = todayExpenses.valueOrNull
        ?.where((e) => e.category == selectedCategory)
        .fold(0.0, (s, e) => s + e.amount) ?? 0.0;

    final monthTotal = monthExpenses.valueOrNull
        ?.where((e) => e.category == selectedCategory)
        .fold(0.0, (s, e) => s + e.amount) ?? 0.0;

    final slideAnim = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: barAnimController, curve: Curves.easeOutCubic));

    final fadeAnim = CurvedAnimation(parent: barAnimController, curve: Curves.easeOut);

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C896).withValues(alpha: 0.10),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Teal glow seam
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x8000C896), Colors.transparent],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // LEFT: Category icon + name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(selectedCategory,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          Container(
                            height: 2,
                            width: selectedCategory.length * 8.0,
                            margin: const EdgeInsets.only(top: 2),
                            color: const Color(0xFF00C896),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // CENTER: Two stat chips
                      Row(
                        children: [
                          _buildStatChip('₹${_formatAmount(todayTotal)}', 'today', const Color(0xFF00C896)),
                          const SizedBox(width: 8),
                          _buildStatChip('₹${_formatAmount(monthTotal)}', 'this month', Colors.white),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // RIGHT: Close button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                        tooltip: 'Clear filter',
                        onPressed: onClearFilter,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00C896).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Quick Add Tiles ──────────────────────────────────────────────────────────

class _QuickAddTiles extends ConsumerWidget {
  final int selectedCategoryIndex;
  final bool isCategorySelected;
  final void Function(int index) onCategoryTap;

  const _QuickAddTiles({
    this.selectedCategoryIndex = -1,
    this.isCategorySelected = false,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ExpenseModel.categories.length,
        itemBuilder: (context, index) {
          final cat = ExpenseModel.categories[index];
          final color = Color(int.parse('FF${cat['color']}', radix: 16));
          final isSelected = index == selectedCategoryIndex;
          final isDimmed = isCategorySelected && !isSelected;

          return GestureDetector(
            onTap: () => onCategoryTap(index),
            onLongPress: () {
              // Long press opens full AddExpense sheet
              _showAddExpenseSheet(
                context, ref,
                presetCategory: cat['name'],
                presetIcon: cat['icon'],
                presetColor: cat['color'],
                presetAmount: cat['defaultAmount'],
              );
            },
            child: AnimatedOpacity(
              opacity: isDimmed ? 0.45 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                transform: isSelected
                    ? (Matrix4.identity()..scale(1.04, 1.04))
                    : Matrix4.identity(),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00C896).withValues(alpha: 0.08)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00C896)
                        : color.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00C896).withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      (cat['name'] as String).length > 8
                          ? '${(cat['name'] as String).substring(0, 7)}…'
                          : cat['name'],
                      style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Teal dot indicator for active
                    if (isSelected)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C896),
                          shape: BoxShape.circle,
                        ),
                      )
                    else if ((cat['defaultAmount'] as double) > 0)
                      Text('₹${(cat['defaultAmount'] as double).toInt()}',
                          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

// ── Expense Row ──────────────────────────────────────────────────────────────

class _ExpenseRow extends ConsumerWidget {
  final ExpenseModel expense;
  const _ExpenseRow({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('h:mm a').format(expense.date);
    final color = Color(int.parse('FF${expense.categoryColor}', radix: 16));

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4444)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Delete Expense?', style: TextStyle(color: Colors.white)),
            content: Text('Remove ₹${_formatAmount(expense.amount)} for ${expense.category}?',
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete', style: TextStyle(color: Color(0xFFFF4444)))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await ExpenseService.deleteExpense(expense.id, expense.monthKey);
        ref.read(_refreshTrigger.notifier).state++;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(expense.categoryIcon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (expense.note.isNotEmpty)
                    Text(expense.note, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${_formatAmount(expense.amount)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(_monthExpensesProvider);
    final date = ref.watch(_selectedDateProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(date);

    return Column(
      children: [
        // ── Month Navigation ─────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryTeal),
                onPressed: () {
                  final prev = DateTime(date.year, date.month - 1, 1);
                  ref.read(_selectedDateProvider.notifier).state = prev;
                },
              ),
              Text(monthLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    color: date.month == DateTime.now().month && date.year == DateTime.now().year
                        ? AppColors.textTertiary
                        : AppColors.primaryTeal),
                onPressed: () {
                  final now = DateTime.now();
                  if (date.month < now.month || date.year < now.year) {
                    final next = DateTime(date.year, date.month + 1, 1);
                    ref.read(_selectedDateProvider.notifier).state = next;
                  }
                },
              ),
            ],
          ),
        ),

        // ── Expense List ─────────────────────────────────
        Expanded(
          child: expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No expenses in $monthLabel',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ],
                  ),
                );
              }

              // Group by date
              final Map<String, List<ExpenseModel>> grouped = {};
              for (final e in expenses) {
                final key = DateFormat('yyyy-MM-dd').format(e.date);
                grouped.putIfAbsent(key, () => []).add(e);
              }

              final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedKeys.length,
                itemBuilder: (_, idx) {
                  final dayKey = sortedKeys[idx];
                  final dayExpenses = grouped[dayKey]!;
                  final dayTotal = dayExpenses.fold(0.0, (s, e) => s + e.amount);
                  final dayDate = DateTime.parse(dayKey);
                  final dayLabel = DateFormat('EEE, d MMM').format(dayDate);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dayLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            Text('₹${_formatAmount(dayTotal)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
                          ],
                        ),
                      ),
                      ...dayExpenses.map((e) => _ExpenseRow(expense: e)),
                      if (idx < sortedKeys.length - 1)
                        const Divider(color: Color(0xFF1F2937), height: 16),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
            error: (_, __) => const Center(child: Text('Failed to load history', style: TextStyle(color: AppColors.textSecondary))),
          ),
        ),
      ],
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_monthlySummaryProvider);
    final budgetAsync = ref.watch(_monthlyBudgetProvider);

    return summaryAsync.when(
      data: (summary) {
        final byCategory = summary['by_category'] as Map<String, double>;
        final dailyTotals = summary['daily_totals'] as Map<String, double>;
        final totalSpent = summary['total_spent'] as double;
        final budget = budgetAsync.valueOrNull ?? 10000;

        if (totalSpent == 0) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📈', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Add expenses to see analytics',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            // Category breakdown
            const Text('SPENDING BY CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textTertiary, letterSpacing: 1)),
            const SizedBox(height: 12),
            _CategoryChart(byCategory: byCategory, total: totalSpent),
            const SizedBox(height: 24),

            // Daily bars
            const Text('DAILY SPENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textTertiary, letterSpacing: 1)),
            const SizedBox(height: 12),
            _DailyChart(dailyTotals: dailyTotals, dailyBudget: budget / 30),
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      error: (_, __) => const Center(child: Text('Analytics unavailable', style: TextStyle(color: AppColors.textSecondary))),
    );
  }
}

// ── Category Pie Chart ───────────────────────────────────────────────────────

class _CategoryChart extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;

  const _CategoryChart({required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sorted.take(6).map((entry) {
                  final cat = ExpenseModel.categories.firstWhere(
                    (c) => c['name'] == entry.key,
                    orElse: () => {'color': 'D3D3D3', 'icon': '📦'},
                  );
                  final color = Color(int.parse('FF${cat['color']}', radix: 16));
                  final pct = total > 0 ? (entry.value / total * 100) : 0;

                  return PieChartSectionData(
                    value: entry.value,
                    color: color,
                    radius: 28,
                    title: '${pct.round()}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          ...sorted.take(6).map((entry) {
            final cat = ExpenseModel.categories.firstWhere(
              (c) => c['name'] == entry.key,
              orElse: () => {'color': 'D3D3D3', 'icon': '📦'},
            );
            final color = Color(int.parse('FF${cat['color']}', radix: 16));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                  Text('₹${_formatAmount(entry.value)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Daily Bar Chart ──────────────────────────────────────────────────────────

class _DailyChart extends StatelessWidget {
  final Map<String, double> dailyTotals;
  final double dailyBudget;

  const _DailyChart({required this.dailyTotals, required this.dailyBudget});

  @override
  Widget build(BuildContext context) {
    // Show last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(d);
    });

    final maxVal = dailyTotals.values.fold(dailyBudget, (a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal,
          barGroups: days.asMap().entries.map((entry) {
            final amount = dailyTotals[entry.value] ?? 0;
            final isOverBudget = amount > dailyBudget;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: isOverBudget ? const Color(0xFFFF4444) : AppColors.primaryTeal,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < days.length) {
                    final d = DateTime.parse(days[idx]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFormat('E').format(d).substring(0, 2),
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: dailyBudget,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Expense Bottom Sheet ─────────────────────────────────────────────────

void _showAddExpenseSheet(
  BuildContext context,
  WidgetRef ref, {
  String? presetCategory,
  String? presetIcon,
  String? presetColor,
  double? presetAmount,
}) {
  final amountController = TextEditingController(
    text: presetAmount != null && presetAmount > 0 ? presetAmount.toStringAsFixed(0) : '',
  );
  final noteController = TextEditingController();
  String selectedCategory = presetCategory ?? ExpenseModel.categories[0]['name'];
  String selectedIcon = presetIcon ?? ExpenseModel.categories[0]['icon'];
  String selectedColor = presetColor ?? ExpenseModel.categories[0]['color'];
  DateTime selectedDate = ref.read(_selectedDateProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111111),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final color = Color(int.parse('FF$selectedColor', radix: 16));
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(
                    color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),

                // Category + icon
                Row(
                  children: [
                    Text(selectedIcon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(selectedCategory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),

                // Category selector (only if no preset)
                if (presetCategory == null) ...[
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ExpenseModel.categories.map((cat) {
                        final isSelected = cat['name'] == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedCategory = cat['name'];
                              selectedIcon = cat['icon'];
                              selectedColor = cat['color'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? color : const Color(0xFF333333)),
                            ),
                            child: Text('${cat['icon']} ${cat['name']}',
                                style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white54)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: presetAmount == null || presetAmount == 0,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                TextField(
                  controller: noteController,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add note (optional)',
                    hintStyle: const TextStyle(color: Color(0xFF555555)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Date selector
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryTeal, surface: Color(0xFF1A1A1A))),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryTeal),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, d MMM yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final amount = parseAmount(amountController.text);
                      if (amount <= 0) return;

                      HapticFeedback.mediumImpact();

                      final now = DateTime.now();
                      final expenseDate = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        now.hour, now.minute, now.second,
                      );
                      final monthKey = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

                      final expense = ExpenseModel(
                        id: '${DateTime.now().millisecondsSinceEpoch}',
                        category: selectedCategory,
                        categoryIcon: selectedIcon,
                        categoryColor: selectedColor,
                        amount: amount,
                        note: noteController.text.trim(),
                        date: expenseDate,
                        monthKey: monthKey,
                      );

                      await ExpenseService.addExpense(expense);
                      ref.read(_refreshTrigger.notifier).state++;

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ── Formatting ───────────────────────────────────────────────────────────────

String _formatAmount(double amount) {
  if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
