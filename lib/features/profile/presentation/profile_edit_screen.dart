import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bank_account_picker.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'profile_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.initialData, this.financeService});

  final Map<String, dynamic>? initialData;
  final FinanceService? financeService;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late String _nickname;
  String? _bankName;
  String? _accountNumber;

  @override
  void initState() {
    super.initState();
    _nickname =
        widget.initialData?['nickname'] as String? ??
        (widget.financeService == null ? '소비로그' : '');
    _bankName =
        widget.initialData?['bank_name'] as String? ??
        (widget.financeService == null ? '소비은행' : null);
    _accountNumber =
        widget.initialData?['bank_account_number'] as String? ??
        (widget.financeService == null ? '000-0000-0000' : null);
  }

  Future<String?> _ask(String title, String initialValue) async {
    var value = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNickname() async {
    final value = await _ask('이름 수정', _nickname);
    if (value == null) return;
    if (value.length < 2 || value.length > 10) {
      _showMessage('이름은 2~10자로 입력해 주세요');
      return;
    }
    if (!await _update({'nickname': value})) return;
    setState(() => _nickname = value);
  }

  Future<void> _editAccount() async {
    final result = await showBankAccountPicker(
      context,
      bank: _bankName,
      number: _accountNumber,
    );
    if (result == null || !mounted) return;
    final (bank: bank, number: account) = result;
    if (!await _update({'bank_name': bank, 'bank_account_number': account})) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _bankName = bank;
      _accountNumber = account;
    });
  }

  Future<bool> _update(Map<String, Object?> body) async {
    final service = widget.financeService;
    if (service == null) return true;
    try {
      await service.updateProfile(body);
      return true;
    } on ApiException catch (error) {
      _showMessage(error.message);
      return false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _createdAt {
    final value = DateTime.tryParse(
      widget.initialData?['created_at'] as String? ?? '',
    );
    if (value == null) {
      return widget.financeService == null ? '2026년 9월 1일 오후 3:20' : '-';
    }
    final local = value.toLocal();
    final period = local.hour < 12 ? '오전' : '오후';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${local.year}년 ${local.month}월 ${local.day}일 $period $hour:${local.minute.toString().padLeft(2, '0')}';
  }

  String get _provider => widget.initialData?['provider'] as String? ?? 'email';

  String get _emailDisplay {
    final email = widget.initialData?['email'] as String?;
    return switch (_provider) {
      'apple'
          when email != null &&
              email.isNotEmpty &&
              !email.endsWith('@apple.sobilog.internal') =>
        'Apple 로그인 · $email',
      'apple' => 'Apple 로그인',
      'kakao' => '카카오 로그인',
      _ =>
        email ?? (widget.financeService == null ? 'welcome@sobilog.com' : '-'),
    };
  }

  void _navigate(int index) {
    final Widget? destination = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      4 => ProfileScreen(financeService: widget.financeService),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
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
              icon: SvgPicture.asset(AppAssets.profileBack),
            ),
          ),
          const Positioned(
            left: 24,
            top: 122,
            child: Text(
              '프로필 수정',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 192,
            width: 354,
            child: Column(
              children: [
                const _ProfileAsterisks(),
                const SizedBox(height: 20),
                _ProfileRow(
                  label: '이름',
                  value: _nickname,
                  arrow: true,
                  onTap: _editNickname,
                ),
                const SizedBox(height: 20),
                _ProfileRow(label: '가입 이메일', value: _emailDisplay),
                const SizedBox(height: 20),
                _ProfileRow(label: '가입일', value: _createdAt),
                const SizedBox(height: 20),
                const _ProfileAsterisks(),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '더치페이 계좌',
                    style: TextStyle(
                      color: AppColors.text50,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 17 / 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _AccountCard(
                  key: const Key('edit-profile-account'),
                  bankName: _bankName,
                  accountNumber: _accountNumber,
                  onTap: _editAccount,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: AppBottomNavigation(selectedIndex: 4, onSelected: _navigate),
          ),
        ],
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.arrow = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool arrow;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text50,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 17 / 14,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 17 / 14,
                    ),
                  ),
                ),
                if (arrow) ...[
                  const SizedBox(width: 6),
                  const AppChevron(size: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileAsterisks extends StatelessWidget {
  const _ProfileAsterisks();
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.receiptAsteriskDivider,
    width: 354,
    height: 7,
    fit: BoxFit.fill,
    colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.bankName,
    required this.accountNumber,
    required this.onTap,
  });
  final String? bankName;
  final String? accountNumber;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 354,
      height: 88,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName?.isNotEmpty == true ? bankName! : '은행을 선택해 주세요',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 17 / 14,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  accountNumber?.isNotEmpty == true
                      ? accountNumber!
                      : '계좌번호를 등록해 주세요',
                  style: const TextStyle(
                    color: AppColors.text80,
                    fontSize: 12,
                    height: 21 / 12,
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(AppAssets.profileEdit, width: 34, height: 34),
        ],
      ),
    ),
  );
}
