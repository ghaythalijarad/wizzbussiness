/// Design System Usage Examples
/// 
/// This file demonstrates how to use the new design system components
/// throughout the Flutter app. It serves as a reference and testing
/// ground for all design system components.

import 'package:flutter/material.dart';

// Direct imports to avoid circular dependency issues
import '../core/design_system/spacing_system.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';

import '../core/design_system/themes/button_themes.dart';
import '../core/design_system/themes/card_themes.dart';
import '../core/design_system/themes/navigation_themes.dart';
import '../core/theme/app_colors.dart';

class DesignSystemExamplesScreen extends StatefulWidget {
  const DesignSystemExamplesScreen({super.key});

  @override
  State<DesignSystemExamplesScreen> createState() => _DesignSystemExamplesScreenState();
}

class _DesignSystemExamplesScreenState extends State<DesignSystemExamplesScreen> {
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
          padding: EdgeInsets.all(GoldenRatio.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacing Examples
              _buildSectionTitle('Spacing System'),
              _buildSpacingExamples(),
              
              SizedBox(height: GoldenRatio.xl),
              
              // Typography Examples
              _buildSectionTitle('Typography System'),
              _buildTypographyExamples(),
              
              SizedBox(height: GoldenRatio.xl),
              
              // Button Examples
              _buildSectionTitle('Button Themes'),
              _buildButtonExamples(),
              
              SizedBox(height: GoldenRatio.Xl,
              
              // Card Examples
              _buildSectionTitle('Card Themes'),
              _buildCardExamples(),
              
              SizedBox(height: GoldenRatio.Xl,
              
              // Navigation Examples
              _buildSectionTitle('Navigation Themes'),
              _buildNavigationExamples(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.all(allMd,
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
        SizedBox(height: GoldenRatio.Sm,
        _buildSpacingDemo('Extra Small (xs)', EdgeInsets.all(xs),
        SizedBox(height: GoldenRatio.Sm,
        _buildSpacingDemo('Small (sm)', EdgeInsets.all(sm),
        SizedBox(height: GoldenRatio.Sm,
        _buildSpacingDemo('Medium (md)', EdgeInsets.all(md),
        SizedBox(height: GoldenRatio.Sm,
        _buildSpacingDemo('Large (lg)', EdgeInsets.all(lg),
        SizedBox(height: GoldenRatio.Sm,
        _buildSpacingDemo('Extra Large (xl)', EdgeInsets.all(xl),
        SizedBox(height: GoldenRatio.Sm,
        
        SizedBox(height: GoldenRatio.Md,
        
        Text('Spacing Widgets:', style: TypographySystem.titleMedium),
        SizedBox(height: GoldenRatio.Sm,
        
        Row(
          children: [
            Container(
              width: 50,
              height: 30,
              color: AppColors.primary.withOpacity(0.3),
              child: const Center(child: Text('A')),
            ),
            SizedBox(width: GoldenRatio.Sm,
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
        SizedBox(width: 100, child: Text(label, style: TypographySystem.bodyMedium)),
        Container(
          width: spacing,
          height: 20,
          color: AppColors.primary.withOpacity(0.5),
        ),
        SizedBox(width: GoldenRatio.Sm,
        Text('${spacing.toInt()}px', style: TypographySystem.bodySmall),
      ],
    );
  }

  Widget _buildTypographyExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: TypographySystem.displayLarge),
        SizedBox(height: GoldenRatio.Sm,
        Text('Headline Large', style: TypographySystem.headlineLarge),
        SizedBox(height: GoldenRatio.Sm,
        Text('Title Large', style: TypographySystem.titleLarge),
        SizedBox(height: GoldenRatio.Sm,
        Text('Body Large', style: TypographySystem.bodyLarge),
        SizedBox(height: GoldenRatio.Sm,
        Text('Label Large', style: TypographySystem.labelLarge),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: EdgeInsets.all(sm,
          runSpacing: EdgeInsets.all(sm,
          children: [
            ButtonThemes.primary(
              text: 'Primary Button',
              onPressed: () {},
            ),
            ButtonThemes.secondary(
              text: 'Secondary Button',
              onPressed: () {},
            ),
            ButtonThemes.outline(
              text: 'Outline Button',
              onPressed: () {},
            ),
          ],
        ),
        SizedBox(height: GoldenRatio.Md,
        Wrap(
          spacing: EdgeInsets.all(sm,
          runSpacing: EdgeInsets.all(sm,
          children: [
            ButtonThemes.primaryIcon(
              text: 'With Icon',
              icon: Icons.star,
              onPressed: () {},
            ),
            ButtonThemes.secondaryIcon(
              text: 'Secondary Icon',
              icon: Icons.favorite,
              onPressed: () {},
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
              SizedBox(height: GoldenRatio.Sm,
              Text('This is a standard card with basic elevation.', 
                   style: TypographySystem.bodyMedium),
            ],
          ),
          onTap: () {},
        ),
        SizedBox(height: GoldenRatio.Md,
        CardThemes.elevatedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elevated Card', style: TypographySystem.titleMedium),
              SizedBox(height: GoldenRatio.Sm,
              Text('This card has higher elevation for emphasis.', 
                   style: TypographySystem.bodyMedium),
            ],
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildNavigationExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Breadcrumb Navigation:', style: TypographySystem.titleMedium),
        SizedBox(height: GoldenRatio.Sm,
        NavigationThemes.breadcrumb(
          items: const ['Home', 'Products', 'Electronics', 'Smartphones'],
          onTap: (index) => debugPrint('Breadcrumb tapped: $index'),
        ),
        SizedBox(height: GoldenRatio.Md,
        
        Text('Pill Tab Bar:', style: TypographySystem.titleMedium),
        SizedBox(height: GoldenRatio.Sm,
        NavigationThemes.pillTabBar(
          tabs: const ['All', 'Active', 'Completed', 'Archived'],
          selectedIndex: 0,
          onTap: (index) => debugPrint('Tab tapped: $index'),
        ),
      ],
    );
  }
}
