import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

SnackBar appSuccessToast(String message) => SnackBar(
  behavior: SnackBarBehavior.floating,
  elevation: 0,
  margin: const EdgeInsets.fromLTRB(24, 0, 24, 120),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  backgroundColor: AppColors.outline,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  content: Row(
    children: [
      SvgPicture.asset(AppAssets.toastSuccess, width: 20, height: 20),
      const SizedBox(width: 10),
      Text(
        message,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
);
