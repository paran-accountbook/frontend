import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../dutch/data/dutch_pay_service.dart';
import '../../dutch/presentation/dutch_people_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';

class ExpenseRegistrationCompleteScreen extends StatefulWidget {
  const ExpenseRegistrationCompleteScreen({
    required this.expenseId,
    required this.financeService,
    super.key,
    this.dutchPayService,
  });

  final String expenseId;
  final FinanceService financeService;
  final DutchPayService? dutchPayService;

  @override
  State<ExpenseRegistrationCompleteScreen> createState() =>
      _ExpenseRegistrationCompleteScreenState();
}

class _ExpenseRegistrationCompleteScreenState
    extends State<ExpenseRegistrationCompleteScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _startDutchPay() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = widget.dutchPayService ?? AppServices.dutchPay;
      final entry = await service.entry(widget.expenseId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchPeopleScreen.fromEntry(
            entry: entry,
            dutchPayService: service,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _close() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LedgerScreen(financeService: widget.financeService),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          const Positioned(
            left: 24,
            right: 24,
            top: 300,
            child: Text(
              '등록이 완료되었습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_error case final message?)
            Positioned(
              left: 24,
              right: 24,
              top: 370,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 108,
            child: FilledButton(
              onPressed: _isLoading ? null : _startDutchPay,
              child: Text(_isLoading ? '불러오는 중...' : '더치페이 하기'),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: OutlinedButton(onPressed: _close, child: const Text('닫기')),
          ),
        ],
      ),
    ),
  );
}
