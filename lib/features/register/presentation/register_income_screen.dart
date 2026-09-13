import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';

class RegisterIncomeScreen extends StatefulWidget {
  const RegisterIncomeScreen({super.key, this.financeService});
  final FinanceService? financeService;

  @override
  State<RegisterIncomeScreen> createState() => _RegisterIncomeScreenState();
}

class _RegisterIncomeScreenState extends State<RegisterIncomeScreen> {
  final _amount = TextEditingController();
  final _memo = TextEditingController();
  final _categories = const ['급여', '용돈', '부수입', '환급·환불', '기타'];
  int _category = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = '수입 금액을 입력해 주세요');
      return;
    }
    final service = widget.financeService;
    if (service == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await service.createIncome({
        'amount': amount,
        'income_date': DateTime.now().toIso8601String().substring(0, 10),
        'category': _categories[_category],
        'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LedgerScreen(financeService: service),
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
            left: 24,
            top: 50,
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(AppAssets.arrowBackLight),
            ),
          ),
          const Positioned(
            left: 24,
            top: 128,
            child: Text(
              '수입 등록',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 205,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '금액',
                  style: TextStyle(color: AppColors.text50, fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 30,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 30),
                const Text(
                  '수입 카테고리',
                  style: TextStyle(color: AppColors.text50, fontSize: 14),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: List.generate(
                    _categories.length,
                    (index) => ChoiceChip(
                      label: Text(_categories[index]),
                      selected: _category == index,
                      onSelected: (_) => setState(() => _category = index),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                AuthTextField(
                  controller: _memo,
                  hintText: '메모 (선택)',
                  onChanged: (_) {},
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '저장 중...' : '저장',
            onPressed: _isLoading ? () {} : _save,
          ),
        ],
      ),
    ),
  );
}
