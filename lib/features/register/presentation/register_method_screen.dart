import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import 'receipt_scan_loading_screen.dart';
import 'register_direct_screen.dart';

typedef PickImageCallback = Future<void> Function(ImageSource source);

class RegisterMethodScreen extends StatelessWidget {
  const RegisterMethodScreen({
    super.key,
    this.onDirect,
    this.onPickImage,
    this.onImageSelected,
    this.financeService,
  });

  final VoidCallback? onDirect;
  final PickImageCallback? onPickImage;
  final ValueChanged<XFile>? onImageSelected;
  final FinanceService? financeService;

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
              top: 392,
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
            const Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
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
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScanLoadingScreen(
            imagePath: image.path,
            financeService: financeService,
          ),
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('Failed to open native image picker', error, stackTrace);
    }
  }
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
            const Text(
              '〉',
              style: TextStyle(color: AppColors.text80, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
