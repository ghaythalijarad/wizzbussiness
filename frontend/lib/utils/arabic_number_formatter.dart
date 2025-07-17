import 'package:flutter/services.dart';

/// Input formatter that converts Western/Latin numerals to Arabic-Indic numerals
/// and restricts input to only Arabic numbers (٠١٢٣٤٥٦٧٨٩)
class ArabicNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert Western numerals to Arabic-Indic numerals
    String convertedText = _convertToArabicNumbers(newValue.text);
    
    // Filter out any non-Arabic numerals
    String filteredText = convertedText.replaceAll(RegExp(r'[^٠-٩]'), '');
    
    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }

  /// Converts Western numerals (0-9) to Arabic-Indic numerals (٠-٩)
  String _convertToArabicNumbers(String input) {
    const westernToArabic = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    String result = input;
    westernToArabic.forEach((western, arabic) {
      result = result.replaceAll(western, arabic);
    });

    return result;
  }
}

/// Validator for Arabic phone numbers (Iraqi format)
class ArabicPhoneValidator {
  /// Validates Iraqi phone numbers in Arabic-Indic numerals
  /// Expected formats:
  /// - Mobile: ٠٧٧xxxxxxx, ٠٧٨xxxxxxx, ٠٧٩xxxxxxx (11 digits starting with ٠٧٧/٧٨/٧٩)
  /// - Landline: ٠١xxxxxxx (9 digits starting with ٠١)
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    // Remove any spaces or special characters except Arabic numbers
    String cleanNumber = value.replaceAll(RegExp(r'[^٠-٩]'), '');

    // Check for exact 10 digits (without country code ٩٦٤)
    if (cleanNumber.length == 10) {
      // Mobile numbers should start with ٧٧, ٧٨, or ٧٩
      if (cleanNumber.startsWith('٧٧') || 
          cleanNumber.startsWith('٧٨') || 
          cleanNumber.startsWith('٧٩')) {
        return null; // Valid mobile number
      }
    }

    // Check for 11 digits with ٠ prefix
    if (cleanNumber.length == 11) {
      if (cleanNumber.startsWith('٠٧٧') || 
          cleanNumber.startsWith('٠٧٨') || 
          cleanNumber.startsWith('٠٧٩')) {
        return null; // Valid mobile number with ٠ prefix
      }
    }

    // Check for landline (9 digits starting with ٠١)
    if (cleanNumber.length == 9 && cleanNumber.startsWith('٠١')) {
      return null; // Valid landline
    }

    return 'يرجى إدخال رقم عراقي صحيح (٧٧X/٧٨X/٧٩X للجوال)';
  }

  /// Formats the phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^٠-٩]'), '');
    
    if (cleanNumber.length == 10) {
      // Format as: ٧٧XX XXX XXX
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7)}';
    } else if (cleanNumber.length == 11) {
      // Format as: ٠٧٧X XXX XXX
      return '${cleanNumber.substring(0, 5)} ${cleanNumber.substring(5, 8)} ${cleanNumber.substring(8)}';
    }
    
    return cleanNumber;
  }
}
