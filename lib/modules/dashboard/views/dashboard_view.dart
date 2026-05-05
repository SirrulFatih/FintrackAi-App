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
                      _InsightStrip(
                        transactionCount: controller.transactions.length,
                        topExpenseCategory: controller.topExpenseCategory,
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
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Transaksi',
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
                      itemCount: visibleTransactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final TransactionModel transaction =
                            visibleTransactions[index];
                        return Dismissible(
                          key: ValueKey<String>(transaction.id),
                          direction: DismissDirection.endToStart,
                          background: const _DeleteBackground(),
                          confirmDismiss: (_) => _confirmDelete(context),
                          onDismissed: (_) {
                            controller.deleteTransaction(transaction.id);
                          },
                          child: _TransactionTile(transaction: transaction),
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

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.transactionCount,
    required this.topExpenseCategory,
  });

  final int transactionCount;
  final String? topExpenseCategory;

  @override
  Widget build(BuildContext context) {
    final String insight = topExpenseCategory == null
        ? 'Belum ada kategori pengeluaran dominan.'
        : 'Pengeluaran terbesar ada di $topExpenseCategory.';

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
        hintText: 'Cari judul atau kategori',
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  IconData _categoryIcon(String category) {
    final String value = category.toLowerCase();
    if (value.contains('makan')) return Icons.restaurant_rounded;
    if (value.contains('transport')) return Icons.directions_car_rounded;
    if (value.contains('gaji')) return Icons.payments_rounded;
    if (value.contains('belanja')) return Icons.shopping_bag_rounded;
    if (value.contains('tagihan')) return Icons.request_quote_rounded;
    if (value.contains('hiburan')) return Icons.movie_rounded;
    return Icons.category_rounded;
  }

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
          child: Icon(_categoryIcon(transaction.category), color: amountColor),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${transaction.category} | ${AppFormatter.compactDate(transaction.date)}',
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
