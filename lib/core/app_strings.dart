
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'en': {
      'app_name': 'LiftCare Pro',
      'dashboard': 'Dashboard',
      'customers': 'Customers',
      'lifts': 'Lifts',
      'technicians': 'Technicians',
      'service_reports': 'Service Reports',
      'settings': 'Settings',
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'company': 'Company',
      'service_date': 'Service Date',
      'next_service': 'Next Service',
      'save': 'Save',
      'cancel': 'Cancel',
      'english': 'English',
      'malayalam': 'Malayalam',
    },
    'ml': {
      'app_name': 'LiftCare Pro',
      'dashboard': 'ഡാഷ്ബോർഡ്',
      'customers': 'കസ്റ്റമർമാർ',
      'lifts': 'ലിഫ്റ്റുകൾ',
      'technicians': 'ടെക്നീഷ്യൻമാർ',
      'service_reports': 'സർവീസ് റിപ്പോർട്ടുകൾ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'login': 'ലോഗിൻ',
      'logout': 'ലോഗ് ഔട്ട്',
      'email': 'ഇമെയിൽ',
      'password': 'പാസ്‌വേഡ്',
      'company': 'കമ്പനി',
      'service_date': 'സർവീസ് തീയതി',
      'next_service': 'അടുത്ത സർവീസ്',
      'save': 'സേവ് ചെയ്യുക',
      'cancel': 'റദ്ദാക്കുക',
      'english': 'ഇംഗ്ലീഷ്',
      'malayalam': 'മലയാളം',
    },
  };

  static String get(String language, String key) {
    return values[language]?[key] ??
        values['en']?[key] ??
        key;
  }
}
