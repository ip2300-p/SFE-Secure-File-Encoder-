import '../main.dart' show languageNotifier;

/// سرویس ساده‌ی چندزبانه بدون نیاز به پکیج‌های سنگین intl/ARB.
/// همه‌ی متن‌های رابط کاربری از اینجا خونده میشن تا اضافه کردن زبان جدید
/// در آینده فقط نیاز به اضافه کردن یه Map جدید داشته باشه.
class AppStrings {
  static String get _lang => languageNotifier.value;

  static String t(String key) {
    return _strings[_lang]?[key] ?? _strings['fa']![key] ?? key;
  }

  static String mbLabel(int mb) => '$mb ${t('mb_unit')}';

  static String filesSelectedLabel(int count) {
    if (_lang == 'en') {
      return '$count file${count == 1 ? '' : 's'} selected';
    }
    return '$count فایل انتخاب شده';
  }

  static const Map<String, Map<String, String>> _strings = {
    'fa': {
      'app_title': 'SFE',
      'settings_tooltip': 'تنظیمات',
      'no_files_yet': 'هنوز فایلی انتخاب نشده',
      'add_file': 'افزودن فایل',
      'clear_list_tooltip': 'پاک کردن لیست',
      'output_dir_not_chosen': 'پوشه‌ی ذخیره‌ی خروجی: انتخاب نشده (بعداً دستی می‌پرسیم)',
      'choose_output_dir_title': 'انتخاب پوشه‌ی ذخیره‌ی خروجی',
      'password_label': 'رمز عبور',
      'use_secondary_password': 'استفاده از رمز دوم',
      'secondary_password_label': 'رمز دوم',
      'delete_source_title': 'حذف فایل‌های اصلی بعد از اتمام',
      'delete_source_subtitle': 'محدودیت فعلی: فقط کش داخلی اپ رو پاک می‌کنه، نه فایل واقعی',
      'delete_confirm_title': '⚠️ حذف فایل‌های اصلی',
      'delete_confirm_body':
          'به‌خاطر یه محدودیت شناخته‌شده در اندروید، این گزینه فعلاً فقط نسخه‌ی '
              'کش‌شده‌ی داخلی اپ رو حذف می‌کنه، نه فایل اصلی توی گالری/Downloads. '
              'حذف واقعی فایل اصلی در آپدیت بعدی اضافه میشه.\n\n'
              'همچنان می‌خوای فعالش کنی؟',
      'cancel': 'انصراف',
      'confirm_exit_title': '⚠️ عملیات هنوز تمام نشده',
      'confirm_exit_message':
          'یه عملیات رمزنگاری/رمزگشایی هنوز در حال اجراست. اگه الان خارج بشی، ممکنه فایل ناقص بمونه. مطمئنی؟',
      'confirm_exit_leave': 'بله، خارج شو',
      'default_output_dir_title': 'پوشه‌ی پیش‌فرض ذخیره',
      'default_output_dir_subtitle': 'فایل‌های خروجی خودکار همینجا ذخیره میشن',
      'default_output_dir_not_set': 'تنظیم نشده',
      'choose_folder': 'انتخاب پوشه',
      'error_out_of_space':
          'فضای ذخیره‌سازی گوشیت کافی نیست. یه مقدار فضا آزاد کن و دوباره امتحان کن.',
      'confirm_enable': 'بله، فعالش کن',
      'processing_prefix': 'در حال پردازش: ',
      'save_all_chosen_dir': 'ذخیره‌ی همه در پوشه‌ی انتخابی',
      'save_all_one_by_one': 'ذخیره‌ی همه (یکی‌یکی)',
      'encrypt_button': 'رمزنگاری',
      'decrypt_button': 'رمزگشایی',
      'generic_error': 'خطا',
      'save_tooltip': 'ذخیره در مسیر دلخواه',
      'share_tooltip': 'اشتراک‌گذاری',
      'save_file_dialog_title': 'ذخیره‌ی فایل خروجی',
      'saved_prefix': 'ذخیره شد: ',
      'cancelled_text': 'لغو شد',
      'settings_title': 'تنظیمات',
      'dark_mode': 'حالت تاریک',
      'language': 'زبان',
      'chunk_size_title': 'اندازه‌ی هر بخش پردازش (chunk)',
      'chunk_size_subtitle': 'در فایل‌های بزرگ روی مصرف حافظه اثر دارد',
      'mb_unit': 'مگابایت',
      'app_lock_title': 'قفل ورود به برنامه',
      'app_lock_subtitle': 'با اثر انگشت / چهره / PIN گوشی خودت',
      'no_device_lock': 'دستگاهت هیچ قفل امنیتی (PIN/الگو/اثر انگشت) نداره.',
      'confirm_enable_lock_reason': 'برای فعال کردن قفل، هویتت رو تأیید کن',
      'auth_failed': 'تأیید هویت ناموفق بود؛ قفل فعال نشد.',
      'randomize_filename_title': 'تصادفی‌سازی نام فایل خروجی',
      'randomize_filename_subtitle':
          'اسم فایل خروجی به‌جای اسم اصلی، یه اسم بی‌ربط میشه (محتوا فرقی نمی‌کنه، فقط اسم ظاهری فایل)',
      'name_style_cache_like': 'شبیه فایل کش سیستم',
      'name_style_data_like': 'شبیه فایل دیتای برنامه',
      'name_style_guid_short': 'کد کوتاه تصادفی',
      'app_locked': 'برنامه قفل است',
      'unlock_button': 'باز کردن قفل',
      'section_general': 'عمومی و ظاهر',
      'section_encryption': 'تنظیمات رمزگذاری',
      'section_security': 'امنیتی',
      'path_and_delete_section': 'مسیر و حذف فایل',
      'open_action': 'باز کردن',
      'open_folder_action': 'باز کردن پوشه',
    },
    'en': {
      'app_title': 'SFE',
      'settings_tooltip': 'Settings',
      'no_files_yet': 'No files selected yet',
      'add_file': 'Add file',
      'clear_list_tooltip': 'Clear list',
      'output_dir_not_chosen': 'Output folder: not chosen (will ask per file)',
      'choose_output_dir_title': 'Choose output folder',
      'password_label': 'Password',
      'use_secondary_password': 'Use secondary password',
      'secondary_password_label': 'Secondary password',
      'delete_source_title': 'Delete source files when done',
      'delete_source_subtitle': 'Current limitation: only clears the app-internal cache copy, not the real file',
      'delete_confirm_title': '⚠️ Delete source files',
      'delete_confirm_body':
          'Due to a known Android limitation, this option currently only deletes '
              'the app-internal cached copy, not the real file in Gallery/Downloads. '
              'True deletion of the original file will be added in a future update.\n\n'
              'Do you still want to enable it?',
      'cancel': 'Cancel',
      'confirm_exit_title': '⚠️ Operation not finished yet',
      'confirm_exit_message':
          'An encrypt/decrypt operation is still running. Leaving now may leave a file incomplete. Are you sure?',
      'confirm_exit_leave': 'Yes, leave',
      'default_output_dir_title': 'Default save folder',
      'default_output_dir_subtitle': 'Output files are saved here automatically',
      'default_output_dir_not_set': 'Not set',
      'choose_folder': 'Choose folder',
      'error_out_of_space':
          'Your device is out of storage space. Free up some space and try again.',
      'confirm_enable': 'Yes, enable it',
      'processing_prefix': 'Processing: ',
      'save_all_chosen_dir': 'Save all to chosen folder',
      'save_all_one_by_one': 'Save all (one by one)',
      'encrypt_button': 'Encrypt',
      'decrypt_button': 'Decrypt',
      'generic_error': 'Error',
      'save_tooltip': 'Save to custom location',
      'share_tooltip': 'Share',
      'save_file_dialog_title': 'Save output file',
      'saved_prefix': 'Saved: ',
      'cancelled_text': 'Cancelled',
      'settings_title': 'Settings',
      'dark_mode': 'Dark mode',
      'language': 'Language',
      'chunk_size_title': 'Processing chunk size',
      'chunk_size_subtitle': 'Affects memory usage on large files',
      'mb_unit': 'MB',
      'app_lock_title': 'App lock',
      'app_lock_subtitle': "Using your device's fingerprint/face/PIN",
      'no_device_lock': 'Your device has no security lock (PIN/pattern/fingerprint) set up.',
      'confirm_enable_lock_reason': 'Verify your identity to enable app lock',
      'auth_failed': 'Authentication failed; lock was not enabled.',
      'randomize_filename_title': 'Randomize output file name',
      'randomize_filename_subtitle':
          "The output file's display name becomes unrelated to the original (content is unaffected, just the visible file name)",
      'name_style_cache_like': 'Like a system cache file',
      'name_style_data_like': 'Like an app data file',
      'name_style_guid_short': 'Short random code',
      'app_locked': 'App is locked',
      'unlock_button': 'Unlock',
      'section_general': 'General & appearance',
      'section_encryption': 'Encryption settings',
      'section_security': 'Security',
      'path_and_delete_section': 'Save location & deletion',
      'open_action': 'Open',
      'open_folder_action': 'Open folder',
    },
  };
}
