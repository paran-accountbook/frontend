import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'register_direct_screen.dart';

typedef PickImageCallback = Future<void> Function(ImageSource source);

class RegisterMethodScreen extends StatelessWidget {
  const RegisterMethodScreen({
    super.key,
    this.onDirect,
    this.onPickImage,
    this.onImageSelected,
  });

  final VoidCallback? onDirect;
  final PickImageCallback? onPickImage;
  final ValueChanged<XFile>? onImageSelected;

  @override
  Widget build(BuildContext context) {
    final direct =
        onDirect ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RegisterDirectScreen()),
        );
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 144,
              child: Text(
                '등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: 46,
              top: 250,
              child: Text(
                '어떻게 기록할까요?',
                style: TextStyle(color: AppColors.text80, fontSize: 29),
              ),
            ),
            Positioned(
              left: 57,
              top: 696,
              child: _MethodChoice(
                icon: Icons.camera_alt,
                label: '카메라로 촬영',
                onTap: () => unawaited(_pickImage(ImageSource.camera)),
              ),
            ),
            Positioned(
              left: 57,
              top: 794,
              child: _MethodChoice(
                icon: Icons.image,
                label: '갤러리에서 선택',
                onTap: () => unawaited(_pickImage(ImageSource.gallery)),
              ),
            ),
            Positioned(
              left: 57,
              top: 894,
              child: _MethodChoice(
                icon: Icons.edit,
                label: '직접 등록',
                onTap: direct,
              ),
            ),
            const Positioned(
              left: 0,
              top: 1459,
              child: AppBottomNavigation(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (onPickImage case final callback?) {
      await callback(source);
      return;
    }

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: false,
      );
      if (image != null) onImageSelected?.call(image);
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('Failed to open native image picker', error, stackTrace);
    }
  }
}

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 642,
        height: 80,
        child: Row(
          children: [
            SizedBox(
              width: 47,
              child: Icon(icon, color: AppColors.text, size: 45),
            ),
            const SizedBox(width: 30),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 39,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text('〉', style: TextStyle(color: AppColors.text50, fontSize: 44)),
          ],
        ),
      ),
    );
  }
}
