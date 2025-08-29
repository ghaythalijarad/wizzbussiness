import 'package:flutter/material.dart';
import '../core/design_system/spacing_system.dart';
import '../core/design_system/typography_system.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/themes/button_themes.dart';
import '../core/design_system/themes/card_themes.dart';
import '../core/theme/app_colors.dart';

/// Example screen demonstrating the Material Design 3 + Golden Ratio design system
class DesignSystemExampleScreen extends StatelessWidget {
  const DesignSystemExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Examples'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(GoldenRatio.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacing Examples
              _buildSectionTitle('Spacing System'),
              _buildSpacingExamples(),

              const SizedBox(height: GoldenRatio.xl),

              // Typography Examples
              _buildSectionTitle('Typography System'),
              _buildTypographyExamples(),

              const SizedBox(height: GoldenRatio.xl),

              // Button Examples
              _buildSectionTitle('Button Themes'),
              _buildButtonExamples(),

              const SizedBox(height: GoldenRatio.xl),

              // Card Examples
              _buildSectionTitle('Card Themes'),
              _buildCardExamples(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(GoldenRatio.md),
      child: Text(
        title,
        style: TypographySystem.headlineMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSpacingExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spacing Values:', style: TypographySystem.titleMedium),
        const SizedBox(height: GoldenRatio.sm),
        _buildSpacingDemo('Extra Small (xs)', GoldenRatio.xs),
        const SizedBox(height: GoldenRatio.sm),
        _buildSpacingDemo('Small (sm)', GoldenRatio.sm),
        const SizedBox(height: GoldenRatio.sm),
        _buildSpacingDemo('Medium (md)', GoldenRatio.md),
        const SizedBox(height: GoldenRatio.sm),
        _buildSpacingDemo('Large (lg)', GoldenRatio.lg),
        const SizedBox(height: GoldenRatio.sm),
        _buildSpacingDemo('Extra Large (xl)', GoldenRatio.xl),
        const SizedBox(height: GoldenRatio.sm),
        const SizedBox(height: GoldenRatio.md),
        Text('Spacing Widgets:', style: TypographySystem.titleMedium),
        const SizedBox(height: GoldenRatio.sm),
        Row(
          children: [
            Container(
              width: 50,
              height: 30,
              color: AppColors.primary.withOpacity(0.3),
              child: const Center(child: Text('A')),
            ),
            const SizedBox(width: GoldenRatio.sm),
            Container(
              width: 50,
              height: 30,
              color: AppColors.secondary.withOpacity(0.3),
              child: const Center(child: Text('B')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingDemo(String label, double spacing) {
    return Row(
      children: [
        SizedBox(
            width: 100, child: Text(label, style: TypographySystem.bodyMedium)),
        Container(
          width: spacing,
          height: 20,
          color: AppColors.primary.withOpacity(0.5),
        ),
        const SizedBox(width: GoldenRatio.sm),
        Text('${spacing.toInt()}px', style: TypographySystem.bodySmall),
      ],
    );
  }

  Widget _buildTypographyExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: TypographySystem.displayLarge),
        const SizedBox(height: GoldenRatio.sm),
        Text('Headline Large', style: TypographySystem.headlineLarge),
        const SizedBox(height: GoldenRatio.sm),
        Text('Title Large', style: TypographySystem.titleLarge),
        const SizedBox(height: GoldenRatio.sm),
        Text('Body Large', style: TypographySystem.bodyLarge),
        const SizedBox(height: GoldenRatio.sm),
        Text('Label Large', style: TypographySystem.labelLarge),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      children: [
        Wrap(
          spacing: GoldenRatio.sm,
          runSpacing: GoldenRatio.sm,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ButtonThemes.primaryElevatedButton,
              child: const Text('Primary Button'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ButtonThemes.secondaryElevatedButton,
              child: const Text('Secondary Button'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: ButtonThemes.primaryOutlinedButton,
              child: const Text('Outline Button'),
            ),
          ],
        ),
        const SizedBox(height: GoldenRatio.md),
        Wrap(
          spacing: GoldenRatio.sm,
          runSpacing: GoldenRatio.sm,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              style: ButtonThemes.primaryElevatedButton,
              icon: const Icon(Icons.star),
              label: const Text('With Icon'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              style: ButtonThemes.secondaryElevatedButton,
              icon: const Icon(Icons.favorite),
              label: const Text('Secondary Icon'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardExamples() {
    return Column(
      children: [
        CardThemes.standardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Standard Card', style: TypographySystem.titleMedium),
              const SizedBox(height: GoldenRatio.sm),
              Text('This is a standard card with basic elevation.',
                  style: TypographySystem.bodyMedium),
            ],
          ),
          onTap: () {},
        ),
        const SizedBox(height: GoldenRatio.md),
        CardThemes.elevatedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elevated Card', style: TypographySystem.titleMedium),
              const SizedBox(height: GoldenRatio.sm),
              Text('This card has higher elevation for emphasis.',
                  style: TypographySystem.bodyMedium),
            ],
          ),
          onTap: () {},
        ),
      ],
    );
  }
}
