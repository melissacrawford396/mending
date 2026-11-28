import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/body_area.dart';

/// The outline for a body area. Files live in the repo's `body-icons/` folder.
String bodyIconAsset(BodyArea area) {
  final name = switch (area) {
    BodyArea.upperBack => 'upper-back',
    BodyArea.lowerBack => 'lower-back',
    BodyArea.wholeBody => 'whole-body',
    _ => area.name,
  };
  return 'assets/body-icons/$name.svg';
}

class BodyAreaIcon extends StatelessWidget {
  const BodyAreaIcon({super.key, required this.area, this.size = 40});

  final BodyArea area;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: area.label,
      child: SvgPicture.asset(
        bodyIconAsset(area),
        width: size,
        height: size,
        semanticsLabel: area.label,
      ),
    );
  }
}
