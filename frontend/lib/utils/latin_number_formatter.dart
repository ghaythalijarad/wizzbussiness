import 'package:flutter/services.dart';

/// Input formatter that ensures phone numbers use Western/Latin numerals (0-9)
/// and maintains left-to-right text direction
class LatinNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert Arabic-Indic numerals to Western numerals
    String convertedText = _convertToLatinNumbers(newValue.text);

    // Filter out any non-Latin numerals and allow only basic phone formatting
    String filteredText =
        convertedText.replaceAll(RegExp(r'[^0-9\+\-\s\(\)]'), '');

    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }

  /// Converts Arabic-Indic numerals (٠-٩) to Western numerals (0-9)
  String _convertToLatinNumbers(String input) {
    const arabicToWestern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    String result = input;
    arabicToWestern.forEach((arabic, western) {
      result = result.replaceAll(arabic, western);
    });

    return result;
  }
}

/// Validator for phone numbers using Latin numerals (Iraqi format)
class LatinPhoneValidator {
  /// Validates Iraqi phone numbers in Western numerals
  /// Expected formats:
  /// - Mobile: 077xxxxxxx, 078xxxxxxx, 079xxxxxxx (10 digits starting with 077/078/079)
  /// - Mobile with prefix: 0077xxxxxxx, 0078xxxxxxx, 0079xxxxxxx (11 digits)
  /// - Landline: 01xxxxxxx (9 digits starting with 01)
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces or special characters except Western numbers
    String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check for exact 10 digits (without country code 964)
    if (cleanNumber.length == 10) {
      // Mobile numbers should start with 77, 78, or 79
      if (cleanNumber.startsWith('77') ||
          cleanNumber.startsWith('78') ||
          cleanNumber.startsWith('79')) {
        return null; // Valid mobile number
      }
    }

    // Check for 11 digits with 0 prefix
    if (cleanNumber.length == 11) {
      if (cleanNumber.startsWith('077') ||
          cleanNumber.startsWith('078') ||
          cleanNumber.startsWith('079')) {
        return null; // Valid mobile number with 0 prefix
      }
    }

    // Check for landline (9 digits starting with 01)
    if (cleanNumber.length == 9 && cleanNumber.startsWith('01')) {
      return null; // Valid landline
    }

    return 'Please enter a valid Iraqi number (77X/78X/79X for mobile)';
  }

  /// Formats the phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.length == 10) {
      // Format as: 77XX XXX XXX
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7)}';
    } else if (cleanNumber.length == 11) {
      // Format as: 077X XXX XXX
      return '${cleanNumber.substring(0, 5)} ${cleanNumber.substring(5, 8)} ${cleanNumber.substring(8)}';
    }

    return cleanNumber;
  }
}
