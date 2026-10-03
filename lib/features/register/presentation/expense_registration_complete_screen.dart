import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
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
    this.storeName,
    this.totalAmount,
    this.showDutchPay = true,
  });

  final String expenseId;
  final FinanceService financeService;
  final DutchPayService? dutchPayService;
  final String? storeName;
  final int? totalAmount;
  final bool showDutchPay;

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
          Positioned(
            left: 184,
            top: 344,
            width: 34,
            height: 34,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.main,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(7),
              child: SvgPicture.asset(
                AppAssets.checkLight,
                colorFilter: const ColorFilter.mode(
                  AppColors.background,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            top: 401,
            child: Text(
              '저장이 완료되었어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 445,
            child: Text(
              '${widget.storeName ?? '가맹점'} · ${_formatAmount(widget.totalAmount ?? 0)}원',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text50, fontSize: 12),
            ),
          ),
          if (_error case final message?)
            Positioned(
              left: 24,
              right: 24,
              top: 485,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
              ),
            ),
          if (widget.showDutchPay)
            Positioned(
              left: 24,
              right: 24,
              bottom: 108,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _startDutchPay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(_isLoading ? '불러오는 중...' : '더치페이 하기'),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            height: 56,
            child: widget.showDutchPay
                ? OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.text20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('가계부로 돌아가기'),
                  )
                : FilledButton(
                    onPressed: _close,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.main,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('가계부로 돌아가기'),
                  ),
          ),
        ],
      ),
    ),
  );
}

String _formatAmount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
