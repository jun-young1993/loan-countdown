import 'package:flutter/material.dart';
import 'package:loan_countdown/utills/format_currency.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../services/loan_calculator.dart';
import '../providers/loan_provider.dart';

class PrepaymentScreen extends StatefulWidget {
  final Loan loan;

  const PrepaymentScreen({super.key, required this.loan});

  @override
  State<PrepaymentScreen> createState() => _PrepaymentScreenState();
}

class _PrepaymentScreenState extends State<PrepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PrepaymentType _selectedType = PrepaymentType.reduceAmount;
  List<MonthlyPayment>? _originalSchedule;
  List<MonthlyPayment>? _newSchedule;
  bool _isCalculating = false;
  double? _interestSavings;

  @override
  void initState() {
    super.initState();
    _loadOriginalSchedule();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _loadOriginalSchedule() {
    try {
      _originalSchedule = LoanCalculator.generatePaymentSchedule(widget.loan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('원본 상환 스케줄을 불러올 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.loan.name} - 중도금 상환'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 중도금 상환 정보 입력
                    _buildInputSection(),
                    const SizedBox(height: 24),

                    // 계산 결과 표시
                    if (_newSchedule != null) _buildResultSection(),
                  ],
                ),
              ),
            ),

            // 계산 및 적용 버튼
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCalculating ? null : _calculatePrepayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isCalculating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              '계산하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _newSchedule == null ? null : _applyPrepayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        '적용하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '중도금 상환 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 상환 날짜 선택
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(
                    widget.loan.startDate.year,
                    widget.loan.startDate.month + widget.loan.term,
                    widget.loan.startDate.day,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      '상환 날짜: ${_formatDate(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 상환 금액 입력
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '상환 금액',
                hintText: '1000000',
                border: OutlineInputBorder(),
                suffixText: '원',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상환 금액을 입력해주세요';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null) {
                  return '올바른 금액을 입력해주세요';
                }
                if (amount <= 0) {
                  return '0보다 큰 금액을 입력해주세요';
                }
                if (amount > widget.loan.amount) {
                  return '대출 원금보다 클 수 없습니다';
                }
                return null;
              },
              onChanged: (value) {
                // 천 단위 콤마 추가
                if (value.isNotEmpty) {
                  final number = int.tryParse(value.replaceAll(',', ''));
                  if (number != null) {
                    final formatted = _formatNumber(number);
                    if (formatted != value) {
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // 상환 방식 선택
            DropdownButtonFormField<PrepaymentType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '상환 방식',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: PrepaymentType.values.map((type) {
                String title, description;
                switch (type) {
                  case PrepaymentType.reduceAmount:
                    title = '금액 경감형';
                    description = '기간 동일, 월 납부금 감소';
                    break;
                  case PrepaymentType.reduceTerm:
                    title = '기간 단축형';
                    description = '월 납부금 동일, 기간 단축';
                    break;
                }

                return DropdownMenuItem(
                  value: type,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_newSchedule == null) return const SizedBox.shrink();

    final originalTotal = _originalSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.totalAmount,
    );
    final newTotal = _newSchedule!.fold(
      0.0,
      (sum, payment) => sum + payment.totalAmount,
    );
    final totalSavings = originalTotal - newTotal;
    final originalInterest = LoanCalculator.calculateTotalInterest(
      _originalSchedule!,
    );
    final newInterest = LoanCalculator.calculateTotalInterest(_newSchedule!);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '계산 결과',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 요약 정보
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    '원본 총 상환금',
                    formatCurrency(originalTotal),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    '새 총 상환금',
                    formatCurrency(newTotal),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    '총 절약액',
                    formatCurrency(totalSavings),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    '이자 절약',
                    formatCurrency(originalInterest - newInterest),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 상환 방식별 결과
            if (_selectedType == PrepaymentType.reduceAmount) ...[
              _buildResultItem(
                '월 납부금 변화',
                formatCurrency(
                  _originalSchedule!.first.totalAmount -
                      _newSchedule!.first.totalAmount,
                ),
                Colors.purple,
              ),
            ] else ...[
              _buildResultItem(
                '기간 단축',
                '${_originalSchedule!.length - _newSchedule!.length}개월 단축',
                Colors.purple,
              ),
            ],

            const SizedBox(height: 24),

            // 비교 테이블
            const Text(
              '상환 스케줄 비교',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('월')),
                  DataColumn(label: Text('원본')),
                  DataColumn(label: Text('변경 후')),
                  DataColumn(label: Text('차이')),
                ],
                rows: List.generate(_newSchedule!.length, (index) {
                  final original = index < _originalSchedule!.length
                      ? _originalSchedule![index]
                      : null;
                  final newPayment = _newSchedule![index];

                  if (original == null) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(const Text('-')),
                        DataCell(Text(formatCurrency(newPayment.totalAmount))),
                        DataCell(const Text('신규')),
                      ],
                    );
                  }

                  final difference =
                      newPayment.totalAmount - original.totalAmount;
                  final differenceText = difference >= 0
                      ? '+${formatCurrency(difference)}'
                      : formatCurrency(difference);
                  final differenceColor = difference >= 0
                      ? Colors.red
                      : Colors.green;

                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(formatCurrency(original.totalAmount))),
                      DataCell(Text(formatCurrency(newPayment.totalAmount))),
                      DataCell(
                        Text(
                          differenceText,
                          style: TextStyle(color: differenceColor),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePrepayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalSchedule == null) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final prepaymentAmount = double.parse(
        _amountController.text.replaceAll(',', ''),
      );

      final newSchedule = LoanCalculator.recalculateAfterPrepayment(
        widget.loan,
        _originalSchedule!,
        prepaymentAmount,
        _selectedDate,
        _selectedType,
      );

      final originalInterest = LoanCalculator.calculateTotalInterest(
        _originalSchedule!,
      );
      final newInterest = LoanCalculator.calculateTotalInterest(newSchedule);
      final interestSavings = originalInterest - newInterest;

      setState(() {
        _newSchedule = newSchedule;
        _interestSavings = interestSavings;
        _isCalculating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('중도금 상환 계산이 완료되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계산 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyPrepayment() {
    // TODO: 실제 대출 정보에 중도금 상환을 적용하는 로직 구현
    // 현재는 계산 결과만 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('중도금 상환이 적용되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
