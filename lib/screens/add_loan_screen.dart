import 'package:flutter/material.dart';
import 'package:flutter_common/common_il8n.dart';
import 'package:flutter_common/models/user/user.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../models/loan.dart';

class AddLoanScreen extends StatefulWidget {
  final User user;
  const AddLoanScreen({super.key, required this.user});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _termController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final _paymentDayController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  RepaymentType _selectedRepaymentType = RepaymentType.equalInstallment;
  bool _isLoading = false;
  bool _isTermInYears = false; // 년/개월 선택 상태

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _termController.dispose();
    _initialPaymentController.dispose();
    _paymentDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Tr.loan.addLoan),
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
                    // 대출명
                    _buildTextField(
                      controller: _nameController,
                      label: '대출명',
                      hint: '예: 주택담보대출, 신용대출',
                      icon: Icons.account_balance,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '대출명을 입력해주세요';
                        }
                        if (value.trim().length < 2) {
                          return '대출명은 2자 이상 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 대출금액
                    _buildTextField(
                      controller: _amountController,
                      label: '대출금액',
                      hint: '10000000',
                      icon: Icons.attach_money,
                      suffixText: '원',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '대출금액을 입력해주세요';
                        }
                        final amount = double.tryParse(
                          value.replaceAll(',', ''),
                        );
                        if (amount == null) {
                          return '올바른 금액을 입력해주세요';
                        }
                        if (amount < 1000000) {
                          return '최소 100만원 이상 입력해주세요';
                        }
                        if (amount > 1000000000000) {
                          return '최대 1조원까지 입력 가능합니다';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // 천 단위 콤마 추가
                        if (value.isNotEmpty) {
                          final number = int.tryParse(
                            value.replaceAll(',', ''),
                          );
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

                    // 이율
                    _buildTextField(
                      controller: _interestRateController,
                      label: '연 이율',
                      hint: '3.5',
                      icon: Icons.percent,
                      suffixText: '%',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이율을 입력해주세요';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null) {
                          return '올바른 이율을 입력해주세요';
                        }
                        if (rate < 0) {
                          return '이율은 0% 이상이어야 합니다';
                        }
                        if (rate > 30) {
                          return '이율은 30% 이하여야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 대출 기간
                    // 대출 기간 (년/개월 선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              Tr.loan.loanPeriod,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _termController,
                                decoration: InputDecoration(
                                  hintText: _isTermInYears ? '30' : '360',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '대출 기간을 입력해주세요';
                                  }
                                  final term = int.tryParse(value);
                                  if (term == null) {
                                    return '올바른 기간을 입력해주세요';
                                  }
                                  if (term < 1) {
                                    return '대출 기간은 1 이상이어야 합니다';
                                  }
                                  if (_isTermInYears && term > 50) {
                                    return '대출 기간은 50년 이하여야 합니다';
                                  }
                                  if (!_isTermInYears && term > 600) {
                                    return '대출 기간은 600개월 이하여야 합니다';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // 년으로 입력된 경우 자동으로 개월로 변환하여 저장
                                  if (_isTermInYears && value.isNotEmpty) {
                                    final years = int.tryParse(value);
                                    if (years != null) {
                                      final months = years * 12;
                                      // 컨트롤러 값은 변경하지 않고 내부적으로만 계산
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<bool>(
                                value: _isTermInYears,
                                underline: Container(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text(Tr.loan.months),
                                  ),
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text(Tr.loan.year),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _isTermInYears = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // D-Day 선택
                    _buildDateSelector(),
                    const SizedBox(height: 16),

                    // 상환 방식
                    _buildRepaymentTypeSelector(),
                    const SizedBox(height: 16),

                    // 상환일 (선택사항)
                    _buildPaymentDaySelector(),
                    const SizedBox(height: 16),

                    // 초기 납부금 (선택사항)
                    _buildTextField(
                      controller: _initialPaymentController,
                      label: '초기 납부금 (선택사항)',
                      hint: '계약금, 선이자 등',
                      icon: Icons.payment,
                      suffixText: '원',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = double.tryParse(
                            value.replaceAll(',', ''),
                          );
                          if (amount == null || amount < 0) {
                            return '올바른 금액을 입력해주세요';
                          }
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // 천 단위 콤마 추가
                        if (value.isNotEmpty) {
                          final number = int.tryParse(
                            value.replaceAll(',', ''),
                          );
                          if (number != null) {
                            final formatted = _formatNumber(number);
                            if (formatted != value) {
                              _initialPaymentController.value =
                                  TextEditingValue(
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // 저장 버튼
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLoan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
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
                    : Text(
                        Tr.loan.addLoan,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixText: suffixText,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(1997),
          lastDate: DateTime(2030),
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
              'D-Day: ${_formatDate(_selectedDate)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentTypeSelector() {
    return DropdownButtonFormField<RepaymentType>(
      value: _selectedRepaymentType,
      decoration: InputDecoration(
        labelText: Tr.loan.repaymentMethod,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      items: RepaymentType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type.displayName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRepaymentType = value!;
        });
      },
    );
  }

  Widget _buildPaymentDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              Tr.loan.repaymentDate + ' ' + Tr.loan.optional,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<int>(
                  value: _paymentDayController.text.isNotEmpty
                      ? int.parse(_paymentDayController.text)
                      : null,
                  decoration: InputDecoration(
                    hintText: Tr.loan.repaymentDate,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: List.generate(31, (index) => index + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text('$day${Tr.loan.day}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        _paymentDayController.text = value.toString();
                      } else {
                        _paymentDayController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value != null) {
                      if (value < 1 || value > 31) {
                        return Tr.loan.repaymentMethodDescription;
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_paymentDayController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  setState(() {
                    _paymentDayController.clear();
                  });
                },
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.all(12),
                ),
              ),
          ],
        ),
        if (_paymentDayController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              Tr.loan.repaymentDateDescription,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  void _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 대출 기간을 개월 단위로 변환
        int termInMonths;
        if (_isTermInYears) {
          // 년으로 입력된 경우 개월로 변환
          final years = int.parse(_termController.text);
          termInMonths = years * 12;
        } else {
          // 개월로 입력된 경우 그대로 사용
          termInMonths = int.parse(_termController.text);
        }

        final loan = Loan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          interestRate: double.parse(_interestRateController.text),
          term: termInMonths, // 변환된 개월 단위 사용
          startDate: _selectedDate,
          repaymentType: _selectedRepaymentType,
          initialPayment: _initialPaymentController.text.isNotEmpty
              ? double.parse(_initialPaymentController.text.replaceAll(',', ''))
              : null,
          paymentDay: _paymentDayController.text.isNotEmpty
              ? int.parse(_paymentDayController.text)
              : null,
        );

        await context.read<LoanProvider>().addLoan(loan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Tr.loan.loanAddSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Tr.loan.error + ': $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
