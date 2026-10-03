import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import '../../register/presentation/register_income_screen.dart';

class IncomeDetailScreen extends StatefulWidget {
  const IncomeDetailScreen({
    required this.incomeId,
    super.key,
    this.financeService,
    this.initialData,
  });

  final String incomeId;
  final FinanceService? financeService;
  final Map<String, dynamic>? initialData;

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  Map<String, dynamic>? _data;
  late bool _isLoading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData == null
        ? null
        : Map<String, dynamic>.from(widget.initialData!);
    _isLoading = widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    try {
      final data = await service.incomeDetail(widget.incomeId);
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '수입 내역을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<IncomeEditResult>(
      MaterialPageRoute<IncomeEditResult>(
        builder: (_) => RegisterIncomeScreen(
          financeService: widget.financeService,
          incomeId: widget.incomeId,
          initialData: _data,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _data = Map<String, dynamic>.from(result.data));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final date = DateTime.tryParse(data?['income_date'] as String? ?? '');
    return Scaffold(
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
                '수입 상세',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (data != null)
              Positioned(
                left: 24,
                right: 24,
                top: 205,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+${_formatAmount(data['amount'] as int? ?? 0)}원',
                        style: const TextStyle(
                          color: Color(0xFFA8A3FF),
                          fontFamily: 'Amarante',
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _DetailRow(
                        label: '카테고리',
                        value: data['category'] as String? ?? '기타',
                      ),
                      _DetailRow(
                        label: '수입일',
                        value: date == null
                            ? '-'
                            : '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                      ),
                      _DetailRow(
                        label: '메모',
                        value: data['memo'] as String? ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading && data == null)
              const Positioned(
                key: Key('income-detail-loading'),
                left: 0,
                right: 0,
                top: 360,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.main),
                ),
              ),
            if (_error case final message?)
              Positioned(
                left: 24,
                right: 24,
                top: 430,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 12,
                  ),
                ),
              ),
            if (data != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('edit-income'),
                    onPressed: _edit,
                    child: const Text('수정'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.text50, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

String _formatAmount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (match) => ',',
);
