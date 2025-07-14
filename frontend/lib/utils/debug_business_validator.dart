import '../models/business.dart';

class DebugBusinessValidator {
  /// Validate business object and provide detailed diagnostics
  static Map<String, dynamic> validateBusiness(Business business) {
    final issues = <String>[];
    final warnings = <String>[];
    final info = <String>[];

    // Check business ID
    if (business.id.isEmpty) {
      issues.add('Business ID is empty');
    } else if (business.id == 'unknown-id') {
      issues.add('Business ID is "unknown-id" - indicates JSON parsing issue');
    } else if (business.id == 'test-id') {
      warnings.add('Business ID is "test-id" - this is a test/debug business');
    } else {
      info.add('Business ID looks valid: ${business.id}');
    }

    // Check business name
    if (business.name.isEmpty || business.name == 'Unknown Business') {
      warnings.add('Business name is empty or default');
    } else {
      info.add('Business name: ${business.name}');
    }

    // Check email
    if (business.email.isEmpty) {
      warnings.add('Business email is empty');
    } else {
      info.add('Business email: ${business.email}');
    }

    // Check business type
    info.add('Business type: ${business.businessType}');

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'info': info,
      'summary': {
        'id': business.id,
        'name': business.name,
        'email': business.email,
        'type': business.businessType.toString(),
      }
    };
  }

  /// Print detailed business validation report
  static void printValidationReport(Business business, {String? context}) {
    final report = validateBusiness(business);
    final contextStr = context != null ? '[$context] ' : '';

    print('${contextStr}=== BUSINESS VALIDATION REPORT ===');
    print('${contextStr}Business Summary: ${report['summary']}');

    if (report['issues'].isNotEmpty) {
      print('${contextStr}🚨 ISSUES:');
      for (String issue in report['issues']) {
        print('${contextStr}  - $issue');
      }
    }

    if (report['warnings'].isNotEmpty) {
      print('${contextStr}⚠️  WARNINGS:');
      for (String warning in report['warnings']) {
        print('${contextStr}  - $warning');
      }
    }

    if (report['info'].isNotEmpty) {
      print('${contextStr}ℹ️  INFO:');
      for (String infoItem in report['info']) {
        print('${contextStr}  - $infoItem');
      }
    }

    print('${contextStr}Status: ${report['isValid'] ? 'VALID' : 'INVALID'}');
    print('${contextStr}=====================================');
  }

  /// Quick validation check - returns true if business is valid for API calls
  static bool isValidForApi(Business business) {
    return business.id.isNotEmpty &&
        business.id != 'unknown-id' &&
        business.name.isNotEmpty &&
        business.name != 'Unknown Business';
  }
}
