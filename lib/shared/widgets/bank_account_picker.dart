import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

const _manualBankLabel = '기타 (직접 입력)';
const _fieldOutline = BorderSide(color: AppColors.text20);

const _bankLogos = {
  '카카오': 'kakao',
  '토스': 'toss',
  'KB국민': 'kb',
  '신한': 'shinhan',
  '우리': 'woori',
  '하나': 'hana',
  'NH농협': 'nh',
  'IBK기업': 'ibk',
  '케이뱅크': 'kbank',
  '우체국': 'post',
  'MG새마을': 'mg',
  '지역농협': 'nh',
  'IM': 'im',
  '부산': 'busan',
  '경남': 'gyeongnam',
  '광주': 'gwangju',
};

/// 디자인(더치_005-02)에 맞춘 은행 표시 이름. 저장 값(bank_name)은 기존 이름 그대로.
String bankDisplayName(String name) => switch (name) {
  'NH농협' => 'NH 농협',
  'IBK기업' => 'IBK 기업',
  'MG새마을' => 'MG 새마을',
  _ => name,
};

Future<({String bank, String number})?> showBankAccountPicker(
  BuildContext context, {
  String? bank,
  String? number,
}) async {
  var manualName = _bankLogos.containsKey(bank) ? null : bank;
  while (context.mounted) {
    final selectedBank = await _showBankSelection(context, bank);
    if (selectedBank == null || !context.mounted) return null;
    final input = await showDialog<_BankAccountDraft>(
      context: context,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (_) => _BankOverlay(
        alignment: const Alignment(0, -.22),
        child: _BankAccountInput(
          bank: selectedBank,
          initialBank: selectedBank.isEmpty ? manualName : null,
          number: number,
        ),
      ),
    );
    if (input == null || !context.mounted) return null;
    if (!input.changeBank) return (bank: input.bank, number: input.number);
    if (selectedBank.isEmpty) manualName = input.bank;
    bank = selectedBank;
    number = input.number;
  }
  return null;
}

typedef _BankAccountDraft = ({String bank, String number, bool changeBank});

Future<String?> _showBankSelection(BuildContext context, String? bank) =>
    showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => _BankOverlay(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '은행을 선택해 주세요',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                crossAxisCount: 4,
                mainAxisExtent: 111,
                children: [
                  for (final name in _bankLogos.keys)
                    InkWell(
                      key: ValueKey('bank-$name'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, name),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _BankIcon(name: name, size: 50),
                          const SizedBox(height: 8),
                          Text(
                            bankDisplayName(name),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: bank == name
                                  ? AppColors.main
                                  : AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.selected,
                  side: _fieldOutline,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => Navigator.pop(context, ''),
                child: const Text(_manualBankLabel),
              ),
            ),
          ],
        ),
      ),
    );

class _BankOverlay extends StatelessWidget {
  const _BankOverlay({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Scaffold(
          backgroundColor: const Color(0x80121215),
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
              ),
              SafeArea(
                minimum: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: alignment,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BankAccountInput extends StatefulWidget {
  const _BankAccountInput({required this.bank, this.initialBank, this.number});

  final String bank;
  final String? initialBank;
  final String? number;

  @override
  State<_BankAccountInput> createState() => _BankAccountInputState();
}

class _BankAccountInputState extends State<_BankAccountInput> {
  late final _bank = TextEditingController(
    text: widget.initialBank ?? widget.bank,
  );
  late final _number = TextEditingController(
    text: (widget.number ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
  );

  @override
  void dispose() {
    _bank.dispose();
    _number.dispose();
    super.dispose();
  }

  void _finish({required bool changeBank}) {
    Navigator.pop(context, (
      bank: _bank.text.trim(),
      number: _number.text,
      changeBank: changeBank,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final manual = widget.bank.isEmpty;
    final enabled = _bank.text.trim().isNotEmpty && _number.text.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '계좌번호 입력',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.selected,
            shape: RoundedRectangleBorder(
              side: _fieldOutline,
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              key: const Key('change-settlement-bank'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => _finish(changeBank: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (manual)
                      const CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.text,
                        child: Icon(Icons.more_horiz),
                      )
                    else
                      _BankIcon(name: widget.bank, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        manual
                            ? _manualBankLabel
                            : bankDisplayName(widget.bank),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        AppAssets.editLight,
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (manual) ...[
            _BankInputBackground(
              child: TextField(
                key: const Key('settlement-custom-bank-name'),
                controller: _bank,
                autofocus: true,
                maxLength: 10,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration('은행·증권사 이름 (예: 키움증권)'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '목록에 없는 은행·증권사 이름을 입력해 주세요 (최대 10자)',
              style: _accountHintStyle,
            ),
            const SizedBox(height: 20),
          ],
          _BankInputBackground(
            child: TextField(
              key: const Key('settlement-account-number'),
              controller: _number,
              autofocus: !manual,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('계좌번호'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          const Text('숫자만 입력해 주세요. 하이픈(-)은 자동으로 빠져요', style: _accountHintStyle),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              backgroundColor: AppColors.main,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.selected,
              disabledForegroundColor: AppColors.text50,
              side: _fieldOutline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            key: const Key('register-settlement-account-number'),
            onPressed: enabled ? () => _finish(changeBank: false) : null,
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}

const _accountHintStyle = TextStyle(color: AppColors.text80, fontSize: 12);

InputDecoration _inputDecoration(String label) => InputDecoration(
  hintText: label,
  hintStyle: const TextStyle(color: AppColors.text80, fontSize: 14),
  counterText: '',
  isDense: true,
  constraints: const BoxConstraints(minHeight: 56),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: _fieldOutline,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Color(0xFFA8A3FF), width: 2),
  ),
);

class _BankInputBackground extends StatelessWidget {
  const _BankInputBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    child: Builder(
      builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: focused ? null : AppColors.selected,
            borderRadius: BorderRadius.circular(20),
            gradient: focused
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.selected, Color(0xE63D3B5D)],
                  )
                : null,
          ),
          child: child,
        );
      },
    ),
  );
}

class _BankIcon extends StatelessWidget {
  const _BankIcon({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'assets/bank_logos/${_bankLogos[name]}.png',
      key: ValueKey('bank-logo-$name'),
      width: size,
      height: size,
      fit: BoxFit.cover,
    ),
  );
}
