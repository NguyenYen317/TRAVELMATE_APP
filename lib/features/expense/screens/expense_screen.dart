import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense_item.dart';
import '../../trip/models/trip_models.dart';
import '../../trip/providers/trip_planner_provider.dart';
import '../providers/expense_provider.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key, this.tripId});

  final String? tripId;

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  static const Map<String, String> _typeLabels = {
    'All': 'Tất cả',
    'Food': 'Ăn uống',
    'Transport': 'Di chuyển',
    'Stay': 'Lưu trú',
    'Ticket': 'Vé',
    'Shopping': 'Mua sắm',
    'Other': 'Khác',
  };

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  String _type = 'Food';
  DateTime? _expenseDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TripPlannerProvider, ExpenseProvider>(
      builder: (context, tripProvider, expenseProvider, _) {
        final trip = tripProvider.trips
            .where(
              (item) => item.id == (widget.tripId ?? tripProvider.activeTripId),
            )
            .firstOrNull;

        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi phí')),
            body: const Center(
              child: Text('Không tìm thấy chuyến đi để quản lý chi phí.'),
            ),
          );
        }

        final expenses = expenseProvider.filteredExpensesByTrip(trip.id);
        final total = expenseProvider.totalByTrip(trip.id);

        return Scaffold(
          appBar: AppBar(title: Text('Chi phí - ${trip.title}')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _buildSummaryCard(total),
              const SizedBox(height: 12),
              _buildFilterCard(context, expenseProvider, trip),
              const SizedBox(height: 12),
              _buildAddExpenseCard(context, expenseProvider, trip),
              const SizedBox(height: 12),
              _buildExpenseList(context, expenseProvider, expenses, trip),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng chi phí',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${total.toStringAsFixed(0)} VND',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    ExpenseProvider provider,
    Trip trip,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bộ lọc', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: provider.filterType,
                    decoration: const InputDecoration(
                      labelText: 'Loại chi phí',
                    ),
                    items: ExpenseProvider.types
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(_typeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      provider.setFilterType(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: _onlyDate(trip.startDate),
                      lastDate: _onlyDate(trip.endDate),
                      initialDate: _clampDate(
                        provider.filterDate ?? _effectiveExpenseDate(trip),
                        trip.startDate,
                        trip.endDate,
                      ),
                    );
                    provider.setFilterDate(picked);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    provider.filterDate == null
                        ? 'Tất cả ngày'
                        : _fmtDate(provider.filterDate!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                provider.setFilterType('All');
                provider.setFilterDate(null);
              },
              child: const Text('Xoá bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseCard(
    BuildContext context,
    ExpenseProvider provider,
    Trip trip,
  ) {
    final effectiveDate = _effectiveExpenseDate(trip);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm chi phí',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Nội dung'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
              ],
              decoration: const InputDecoration(labelText: 'Số tiền'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Loại'),
              items: ExpenseProvider.types
                  .where((item) => item != 'All')
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(_typeLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _type = value;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: _onlyDate(trip.startDate),
                        lastDate: _onlyDate(trip.endDate),
                        initialDate: _clampDate(
                          effectiveDate,
                          trip.startDate,
                          trip.endDate,
                        ),
                      );
                      if (picked == null) {
                        return;
                      }
                      setState(() {
                        _expenseDate = picked;
                      });
                    },
                    icon: const Icon(Icons.event),
                    label: Text(_fmtDate(effectiveDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () async {
                final title = _titleCtrl.text.trim();
                final amount = _parseAmount(_amountCtrl.text);

                if (title.isEmpty || amount == null || amount <= 0) {
                  _showSnack(context, 'Nhập đúng nội dung và số tiền > 0.');
                  return;
                }

                await provider.addExpense(
                  tripId: trip.id,
                  title: title,
                  amount: amount,
                  type: _type,
                  date: _clampDate(effectiveDate, trip.startDate, trip.endDate),
                  note: _noteCtrl.text,
                );

                _titleCtrl.clear();
                _amountCtrl.clear();
                _noteCtrl.clear();
                setState(() {
                  _expenseDate = null;
                  _type = 'Food';
                });
              },
              child: const Text('Thêm chi phí'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(
    BuildContext context,
    ExpenseProvider provider,
    List<ExpenseItem> expenses,
    Trip trip,
  ) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có chi phí với bộ lọc hiện tại.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: expenses
              .map(
                (item) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(item.title),
                  subtitle: Text(
                    '${_typeLabel(item.type)} • ${_fmtDate(item.date)}\n${item.amount.toStringAsFixed(0)} VND${item.note == null ? '' : ' • ${item.note}'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa chi phí',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          await _showEditExpenseSheet(
                            context,
                            provider,
                            item,
                            trip,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Xoá chi phí',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Xoá chi phí'),
                                content: const Text(
                                  'Bạn có chắc muốn xoá chi phí này?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Huỷ'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Xoá'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldDelete == true) {
                            await provider.deleteExpense(item.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _fmtDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    // Accept common Vietnamese formats: 1000000, 1.000.000, 1,000,000
    final thousandNormalized = normalized
        .replaceAll('.', '')
        .replaceAll(',', '');
    return double.tryParse(thousandNormalized);
  }

  String _typeLabel(String value) {
    return _typeLabels[value] ?? value;
  }

  DateTime _onlyDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampDate(DateTime value, DateTime start, DateTime end) {
    final d = _onlyDate(value);
    final min = _onlyDate(start);
    final max = _onlyDate(end);
    if (d.isBefore(min)) {
      return min;
    }
    if (d.isAfter(max)) {
      return max;
    }
    return d;
  }

  DateTime _effectiveExpenseDate(Trip trip) {
    final base = _expenseDate ?? DateTime.now();
    return _clampDate(base, trip.startDate, trip.endDate);
  }

  Future<void> _showEditExpenseSheet(
    BuildContext context,
    ExpenseProvider provider,
    ExpenseItem item,
    Trip trip,
  ) async {
    final titleCtrl = TextEditingController(text: item.title);
    final amountCtrl = TextEditingController(
      text: item.amount.toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController(text: item.note ?? '');
    var type = item.type;
    var date = item.date;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setModalState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa chi phí'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Nội dung'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                      ],
                      decoration: const InputDecoration(labelText: 'Số tiền'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Loại'),
                      items: ExpenseProvider.types
                          .where((value) => value != 'All')
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_typeLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          type = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: localContext,
                          firstDate: _onlyDate(trip.startDate),
                          lastDate: _onlyDate(trip.endDate),
                          initialDate: _clampDate(
                            date,
                            trip.startDate,
                            trip.endDate,
                          ),
                        );
                        if (picked == null) {
                          return;
                        }
                        setModalState(() {
                          date = picked;
                        });
                      },
                      icon: const Icon(Icons.event),
                      label: Text(_fmtDate(date)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  onPressed: () async {
                    final parsedAmount = _parseAmount(amountCtrl.text);
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty ||
                        parsedAmount == null ||
                        parsedAmount <= 0) {
                      _showSnack(context, 'Nhập đúng nội dung và số tiền > 0.');
                      return;
                    }

                    await provider.updateExpense(
                      expenseId: item.id,
                      title: title,
                      amount: parsedAmount,
                      type: type,
                      date: _clampDate(date, trip.startDate, trip.endDate),
                      note: noteCtrl.text,
                    );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

extension _IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
