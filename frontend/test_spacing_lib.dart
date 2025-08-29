// Simple test to check spacing system imports
library test_spacing_imports;

import 'lib/core/design_system/spacing_system.dart';

class TestSpacingImports {
  static void test() {
    // Test SpacingSystem access
    final padding = SpacingSystem.allMd;

    // Test SpacingWidgets access
    final spacing = SpacingWidgets.verticalSm;

    print('SpacingSystem test: ${padding.toString()}');
    print('SpacingWidgets test: ${spacing.toString()}');
  }
}
