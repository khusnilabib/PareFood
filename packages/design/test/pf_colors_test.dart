import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_design/pare_design.dart';

void main() {
  group('PfColors', () {
    test('exposes fixed light brand tokens', () {
      expect(PfColors.primaryLight, const Color(0xFFE6382C));
      expect(PfColors.onPrimaryLight, const Color(0xFFFFFFFF));
      expect(PfColors.secondaryLight, const Color(0xFFE8630C));
      expect(PfColors.tertiaryLight, const Color(0xFF2E7D32));
      expect(PfColors.surfaceLight, const Color(0xFFF7F2EF));
      expect(PfColors.surfaceContainerLight, const Color(0xFFF5EDEA));
      expect(PfColors.errorLight, const Color(0xFFBA1A1A));
      expect(PfColors.onSurfaceLight, const Color(0xFF221A19));
      expect(PfColors.onSurfaceVariantLight, const Color(0xFF857370));
      expect(PfColors.outlineLight, const Color(0xFF9A8682));
    });

    test('exposes fixed dark brand tokens', () {
      expect(PfColors.primaryDark, const Color(0xFFFFB4AB));
      expect(PfColors.onPrimaryDark, const Color(0xFF690005));
      expect(PfColors.secondaryDark, const Color(0xFFFFB77B));
      expect(PfColors.tertiaryDark, const Color(0xFF81C784));
      expect(PfColors.surfaceDark, const Color(0xFF201A19));
      expect(PfColors.surfaceContainerDark, const Color(0xFF2B2321));
      expect(PfColors.errorDark, const Color(0xFFFFB4AB));
      expect(PfColors.onSurfaceDark, const Color(0xFFF0DFDC));
      expect(PfColors.onSurfaceVariantDark, const Color(0xFFD5C2BF));
      expect(PfColors.outlineDark, const Color(0xFF9A8682));
    });
  });
}
