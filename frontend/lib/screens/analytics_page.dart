import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  final Business? business;
  final List<Order>? orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const AnalyticsPage({
    Key? key,
    this.business,
    this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveHelper.isMobile(context)
                      ? GoldenRatio.spacing12
                      : GoldenRatio.spacing16),
                  child: Column(
                    children: [
                      // Stats Cards
                      _buildStatsGrid(context, loc),
                      SizedBox(height: GoldenRatio.spacing24),

                      // Charts Section
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 300,
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: _buildChartsSection(context, loc),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppLocalizations loc) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
          isMobile ? GoldenRatio.spacing12 : GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          double childAspectRatio;

          if (constraints.maxWidth < 600) {
            // Mobile: 2 columns
            crossAxisCount = 2;
            childAspectRatio = 1.0;
          } else if (constraints.maxWidth < 900) {
            // Tablet: 2 columns
            crossAxisCount = 2;
            childAspectRatio = 1.3;
          } else {
            // Desktop: 4 columns
            crossAxisCount = 4;
            childAspectRatio = 1.1;
          }
          
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing:
                isMobile ? GoldenRatio.spacing12 : GoldenRatio.spacing20,
            crossAxisSpacing:
                isMobile ? GoldenRatio.spacing12 : GoldenRatio.spacing20,
            children: [
              _buildStatCard(
                title: loc.totalOrders,
                value: '1,234',
                icon: Icons.shopping_cart_rounded,
                color: AppColors.primary,
              ),
              _buildStatCard(
                title: loc.revenue,
                value: '\$12,345',
                icon: Icons.attach_money_rounded,
                color: AppColors.secondary,
              ),
              _buildStatCard(
                title: 'Active Products',
                value: '89',
                icon: Icons.inventory_2_rounded,
                color: AppColors.info,
              ),
              _buildStatCard(
                title: 'Customers',
                value: '567',
                icon: Icons.people_rounded,
                color: AppColors.success,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        color: AppColors.surface,
        shadowColor: color.withOpacity(0.2),
        child: InkWell(
          onTap: () {
            // Handle analytics card tap if needed
          },
          borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
          child: Container(
            padding: EdgeInsets.all(GoldenRatio.spacing16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  color.withOpacity(0.02),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 120;
                final iconSize =
                    isSmall ? GoldenRatio.spacing20 : GoldenRatio.spacing24;
                final spacing =
                    isSmall ? GoldenRatio.spacing8 : GoldenRatio.spacing12;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(isSmall
                            ? GoldenRatio.spacing8
                            : GoldenRatio.spacing12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.1),
                              color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(GoldenRatio.radiusLg),
                        ),
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: color,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TypographySystem.headlineSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmall ? 18 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing4),
                    Flexible(
                      child: Text(
                        title,
                        style: TypographySystem.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: isSmall ? 12 : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, AppLocalizations loc) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: GoldenRatio.spacing4),
          child: Text(
            'Sales Overview',
            style: TypographySystem.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: GoldenRatio.spacing16),
        
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
                isMobile ? GoldenRatio.spacing16 : GoldenRatio.spacing24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.04),
                  blurRadius: GoldenRatio.spacing20,
                  offset: Offset(0, GoldenRatio.spacing8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveHelper.isDesktop(context)
                              ? 500
                              : double.infinity,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? GoldenRatio.spacing16 : GoldenRatio.spacing20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.secondary.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
                              ),
                              child: Icon(
                                Icons.analytics_rounded,
                                size: isMobile ? GoldenRatio.spacing24 * 1.5 : GoldenRatio.spacing24 * 2,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: GoldenRatio.spacing20),
                            FittedBox(
                              child: Text(
                                'Analytics Chart',
                                style: TypographySystem.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(height: GoldenRatio.spacing8),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: GoldenRatio.spacing16),
                              child: Text(
                                'Chart visualization will be implemented here',
                                style: TypographySystem.bodyLarge.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: GoldenRatio.spacing24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(GoldenRatio.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: GoldenRatio.spacing12,
                                    offset:
                                        Offset(0, GoldenRatio.spacing8 * 0.75),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Handle chart interaction
                                  },
                                  borderRadius: BorderRadius.circular(
                                      GoldenRatio.radiusLg),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile
                                          ? GoldenRatio.spacing20
                                          : GoldenRatio.spacing24,
                                      vertical: GoldenRatio.spacing16,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              GoldenRatio.spacing8 * 0.75),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            borderRadius: BorderRadius.circular(
                                                GoldenRatio.spacing8),
                                          ),
                                          child: Icon(
                                            Icons.show_chart,
                                            color: AppColors.onSecondary,
                                            size: GoldenRatio.spacing18,
                                          ),
                                        ),
                                        SizedBox(width: GoldenRatio.spacing12),
                                        Flexible(
                                          child: Text(
                                            'View Details',
                                            style: TypographySystem.titleMedium
                                                .copyWith(
                                              color: AppColors.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
