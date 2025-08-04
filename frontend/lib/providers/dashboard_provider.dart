import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the currently selected page index in the dashboard.
final dashboardPageIndexProvider = StateProvider<int>((ref) => 0);

/// Provider to manage the online status of the business.
final businessOnlineStatusProvider = StateProvider<bool>((ref) => true);
