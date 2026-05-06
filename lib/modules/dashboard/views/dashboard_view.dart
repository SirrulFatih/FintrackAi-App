import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/app_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../../modules/transaction/controllers/transaction_controller.dart';
import '../../../routes/app_routes.dart';

class DashboardPage extends GetView<TransactionController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack AI'),
        actions: <Widget>[
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.chatbot),
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Asisten AI',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final List<TransactionModel> visibleTransactions =
              controller.filteredTransactions;
          final List<TransactionGroup> groupedTransactions =
              controller.groupedTransactions;

          return RefreshIndicator(
            onRefresh: controller.loadTransactions,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList.list(
                    children: <Widget>[
                      _OverviewPanel(
                        balance: controller.balance,
                        savingsRate: controller.savingsRate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _MetricTile(
                              title: 'Pemasukan',
                              value: AppFormatter.currency(
                                controller.totalIncome,
                              ),
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.income,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              title: 'Pengeluaran',
                              value: AppFormatter.currency(
                                controller.totalExpense,
                              ),
                              icon: Icons.trending_down_rounded,
                              color: AppTheme.expense,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TodayExpenseBanner(
                        date: DateTime.now(),
                        total: controller.todayExpenseTotal,
                      ),
                      const SizedBox(height: 10),
                      _DailyExpenseChart(totals: controller.dailyExpenseTotals),
                      const SizedBox(height: 10),
                      _InsightStrip(
                        transactionCount: controller.transactions.length,
                        balance: controller.balance,
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        onChanged: controller.setSearchQuery,
                        onClear: () => controller.setSearchQuery(''),
                      ),
                      const SizedBox(height: 12),
                      _FilterBar(
                        selectedType: controller.activeType.value,
                        onChanged: controller.setActiveType,
                      ),
                      const SizedBox(height: 12),
                      _PeriodSelector(
                        selectedPeriod: controller.selectedPeriod.value,
                        onChanged: controller.setPeriod,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Transaksi per ${controller.selectedPeriod.value.label.toLowerCase()}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: controller.loadTransactions,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Muat ulang',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading.value &&
                    controller.transactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visibleTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyTransactions(
                      hasTransactions: controller.transactions.isNotEmpty,
                      onAddPressed: () => Get.toNamed(AppRoutes.addTransaction),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: groupedTransactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (BuildContext context, int index) {
                        final TransactionGroup group =
                            groupedTransactions[index];

                        return _TransactionGroupSection(
                          group: group,
                          onConfirmDelete: () => _confirmDelete(context),
                          onDelete: controller.deleteTransaction,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addTransaction),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Transaksi'),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: const Text('Data yang dihapus tidak bisa dikembalikan.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.balance, required this.savingsRate});

  final double balance;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = balance >= 0;
    final Color statusColor = isHealthy ? AppTheme.income : AppTheme.expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saldo saat ini',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  isHealthy ? 'Sehat' : 'Defisit',
                  style: TextStyle(
                    color: isHealthy ? const Color(0xFFA7F3D0) : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatter.currency(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: savingsRate,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rasio tabungan ${(savingsRate * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayExpenseBanner extends StatelessWidget {
  const _TodayExpenseBanner({required this.date, required this.total});

  final DateTime date;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.expense.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.expense.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.today_rounded, color: AppTheme.expense),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Keluar hari ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppFormatter.date(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppFormatter.currency(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.expense,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyExpenseChart extends StatelessWidget {
  const _DailyExpenseChart({required this.totals});

  final List<DailyExpenseTotal> totals;

  @override
  Widget build(BuildContext context) {
    final List<DailyExpenseTotal> visibleTotals = totals.length > 14
        ? totals.sublist(totals.length - 14)
        : totals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Grafik Pengeluaran Harian',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (visibleTotals.isNotEmpty)
                  Text(
                    '${visibleTotals.length} hari',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleTotals.isEmpty)
              SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Belum ada pengeluaran',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 190,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double chartWidth = math.max(
                      constraints.maxWidth,
                      visibleTotals.length * 56,
                    );

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CustomPaint(
                        size: Size(chartWidth, constraints.maxHeight),
                        painter: _DailyExpenseChartPainter(
                          totals: visibleTotals,
                          textStyle: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyExpenseChartPainter extends CustomPainter {
  const _DailyExpenseChartPainter({
    required this.totals,
    required this.textStyle,
  });

  final List<DailyExpenseTotal> totals;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (totals.isEmpty) {
      return;
    }

    final double maxTotal = totals
        .map((DailyExpenseTotal item) => item.total)
        .reduce(math.max);
    final double chartMax = maxTotal <= 0 ? 1 : maxTotal;
    const double top = 12;
    const double bottomLabelHeight = 42;
    const double left = 8;
    const double right = 8;
    final double chartBottom = size.height - bottomLabelHeight;
    final double chartHeight = chartBottom - top;
    final double chartWidth = size.width - left - right;
    final double slotWidth = chartWidth / totals.length;

    final Paint gridPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1;
    final Paint barPaint = Paint()..color = AppTheme.expense;
    final Paint mutedBarPaint = Paint()
      ..color = AppTheme.expense.withValues(alpha: 0.32);

    for (int i = 0; i <= 3; i++) {
      final double y = top + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    for (int index = 0; index < totals.length; index++) {
      final DailyExpenseTotal item = totals[index];
      final double normalizedHeight = (item.total / chartMax) * chartHeight;
      final double barWidth = math.min(30, slotWidth * 0.52);
      final double x =
          left + (slotWidth * index) + ((slotWidth - barWidth) / 2);
      final double barTop = chartBottom - normalizedHeight;
      final RRect rect = RRect.fromLTRBR(
        x,
        barTop,
        x + barWidth,
        chartBottom,
        const Radius.circular(5),
      );

      canvas.drawRRect(rect, item.total == maxTotal ? barPaint : mutedBarPaint);
      _paintText(
        canvas,
        text: AppFormatter.compactDate(item.date),
        center: Offset(x + (barWidth / 2), chartBottom + 14),
        maxWidth: slotWidth,
        color: AppTheme.muted,
      );
    }
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double maxWidth,
    required Color color,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: (textStyle ?? const TextStyle(fontSize: 11)).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, Offset(center.dx - (painter.width / 2), center.dy));
  }

  @override
  bool shouldRepaint(covariant _DailyExpenseChartPainter oldDelegate) {
    return oldDelegate.totals != totals || oldDelegate.textStyle != textStyle;
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.transactionCount, required this.balance});

  final int transactionCount;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final String insight = balance >= 0
        ? 'Saldo kamu masih positif.'
        : 'Pengeluaran sudah melewati pemasukan.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.insights_rounded, color: Color(0xFF8A5A10)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$transactionCount transaksi tercatat. $insight',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF594019),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged, required this.onClear});

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari judul transaksi',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Bersihkan pencarian',
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedType, required this.onChanged});

  final TransactionType? selectedType;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilterChip(
          selected: selectedType == null,
          label: const Text('Semua'),
          avatar: const Icon(Icons.receipt_long_rounded, size: 18),
          onSelected: (_) => onChanged(null),
        ),
        FilterChip(
          selected: selectedType == TransactionType.income,
          label: const Text('Pemasukan'),
          avatar: const Icon(Icons.arrow_upward_rounded, size: 18),
          onSelected: (_) => onChanged(TransactionType.income),
        ),
        FilterChip(
          selected: selectedType == TransactionType.expense,
          label: const Text('Pengeluaran'),
          avatar: const Icon(Icons.arrow_downward_rounded, size: 18),
          onSelected: (_) => onChanged(TransactionType.expense),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final TransactionPeriod selectedPeriod;
  final ValueChanged<TransactionPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionPeriod>(
      segments: const <ButtonSegment<TransactionPeriod>>[
        ButtonSegment<TransactionPeriod>(
          value: TransactionPeriod.day,
          icon: Icon(Icons.calendar_view_day_rounded),
          label: Text('Hari'),
        ),
        ButtonSegment<TransactionPeriod>(
          value: TransactionPeriod.month,
          icon: Icon(Icons.calendar_view_month_rounded),
          label: Text('Bulan'),
        ),
        ButtonSegment<TransactionPeriod>(
          value: TransactionPeriod.year,
          icon: Icon(Icons.event_available_rounded),
          label: Text('Tahun'),
        ),
      ],
      selected: <TransactionPeriod>{selectedPeriod},
      onSelectionChanged: (Set<TransactionPeriod> value) {
        onChanged(value.first);
      },
    );
  }
}

class _TransactionGroupSection extends StatelessWidget {
  const _TransactionGroupSection({
    required this.group,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  final TransactionGroup group;
  final Future<bool> Function() onConfirmDelete;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final List<Widget> transactionRows = <Widget>[];

    for (final TransactionModel transaction in group.transactions) {
      if (transactionRows.isNotEmpty) {
        transactionRows.add(const SizedBox(height: 8));
      }

      transactionRows.add(
        Dismissible(
          key: ValueKey<String>(transaction.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) => onConfirmDelete(),
          onDismissed: (_) => onDelete(transaction.id),
          child: _TransactionTile(transaction: transaction),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _TransactionGroupHeader(group: group),
        const SizedBox(height: 8),
        ...transactionRows,
      ],
    );
  }
}

class _TransactionGroupHeader extends StatelessWidget {
  const _TransactionGroupHeader({required this.group});

  final TransactionGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _groupTitle(group),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${group.transactionCount} transaksi',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _GroupTotalChip(
                label: 'Keluar',
                value: AppFormatter.currency(group.totalExpense),
                color: AppTheme.expense,
                icon: Icons.arrow_downward_rounded,
              ),
              _GroupTotalChip(
                label: 'Masuk',
                value: AppFormatter.currency(group.totalIncome),
                color: AppTheme.income,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _groupTitle(TransactionGroup group) {
    return switch (group.period) {
      TransactionPeriod.day => AppFormatter.date(group.startDate),
      TransactionPeriod.month => AppFormatter.monthYear(group.startDate),
      TransactionPeriod.year => AppFormatter.year(group.startDate),
    };
  }
}

class _GroupTotalChip extends StatelessWidget {
  const _GroupTotalChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor = isIncome ? AppTheme.income : AppTheme.expense;

    return Card(
      child: ListTile(
        minLeadingWidth: 44,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () =>
            Get.toNamed(AppRoutes.editTransaction, arguments: transaction),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: amountColor.withValues(alpha: 0.12),
          child: Icon(
            isIncome
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: amountColor,
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          AppFormatter.compactDate(transaction.date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppFormatter.signedCurrency(transaction.signedAmount),
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.type.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.expense,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({
    required this.hasTransactions,
    required this.onAddPressed,
  });

  final bool hasTransactions;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  hasTransactions ? 'Tidak ada hasil' : 'Belum ada transaksi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasTransactions
                      ? 'Coba ubah kata kunci atau filter transaksi.'
                      : 'Catat pemasukan dan pengeluaran pertama untuk mulai melihat ringkasan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
                if (!hasTransactions) ...<Widget>[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Transaksi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
