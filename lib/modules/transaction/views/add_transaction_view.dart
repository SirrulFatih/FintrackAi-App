import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/app_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/transaction_controller.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TransactionController _controller = Get.find<TransactionController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late final TransactionModel? _editingTransaction;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _editingTransaction = Get.arguments as TransactionModel?;
    final TransactionModel? transaction = _editingTransaction;
    _controller.initializeForm(_editingTransaction);
    _titleController.text = transaction?.title ?? '';
    _amountController.text = transaction == null
        ? ''
        : transaction.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate.value,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );

    if (pickedDate != null) {
      _controller.setDate(pickedDate);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _controller.isSaving.value) {
      return;
    }

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final bool success;
    try {
      success = await _controller.submit(
        existingTransaction: _editingTransaction,
        title: _titleController.text,
        amountInput: _amountController.text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    if (success) {
      Get.offAllNamed<void>(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = _editingTransaction != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Transaksi' : 'Transaksi Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              _SectionLabel(
                title: 'Detail',
                subtitle: isEdit
                    ? 'Perbarui catatan transaksi yang sudah ada.'
                    : 'Masukkan catatan keuangan dengan data yang jelas.',
              ),
              const SizedBox(height: 14),
              Obx(
                () => SegmentedButton<TransactionType>(
                  segments: const <ButtonSegment<TransactionType>>[
                    ButtonSegment<TransactionType>(
                      value: TransactionType.expense,
                      icon: Icon(Icons.arrow_downward_rounded),
                      label: Text('Keluar'),
                    ),
                    ButtonSegment<TransactionType>(
                      value: TransactionType.income,
                      icon: Icon(Icons.arrow_upward_rounded),
                      label: Text('Masuk'),
                    ),
                  ],
                  selected: <TransactionType>{_controller.selectedType.value},
                  onSelectionChanged: (Set<TransactionType> value) {
                    _controller.setType(value.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Contoh: Uang Jajan',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  hintText: 'Contoh: 1500000 atau 1.500.000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal wajib diisi.';
                  }
                  if (AppFormatter.parseCurrencyInput(value) == null) {
                    return 'Nominal harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder:
                    (
                      BuildContext context,
                      TextEditingValue value,
                      Widget? child,
                    ) {
                      final double? amount = AppFormatter.parseCurrencyInput(
                        value.text,
                      );
                      return Text(
                        'Preview ${AppFormatter.currency(amount ?? 0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
              ),
              const SizedBox(height: 18),
              Obx(
                () => _DatePickerTile(
                  date: _controller.selectedDate.value,
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final bool isBusy = _isSubmitting || _controller.isSaving.value;
                return FilledButton.icon(
                  onPressed: isBusy ? null : _submit,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi'),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onPressed});

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_month_outlined,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Tanggal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppFormatter.date(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
