import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../data/kakao_share_service.dart';
import '../data/dutch_pay_service.dart';

/// 더치_005: 인원별 정산 요청(계좌+요청금액 복사·공유) 화면.
class DutchRequestScreen extends StatefulWidget {
  const DutchRequestScreen({
    super.key,
    this.sessionId,
    this.dutchPayService,
    this.settlementData,
    this.selfName,
    this.onShareText,
    this.kakaoShareService,
  });

  final String? sessionId;
  final DutchPayService? dutchPayService;
  final Map<String, dynamic>? settlementData;
  final String? selfName;
  final Future<void> Function(String message)? onShareText;
  final KakaoShareService? kakaoShareService;

  @override
  State<DutchRequestScreen> createState() => _DutchRequestScreenState();
}

class _DutchRequestScreenState extends State<DutchRequestScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isCompleting = false;
  String? _error;
  int _selectedRequestIndex = 0;
  bool _didPrecacheBankLogos = false;

  bool get _isLive =>
      widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _data = widget.settlementData;
    if (_isLive) {
      _isLoading = true;
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBankLogos) return;
    _didPrecacheBankLogos = true;
    for (final bank in _BankPickerDialog.banks) {
      precacheImage(AssetImage(_bankLogoAsset(bank)), context);
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.dutchPayService!.summary(widget.sessionId!);
      if (mounted) setState(() => _data = {...?_data, ...data});
    } catch (_) {
      if (mounted) setState(() => _error = '정산 정보를 불러오지 못했습니다. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _requests {
    final list = (_data?['requests'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (list != null) return list;
    if (_isLive) return const [];
    return const [
      {
        'participant_id': 'p2',
        'name': '철수',
        'amount': 14500,
        'message': '철수 님  14,500원',
      },
      {
        'participant_id': 'p3',
        'name': '영희',
        'amount': 14500,
        'message': '영희 님  14,500원',
      },
    ];
  }

  String get _bankLabel {
    final bankName = _data?['bank_name'] as String?;
    final account = _data?['bank_account_number'] as String?;
    if (bankName == null || account == null) {
      return _isLive ? '계좌 정보를 등록해 주세요' : '아주은행 000-0000-0000';
    }
    return '$bankName $account';
  }

  bool get _hasAccount {
    if (_data == null) return !_isLive;
    return (_data?['bank_name'] as String?)?.isNotEmpty == true &&
        (_data?['bank_account_number'] as String?)?.isNotEmpty == true;
  }

  Future<void> _editAccount() async {
    await Future.wait(
      _BankPickerDialog.banks.map(
        (bank) => precacheImage(AssetImage(_bankLogoAsset(bank)), context),
      ),
    );
    if (!mounted) return;
    final bankName = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) =>
          _BankPickerDialog(selectedBank: _data?['bank_name'] as String?),
    );
    if (bankName == null || !mounted) return;
    final account = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _AccountNumberDialog(
        bankName: bankName,
        initialValue: _data?['bank_account_number'] as String? ?? '',
      ),
    );
    if (account == null || !mounted) return;
    if (!_isLive) {
      setState(() {
        _data = {
          ...?_data,
          'bank_name': bankName,
          'bank_account_number': account,
        };
      });
      return;
    }
    try {
      final updated = await widget.dutchPayService!.updateAccount(
        widget.sessionId!,
        bankName: bankName,
        bankAccountNumber: account,
      );
      if (mounted) {
        setState(() => _data = {...?_data, ...updated});
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _copy(String message) async {
    if (!_hasAccount) {
      await _showAccountRequired();
      return;
    }
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('메시지를 복사했어요')));
  }

  Future<void> _copyAll() async {
    await _copy(_combinedMessage);
  }

  String get _requesterName {
    final explicit =
        _data?['owner_name'] as String? ??
        _data?['requester_name'] as String? ??
        widget.selfName;
    if (explicit?.trim().isNotEmpty == true) return explicit!.trim();
    for (final request in _requests) {
      final parts = (request['message'] as String? ?? '').split(' / ');
      if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    final participants = (widget.settlementData?['participants'] as List?)
        ?.whereType<Map<String, dynamic>>();
    for (final participant in participants ?? const <Map<String, dynamic>>[]) {
      if (participant['is_self'] == true) {
        return participant['name'] as String? ?? '나';
      }
    }
    return _isLive ? '나' : '홍길동';
  }

  List<Map<String, dynamic>> get _settlementParticipants {
    final participants = (widget.settlementData?['participants'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (participants?.isNotEmpty == true) return participants!;
    return [
      {'name': _requesterName, 'amount': 0, 'is_self': true},
      ..._requests,
    ];
  }

  String _individualMessage(Map<String, dynamic> request) {
    final name = request['name'] as String? ?? '';
    final amount = request['amount'] as int? ?? 0;
    return '$_requesterName님이 $name님께 더치페이를 요청했어요\n'
        '보낼 금액 ${_formatAmount(amount)}원\n'
        '입금 계좌 $_bankLabel ($_requesterName)';
  }

  String get _combinedMessage => [
    '$_requesterName님이 더치페이를 요청했어요',
    for (final participant in _settlementParticipants)
      '${participant['name']}  ${_formatAmount(participant['amount'] as int? ?? 0)}원',
    '총 ${_formatAmount(_settlementTotal)}원',
    '입금 계좌 $_bankLabel ($_requesterName)',
  ].join('\n');

  int get _settlementTotal =>
      widget.settlementData?['total_amount'] as int? ??
      _requests.fold<int>(
        0,
        (sum, item) => sum + (item['amount'] as int? ?? 0),
      );

  Future<void> _share(
    String message, {
    bool whole = false,
    int? requestedAmount,
  }) async {
    if (!_hasAccount) {
      await _showAccountRequired();
      return;
    }
    final target = await showDialog<_ShareTarget>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _ShareDialog(
        message: message,
        account: _bankLabel,
        requesterName: _requesterName,
        participants: _settlementParticipants,
        participantCount: _settlementParticipants.length,
        participantName: whole || _requests.isEmpty
            ? null
            : _requests[_selectedRequestIndex.clamp(
                    0,
                    _requests.length - 1,
                  )]['name']
                  as String?,
        totalAmount: requestedAmount ?? _settlementTotal,
      ),
    );
    if (target == null || !mounted) return;
    if (widget.onShareText case final callback?) {
      await callback(message);
      return;
    }
    switch (target) {
      case _ShareTarget.kakao:
        try {
          await (widget.kakaoShareService ?? const KakaoSdkShareService())
              .shareText(message);
        } catch (_) {
          await Clipboard.setData(ClipboardData(text: message));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카카오톡 공유를 열지 못했습니다. 메시지를 복사했어요')),
          );
        }
        return;
      case _ShareTarget.message:
        final uri = Uri(scheme: 'sms', queryParameters: {'body': message});
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await Clipboard.setData(ClipboardData(text: message));
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('메시지를 복사했어요')));
          }
        }
        return;
    }
  }

  Future<void> _showAccountRequired() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('정산 계좌를 먼저 등록해 주세요')));
    await _editAccount();
  }

  Future<void> _copyRequest(int index) async {
    if (_requests.isEmpty) return;
    setState(() => _selectedRequestIndex = index);
    final request = _requests[index];
    await _copy(_individualMessage(request));
  }

  Future<void> _shareRequest(int index) async {
    if (_requests.isEmpty) return;
    setState(() => _selectedRequestIndex = index);
    final request = _requests[index];
    await _share(
      _individualMessage(request),
      requestedAmount: request['amount'] as int? ?? 0,
    );
  }

  Future<void> _complete() async {
    if (!_isLive) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _isCompleting = true;
      _error = null;
    });
    try {
      final message = await widget.dutchPayService!.complete(widget.sessionId!);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
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
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 34,
                height: 34,
                child: SvgPicture.asset(
                  AppAssets.arrowBackLight,
                  width: 34,
                  height: 34,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            top: 125,
            child: Text(
              '정산 요청',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 27,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 192,
            bottom: 121,
            child: _CompactRequestBody(
              requests: _requests,
              accountLabel: _bankLabel,
              hasAccount: _hasAccount,
              loading: _isLoading,
              requesterName: _requesterName,
              settlementParticipants: _settlementParticipants,
              settlementTotal: _settlementTotal,
              individualRequests: [
                for (final request in _requests)
                  (
                    id: request['participant_id'] as String? ?? '',
                    name: request['name'] as String? ?? '',
                    amount: request['amount'] as int? ?? 0,
                  ),
              ],
              onEditAccount: _editAccount,
              onCopy: _copyRequest,
              onShare: _shareRequest,
              onCopyAll: _hasAccount ? _copyAll : _showAccountRequired,
              onShareAll: _hasAccount
                  ? () => _share(_combinedMessage, whole: true)
                  : _showAccountRequired,
            ),
          ),
          if (_error case final message?)
            Positioned(
              left: 24,
              right: 24,
              bottom: 112,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 121,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE6121215)],
                      stops: [0, .8],
                    ),
                  ),
                  child: FilledButton(
                    onPressed: _isCompleting ? null : _complete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.main,
                      disabledBackgroundColor: AppColors.selected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isCompleting ? '처리 중...' : '완료',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompactRequestBody extends StatelessWidget {
  const _CompactRequestBody({
    required this.requests,
    required this.accountLabel,
    required this.hasAccount,
    required this.loading,
    required this.requesterName,
    required this.settlementParticipants,
    required this.settlementTotal,
    required this.individualRequests,
    required this.onEditAccount,
    required this.onCopy,
    required this.onShare,
    required this.onCopyAll,
    required this.onShareAll,
  });

  final List<Map<String, dynamic>> requests;
  final String accountLabel;
  final bool hasAccount;
  final bool loading;
  final String requesterName;
  final List<Map<String, dynamic>> settlementParticipants;
  final int settlementTotal;
  final List<({String id, String name, int amount})> individualRequests;
  final VoidCallback onEditAccount;
  final ValueChanged<int> onCopy;
  final ValueChanged<int> onShare;
  final VoidCallback onCopyAll;
  final VoidCallback onShareAll;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CompactDivider(),
        const SizedBox(height: 20),
        if (loading)
          const _CompactRequestSkeleton()
        else if (hasAccount)
          _CompactAccount(label: accountLabel, onEdit: onEditAccount)
        else ...[
          const SizedBox(
            width: 354,
            height: 51,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '등록된 계좌가 없어요',
                  style: TextStyle(
                    color: Color(0xFFCF376A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '계좌를 등록해야 요청 메시지를 보낼 수 있어요',
                  style: TextStyle(color: AppColors.text80, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 354,
            height: 56,
            child: FilledButton(
              key: const Key('register-settlement-account'),
              onPressed: onEditAccount,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '계좌 등록하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (!loading) ...[
          const SizedBox(height: 20),
          const _CompactDivider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '요청할 인원 ${requests.length}명',
                style: const TextStyle(
                  color: AppColors.text80,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                key: const Key('dutch-copy-all-header'),
                onTap: onCopyAll,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '전체 복사',
                    style: TextStyle(
                      color: AppColors.text80,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < requests.length; index++) ...[
            _CompactPerson(
              request: requests[index],
              enabled: hasAccount,
              onCopy: () => onCopy(index),
              onShare: () => onShare(index),
            ),
            if (index != requests.length - 1) const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CompactAction(
                  label: '전체 복사',
                  enabled: hasAccount,
                  onTap: onCopyAll,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _CompactAction(
                  label: '전체 공유',
                  enabled: hasAccount,
                  onTap: onShareAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CompactPreview(
            expanded: hasAccount,
            accountLabel: accountLabel,
            requesterName: requesterName,
            settlementParticipants: settlementParticipants,
            settlementTotal: settlementTotal,
            individualRequests: individualRequests,
          ),
        ],
      ],
    ),
  );
}

class _CompactRequestSkeleton extends StatelessWidget {
  const _CompactRequestSkeleton();

  @override
  Widget build(BuildContext context) => const AppSkeleton(
    key: Key('dutch-request-loading-skeleton'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBox(width: 47, height: 14),
        SizedBox(height: 13),
        Row(
          children: [
            AppSkeletonBox(width: 235, height: 20),
            Spacer(),
            AppSkeletonBox(width: 24, height: 24, shape: BoxShape.circle),
          ],
        ),
        SizedBox(height: 10),
        AppSkeletonBox(width: 205, height: 12),
        SizedBox(height: 27),
        AppSkeletonBox(width: 354, height: 7, radius: 0),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSkeletonBox(width: 104, height: 14),
            AppSkeletonBox(width: 52, height: 14),
          ],
        ),
        SizedBox(height: 20),
        _CompactPersonSkeleton(),
        SizedBox(height: 20),
        _CompactPersonSkeleton(),
        SizedBox(height: 20),
        _CompactPersonSkeleton(),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: AppSkeletonBox(width: 170, height: 56, radius: 20)),
            SizedBox(width: 15),
            Expanded(child: AppSkeletonBox(width: 170, height: 56, radius: 20)),
          ],
        ),
      ],
    ),
  );
}

class _CompactPersonSkeleton extends StatelessWidget {
  const _CompactPersonSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 354,
    height: 74,
    child: Row(
      children: [
        AppSkeletonBox(width: 38, height: 38, shape: BoxShape.circle),
        SizedBox(width: 14),
        AppSkeletonBox(width: 52, height: 15),
        Spacer(),
        AppSkeletonBox(width: 75, height: 22),
        SizedBox(width: 16),
        AppSkeletonBox(width: 46, height: 14),
        SizedBox(width: 16),
        AppSkeletonBox(width: 24, height: 24),
      ],
    ),
  );
}

class _CompactDivider extends StatelessWidget {
  const _CompactDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 354,
    height: 7,
    fit: BoxFit.fill,
  );
}

class _CompactAccount extends StatelessWidget {
  const _CompactAccount({required this.label, required this.onEdit});

  final String label;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 84,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 계좌',
          style: TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              key: const Key('edit-settlement-account'),
              onTap: onEdit,
              child: SvgPicture.asset(
                AppAssets.editLight,
                width: 34,
                height: 34,
              ),
            ),
          ],
        ),
        const Text(
          '수정하면 다음 정산에도 이 계좌를 사용해요',
          style: TextStyle(
            color: Color(0xFFA8A3FF),
            fontSize: 12,
            height: 1.75,
          ),
        ),
      ],
    ),
  );
}

class _CompactPerson extends StatelessWidget {
  const _CompactPerson({
    required this.request,
    required this.enabled,
    required this.onCopy,
    required this.onShare,
  });

  final Map<String, dynamic> request;
  final bool enabled;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final id = request['participant_id'] as String? ?? '';
    return Container(
      width: 354,
      height: 74,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppAssets.avatarSelected, width: 34, height: 34),
          const SizedBox(width: 16),
          Text(
            request['name'] as String? ?? '',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _RequestAmount(value: request['amount'] as int? ?? 0),
          const SizedBox(width: 16),
          GestureDetector(
            key: ValueKey('dutch-copy-$id'),
            onTap: onCopy,
            child: Text(
              '복사',
              style: TextStyle(
                color: enabled ? AppColors.text80 : AppColors.text20,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            key: ValueKey('dutch-share-$id'),
            onTap: onShare,
            child: Opacity(
              opacity: enabled ? 1 : .25,
              child: SvgPicture.asset(
                AppAssets.dutchShare,
                width: 34,
                height: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.text20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? AppColors.text : AppColors.text20,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _CompactPreview extends StatelessWidget {
  const _CompactPreview({
    required this.expanded,
    required this.accountLabel,
    required this.requesterName,
    required this.settlementParticipants,
    required this.settlementTotal,
    required this.individualRequests,
  });

  final bool expanded;
  final String accountLabel;
  final String requesterName;
  final List<Map<String, dynamic>> settlementParticipants;
  final int settlementTotal;
  final List<({String id, String name, int amount})> individualRequests;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Container(
        width: 354,
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '복사되는 메시지',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '철수 님  14,500원\n홍길동 / $accountLabel',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text80,
                fontSize: 12,
                height: 1.75,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: 354,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(21, 18, 21, 0),
            child: Text(
              '공유되는 메시지',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _WholeMessagePreview(
            key: const Key('dutch-preview-all'),
            requesterName: requesterName,
            participants: settlementParticipants,
            total: settlementTotal,
            accountLabel: accountLabel,
          ),
          for (final individual in individualRequests) ...[
            const Divider(height: 1, color: AppColors.text10),
            _IndividualMessagePreview(
              key: ValueKey('dutch-preview-individual-${individual.id}'),
              requesterName: requesterName,
              participantName: individual.name,
              amount: individual.amount,
              accountLabel: accountLabel,
            ),
          ],
        ],
      ),
    );
  }
}

class _WholeMessagePreview extends StatelessWidget {
  const _WholeMessagePreview({
    required this.requesterName,
    required this.participants,
    required this.total,
    required this.accountLabel,
    super.key,
  });

  final String requesterName;
  final List<Map<String, dynamic>> participants;
  final int total;
  final String accountLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(21, 17, 21, 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MessageTypeChip('전체'),
        const SizedBox(height: 15),
        Text('$requesterName님이 더치페이를 요청했어요', style: _messageHeadlineStyle),
        const SizedBox(height: 8),
        for (final participant in participants)
          _MessageRow(
            label: participant['name'] as String? ?? '',
            value: '${_formatAmount(participant['amount'] as int? ?? 0)}원',
          ),
        _MessageRow(label: '총', value: '${_formatAmount(total)}원'),
        _MessageRow(label: '입금 계좌', value: '$accountLabel ($requesterName)'),
      ],
    ),
  );
}

class _IndividualMessagePreview extends StatelessWidget {
  const _IndividualMessagePreview({
    required this.requesterName,
    required this.participantName,
    required this.amount,
    required this.accountLabel,
    super.key,
  });

  final String requesterName;
  final String participantName;
  final int amount;
  final String accountLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(21, 21, 21, 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MessageTypeChip('개별 · $participantName'),
        const SizedBox(height: 15),
        Text(
          '$requesterName님이 $participantName님께 더치페이를 요청했어요',
          style: _messageHeadlineStyle,
        ),
        const SizedBox(height: 8),
        _MessageRow(label: '보낼 금액', value: '${_formatAmount(amount)}원'),
        _MessageRow(label: '입금 계좌', value: '$accountLabel ($requesterName)'),
      ],
    ),
  );
}

class _MessageTypeChip extends StatelessWidget {
  const _MessageTypeChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.outline,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.text20, width: .5),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 23,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 99, child: Text(label, style: _messageLabelStyle)),
        Expanded(child: Text(value, style: _messageValueStyle)),
      ],
    ),
  );
}

const _messageHeadlineStyle = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

const _messageLabelStyle = TextStyle(
  color: AppColors.text50,
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.75,
);

const _messageValueStyle = TextStyle(
  color: AppColors.text,
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.75,
);

class _RequestDivider extends StatelessWidget {
  const _RequestDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 657,
    height: 15,
    fit: BoxFit.fill,
  );
}

// Legacy large-canvas component kept while older routes migrate to 402px.
// ignore: unused_element
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.label,
    required this.hasAccount,
    required this.onEdit,
  });
  final String label;
  final bool hasAccount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 235,
    color: Colors.transparent,
    child: Stack(
      children: [
        const Positioned(left: 46, top: 0, child: _RequestDivider()),
        if (hasAccount) ...[
          const Positioned(
            left: 46,
            top: 43,
            child: Text(
              '내 계좌',
              style: TextStyle(color: AppColors.text50, fontSize: 26),
            ),
          ),
          Positioned(
            left: 38,
            top: 94,
            right: 130,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 37,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 499,
            top: 90,
            child: GestureDetector(
              key: const Key('edit-settlement-account'),
              onTap: onEdit,
              child: SvgPicture.asset(
                AppAssets.editLight,
                width: 64,
                height: 64,
              ),
            ),
          ),
          const Positioned(
            left: 46,
            top: 157,
            child: Text(
              '수정하면 다음 정산에도 이 계좌를 사용해요',
              style: TextStyle(color: Color(0xFFA8A3FF), fontSize: 22),
            ),
          ),
        ] else ...[
          const Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '등록된 계좌가 없어요',
                  style: TextStyle(
                    color: Color(0xFFFF7373),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '계좌를 등록해야 요청 메시지를 보낼 수 있어요',
                  style: TextStyle(color: AppColors.text80, fontSize: 22),
                ),
              ],
            ),
          ),
          Positioned(
            left: 46,
            right: 46,
            top: 118,
            height: 78,
            child: FilledButton(
              key: const Key('register-settlement-account'),
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '계좌 등록하기',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        const Positioned(left: 46, bottom: 0, child: _RequestDivider()),
      ],
    ),
  );
}

// ignore: unused_element
class _RequestPeople extends StatelessWidget {
  const _RequestPeople({
    required this.requests,
    required this.onCopy,
    required this.onShare,
    required this.enabled,
  });
  final List<Map<String, dynamic>> requests;
  final ValueChanged<int> onCopy;
  final ValueChanged<int> onShare;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < requests.length; index++)
        _RequestPerson(
          key: ValueKey('dutch-request-${requests[index]['participant_id']}'),
          participantId:
              requests[index]['participant_id'] as String? ?? '$index',
          name: requests[index]['name'] as String? ?? '',
          amount: requests[index]['amount'] as int? ?? 0,
          enabled: enabled,
          onCopy: () => onCopy(index),
          onShare: () => onShare(index),
        ),
    ],
  );
}

class _RequestPerson extends StatelessWidget {
  const _RequestPerson({
    super.key,
    required this.participantId,
    required this.name,
    required this.amount,
    required this.onCopy,
    required this.onShare,
    required this.enabled,
  });

  final String participantId;
  final String name;
  final int amount;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    width: 657,
    height: 205,
    margin: const EdgeInsets.only(bottom: 37),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(37),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 30,
          child: SvgPicture.asset(
            AppAssets.avatarSelected,
            width: 63,
            height: 63,
          ),
        ),
        Positioned(
          left: 138,
          top: 44,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(right: 46, top: 39, child: _RequestAmount(value: amount)),
        Positioned(
          right: 178,
          bottom: 24,
          child: GestureDetector(
            key: ValueKey('dutch-copy-$participantId'),
            onTap: onCopy,
            child: Container(
              width: 104,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: AppColors.text20),
              ),
              child: Text(
                '복사',
                style: TextStyle(
                  color: enabled ? const Color(0xCCE2E2F9) : AppColors.text30,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 46,
          bottom: 24,
          child: GestureDetector(
            key: ValueKey('dutch-share-$participantId'),
            onTap: onShare,
            child: Container(
              width: 116,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: AppColors.text20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: enabled ? 1 : .35,
                    child: SvgPicture.asset(
                      AppAssets.dutchShare,
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '공유',
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xCCE2E2F9)
                          : AppColors.text30,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _BulkActions extends StatelessWidget {
  const _BulkActions({
    required this.onCopyAll,
    required this.onShareAll,
    required this.onUnavailable,
  });
  final VoidCallback? onCopyAll;
  final VoidCallback? onShareAll;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _BulkActionButton(
          label: '전체 복사',
          onTap: onCopyAll ?? onUnavailable,
          enabled: onCopyAll != null,
        ),
      ),
      const SizedBox(width: 28),
      Expanded(
        child: _BulkActionButton(
          label: '전체 공유',
          onTap: onShareAll ?? onUnavailable,
          enabled: onShareAll != null,
        ),
      ),
    ],
  );
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 104,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(37),
        border: Border.all(color: AppColors.text20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? AppColors.text : AppColors.text30,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ignore: unused_element
class _RequestBottomButton extends StatelessWidget {
  const _RequestBottomButton({
    required this.label,
    required this.width,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      height: 102,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? AppColors.main : AppColors.selected,
        borderRadius: BorderRadius.circular(37),
        border: Border.all(color: const Color(0x4DE2E2F9)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onTap == null ? AppColors.text30 : Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ignore: unused_element
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.allMessage,
    required this.individualName,
    required this.individualMessage,
  });
  final String allMessage;
  final String individualName;
  final String individualMessage;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(45),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(37),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공유되는 메시지',
          style: TextStyle(color: AppColors.text, fontSize: 28),
        ),
        const SizedBox(height: 8),
        const _PreviewChip('전체'),
        const SizedBox(height: 10),
        Text(
          allMessage,
          style: const TextStyle(color: Color(0xCCE2E2F9), fontSize: 22),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppColors.text10),
        const SizedBox(height: 20),
        Row(
          children: [
            _PreviewChip('개별 · $individualName'),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '복사·공유를 누른 인원으로 바뀌',
                style: TextStyle(color: AppColors.text50, fontSize: 17),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          individualMessage,
          style: const TextStyle(color: Color(0xCCE2E2F9), fontSize: 22),
        ),
      ],
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.outline,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.text20, width: .5),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _RequestAmount extends StatelessWidget {
  const _RequestAmount({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _formatAmount(value),
        style: const TextStyle(
          color: AppColors.text,
          fontFamily: 'Amarante',
          fontSize: 20,
        ),
      ),
      const SizedBox(width: 4),
      SvgPicture.asset(AppAssets.wonLight, width: 14, height: 15),
    ],
  );
}

String _formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}

enum _ShareTarget { kakao, message }

class _BankPickerDialog extends StatelessWidget {
  const _BankPickerDialog({this.selectedBank});

  final String? selectedBank;

  static const banks = [
    '우리',
    'KB국민',
    '신한',
    '카카오',
    '하나',
    '시티',
    'SC제일',
    '토스',
    'IM',
    'IBK기업',
    '부산',
    '경남',
    '광주',
    '전북',
    '제주',
    'KDB산업',
    'MG새마을',
    'NH농협',
    '수협',
    '신협',
    '우체국',
    'SBI저축',
  ];

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Scaffold(
          backgroundColor: const Color(0x80121215),
          body: DesignCanvas(
            paintBackground: false,
            child: Stack(
              children: [
                const Positioned(
                  top: 112,
                  left: 0,
                  right: 0,
                  child: Text(
                    '은행을 선택해 주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 35,
                  right: 35,
                  top: 155,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: banks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 76,
                          mainAxisSpacing: 35,
                          crossAxisSpacing: 38,
                        ),
                    itemBuilder: (context, index) {
                      final bank = banks[index];
                      return GestureDetector(
                        key: ValueKey('bank-$bank'),
                        onTap: () => Navigator.pop(context, bank),
                        child: Column(
                          children: [
                            _BankLogo(bank: bank, width: 50, height: 50),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 18,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _bankDisplayLabel(bank),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _bankDisplayLabel(String bank) => switch (bank) {
  'IBK기업' => 'IBK 기업',
  'KDB산업' => 'KDB 산업',
  'MG새마을' => 'MG 새마을',
  'NH농협' => 'NH 농협',
  'SBI저축' => 'SBI 저축',
  _ => bank,
};

String _bankLogoAsset(String bank) => switch (bank) {
  '우리' => 'assets/bank_logos/woori.png',
  'KB국민' => 'assets/bank_logos/kb.png',
  '신한' => 'assets/bank_logos/shinhan.png',
  '카카오' => 'assets/bank_logos/kakao.png',
  '하나' => 'assets/bank_logos/hana.png',
  '시티' => 'assets/bank_logos/citi.png',
  'SC제일' => 'assets/bank_logos/sc.png',
  '토스' => 'assets/bank_logos/toss.png',
  'IM' => 'assets/bank_logos/im.png',
  'IBK기업' => 'assets/bank_logos/ibk.png',
  '부산' => 'assets/bank_logos/busan.png',
  '경남' => 'assets/bank_logos/gyeongnam.png',
  '광주' => 'assets/bank_logos/gwangju.png',
  '전북' => 'assets/bank_logos/jeonbuk.png',
  '제주' => 'assets/bank_logos/jeju.png',
  'KDB산업' => 'assets/bank_logos/kdb.png',
  'MG새마을' => 'assets/bank_logos/mg.png',
  'NH농협' => 'assets/bank_logos/nh.png',
  '수협' => 'assets/bank_logos/suhyup.png',
  '신협' => 'assets/bank_logos/cu.png',
  '우체국' => 'assets/bank_logos/post.png',
  'SBI저축' => 'assets/bank_logos/sbi.png',
  _ => 'assets/bank_logos/toss.png',
};

class _BankLogo extends StatelessWidget {
  const _BankLogo({
    required this.bank,
    required this.width,
    required this.height,
  });

  final String bank;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      _bankLogoAsset(bank),
      key: ValueKey('bank-logo-$bank'),
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    ),
  );
}

class _AccountNumberDialog extends StatefulWidget {
  const _AccountNumberDialog({
    required this.bankName,
    required this.initialValue,
  });
  final String bankName;
  final String initialValue;

  @override
  State<_AccountNumberDialog> createState() => _AccountNumberDialogState();
}

class _AccountNumberDialogState extends State<_AccountNumberDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0x80121215),
          body: DesignCanvas(
            paintBackground: false,
            child: Stack(
              children: [
                const Positioned(
                  top: 249,
                  left: 0,
                  right: 0,
                  child: Text(
                    '계좌번호 입력',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 286,
                  height: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.selected,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.text20),
                    ),
                    child: Row(
                      children: [
                        _BankLogo(bank: widget.bankName, width: 38, height: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.bankName == '토스'
                                ? '토스뱅크'
                                : _bankDisplayLabel(widget.bankName),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SvgPicture.asset(
                          AppAssets.editLight,
                          width: 34,
                          height: 34,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 362,
                  height: 56,
                  child: TextField(
                    key: const Key('settlement-account-number'),
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '계좌번호',
                      hintStyle: const TextStyle(color: AppColors.text50),
                      filled: true,
                      fillColor: AppColors.selected,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.text20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.main),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 24,
                  top: 438,
                  child: Text(
                    '숫자만 입력해 주세요. 하이픈(-)은 자동으로 빠져요',
                    style: TextStyle(color: AppColors.text80, fontSize: 12),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 479,
                  height: 56,
                  child: FilledButton(
                    key: const Key('register-settlement-account-number'),
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty) Navigator.pop(context, value);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.main,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '등록',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShareDialog extends StatelessWidget {
  const _ShareDialog({
    required this.message,
    required this.account,
    required this.requesterName,
    required this.participants,
    required this.totalAmount,
    required this.participantCount,
    this.participantName,
  });
  final String message;
  final String account;
  final String requesterName;
  final List<Map<String, dynamic>> participants;
  final int totalAmount;
  final int participantCount;
  final String? participantName;

  @override
  Widget build(BuildContext context) {
    final individual = participantName?.isNotEmpty == true;
    final sheetHeight = individual ? 392.0 : 483.0;
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ColoredBox(
            color: const Color(0x80121215),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 402,
                height: sheetHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 25),
                  child: Column(
                    children: [
                      const Text(
                        '공유',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        individual
                            ? '${participantName!}에게 보낼 메시지'
                            : '전체 메시지 · $participantCount명 총 ${_formatAmount(totalAmount)}원',
                        style: const TextStyle(
                          color: AppColors.text80,
                          fontSize: 12,
                          height: 1.75,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ShareChoice(
                            key: const Key('share-via-kakao'),
                            label: '카카오톡',
                            icon: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE300),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                AppAssets.shareKakaoBubble,
                                width: 29,
                                height: 27,
                              ),
                            ),
                            onTap: () =>
                                Navigator.pop(context, _ShareTarget.kakao),
                          ),
                          const SizedBox(width: 38),
                          _ShareChoice(
                            key: const Key('share-via-message'),
                            label: '메시지',
                            icon: SvgPicture.asset(
                              AppAssets.shareMessage,
                              width: 50,
                              height: 50,
                            ),
                            onTap: () =>
                                Navigator.pop(context, _ShareTarget.message),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),
                      _ShareMessageCard(
                        individual: individual,
                        message: message,
                        account: account,
                        requesterName: requesterName,
                        participants: participants,
                        totalAmount: totalAmount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareMessageCard extends StatelessWidget {
  const _ShareMessageCard({
    required this.individual,
    required this.message,
    required this.account,
    required this.requesterName,
    required this.participants,
    required this.totalAmount,
  });

  final bool individual;
  final String message;
  final String account;
  final String requesterName;
  final List<Map<String, dynamic>> participants;
  final int totalAmount;

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    height: individual ? 140 : 231,
    padding: const EdgeInsets.fromLTRB(21, 18, 21, 15),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보낼 메시지',
          style: TextStyle(color: AppColors.text80, fontSize: 12, height: 1.75),
        ),
        const SizedBox(height: 3),
        Text(
          message.split('\n').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (individual)
          _ShareMessageRow(
            label: '보낼 금액',
            value: '${_formatAmount(totalAmount)}원',
          )
        else ...[
          for (final participant in participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _ShareMessageRow(
                label: participant['name'] as String? ?? '',
                value: '${_formatAmount(participant['amount'] as int? ?? 0)}원',
              ),
            ),
          _ShareMessageRow(label: '총', value: '${_formatAmount(totalAmount)}원'),
        ],
        const Spacer(),
        _ShareMessageRow(label: '입금 계좌', value: '$account ($requesterName)'),
      ],
    ),
  );
}

class _ShareMessageRow extends StatelessWidget {
  const _ShareMessageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 99,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.text50, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
      ),
    ],
  );
}

class _ShareChoice extends StatelessWidget {
  const _ShareChoice({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        SizedBox(width: 50, height: 50, child: icon),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    ),
  );
}
