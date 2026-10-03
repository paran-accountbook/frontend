import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'receipt_scan_loading_screen.dart';
import 'register_direct_screen.dart';
import 'register_type_screen.dart';

typedef PickImageCallback = Future<void> Function(ImageSource source);

class RegisterMethodScreen extends StatelessWidget {
  const RegisterMethodScreen({
    super.key,
    this.onDirect,
    this.onPickImage,
    this.onImageSelected,
    this.financeService,
    this.onNavigationSelected,
  });

  final VoidCallback? onDirect;
  final PickImageCallback? onPickImage;
  final ValueChanged<XFile>? onImageSelected;
  final FinanceService? financeService;
  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    final direct =
        onDirect ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RegisterDirectScreen(financeService: financeService),
          ),
        );
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
                '등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 177,
              child: Text(
                '어떻게 기록할까요?',
                style: TextStyle(color: AppColors.text80, fontSize: 15),
              ),
            ),
            Positioned(
              left: 24,
              top: 366,
              child: Column(
                children: [
                  _MethodChoice(
                    iconAsset: AppAssets.registerCamera,
                    label: '카메라로 촬영',
                    onTap: () =>
                        unawaited(_pickImage(context, ImageSource.camera)),
                  ),
                  const SizedBox(height: 20),
                  _MethodChoice(
                    iconAsset: AppAssets.registerGallery,
                    label: '갤러리에서 선택',
                    onTap: () =>
                        unawaited(_pickImage(context, ImageSource.gallery)),
                  ),
                  const SizedBox(height: 20),
                  _MethodChoice(
                    iconAsset: AppAssets.registerEdit,
                    label: '직접 등록',
                    onTap: direct,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 2,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget destination = switch (index) {
      0 => HomeScreen(financeService: financeService),
      1 => LedgerScreen(financeService: financeService),
      2 => RegisterTypeScreen(financeService: financeService),
      3 => AnalysisOverviewScreen(financeService: financeService),
      _ => ProfileScreen(financeService: financeService),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (onPickImage case final callback?) {
      await callback(source);
      return;
    }
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: false,
      );
      if (image == null || !context.mounted) return;
      if (onImageSelected case final callback?) {
        callback(image);
        return;
      }
      final useImage = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              ReceiptImageConfirmationScreen(image: image, source: source),
        ),
      );
      if (useImage != true || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScanLoadingScreen(
            imagePath: image.path,
            imageSource: source,
            financeService: financeService,
          ),
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('Failed to open native image picker', error, stackTrace);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사진 접근 권한이 필요합니다'),
          content: const Text('iPhone 설정에서 카메라 또는 사진 권한을 허용한 뒤 다시 시도해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}

class ReceiptImageConfirmationScreen extends StatelessWidget {
  const ReceiptImageConfirmationScreen({
    required this.image,
    required this.source,
    this.previewImage,
    super.key,
  });

  final XFile image;
  final ImageSource source;
  final ImageProvider? previewImage;

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
              tooltip: '뒤로가기',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(AppAssets.arrowBackLight),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            top: 80,
            child: Column(
              children: [
                Text(
                  '촬영 확인',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  '영수증 글자가 또렷한지 확인해 주세요',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            top: 153,
            width: 354,
            height: 593,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: Image(
                  image: previewImage ?? FileImage(File(image.path)),
                  width: 354,
                  height: 593,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.secondary,
                    child: Center(
                      child: Icon(
                        Icons.receipt_long,
                        color: AppColors.text50,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Row(
              children: [
                Expanded(
                  child: _ConfirmationButton(
                    key: const Key('receipt-image-retry'),
                    onPressed: () => Navigator.pop(context, false),
                    label: source == ImageSource.camera ? '다시 촬영' : '다시 선택',
                    primary: false,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _ConfirmationButton(
                    key: const Key('receipt-image-use'),
                    onPressed: () => Navigator.pop(context, true),
                    label: '이 사진 사용',
                    primary: true,
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

class _ConfirmationButton extends StatelessWidget {
  const _ConfirmationButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? AppColors.main : AppColors.selected,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.text20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({
    required this.iconAsset,
    required this.label,
    this.onTap,
  });
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 354,
        height: 34,
        child: Row(
          children: [
            SizedBox(width: 34, height: 34, child: SvgPicture.asset(iconAsset)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const AppChevron(color: AppColors.text80),
          ],
        ),
      ),
    );
  }
}
