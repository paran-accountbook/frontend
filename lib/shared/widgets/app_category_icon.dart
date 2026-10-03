import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

class AppCategoryIcon extends StatelessWidget {
  const AppCategoryIcon({super.key, this.category, this.slotSize = 26});

  final String? category;
  final double slotSize;

  @override
  Widget build(BuildContext context) {
    final (width, height) = switch (category) {
      '식비' || null => (14.0, 20.0),
      '카페' || '카페/간식' || '기타' => (26.0, 26.0),
      '쇼핑' || '문화' || '문화/여가' || '의료' || '건강' || '의료/건강' => (18.0, 18.0),
      '교통' || '교통/차량' => (20.0, 20.0),
      '교육' => (24.0, 16.0),
      _ => (14.0, 20.0),
    };
    return SizedBox.square(
      dimension: slotSize,
      child: Center(
        child: SvgPicture.asset(
          AppAssets.categoryIconFor(category),
          width: width,
          height: height,
        ),
      ),
    );
  }
}
