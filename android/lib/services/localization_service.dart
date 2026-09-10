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

  static String progressCounter(int current, int total) {
    if (_lang == 'en') return 'File $current of $total';
    return 'فایل $current از $total';
  }

  static String autosavePartial(int saved, int manual) {
    if (_lang == 'en') return '$saved saved ✓ / $manual left to save manually';
    return '$saved تا ذخیره شد ✓ / $manual تا مونده که دستی ذخیره کنی';
  }

  static const Map<String, Map<String, String>> _strings = {
    'fa': {
      'app_title': 'SFE',
      'settings_tooltip': 'تنظیمات',
      'no_files_yet': 'هنوز فایلی انتخاب نشده',
      'add_file': 'افزودن فایل',
      'clear_list_tooltip': 'پاک کردن لیست',
      'output_dir_not_chosen': 'پوشه‌ی ذخیره‌ی خروجی: انتخاب نشده (خروجی‌ها موقت می‌مونن تا دستی ذخیره‌شون کنی)',
      'choose_output_dir_title': 'انتخاب پوشه‌ی ذخیره‌ی خروجی',
      'password_label': 'رمز عبور',
      'use_secondary_password': 'استفاده از رمز دوم',
      'secondary_password_label': 'رمز دوم',
      'delete_source_title': 'پاک کردن نسخه‌ی موقت بعد از اتمام',
      'delete_source_subtitle': 'فایل اصلی در گالری/Downloads دست‌نخورده باقی می‌مونه',
      'delete_confirm_title': 'پاک کردن نسخه‌ی موقت',
      'delete_confirm_body':
          'به‌خاطر یه محدودیت فنی در اندروید، اپ فقط می‌تونه نسخه‌ی موقتی که '
              'خودش برای پردازش ساخته رو پاک کنه؛ به فایل اصلی توی گالری/'
              'Downloads دسترسی نداره تا حذفش کنه. اگه می‌خوای فایل اصلی رو '
              'واقعاً حذف کنی، باید بعد از اتمام کار، خودت دستی از گالری/'
              'File Manager پاکش کنی.\n\n'
              'می‌خوای این پاک‌سازی نسخه‌ی موقت رو فعال کنی؟',
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
      'error_out_of_memory':
          'حافظه‌ی گوشیت برای این عملیات کافی نیست. بقیه‌ی برنامه‌ها رو ببند و دوباره امتحان کن.',
      'error_incomplete_file':
          'فایل رمزشده کامل نیست (احتمالاً حین انتقال قطع شده). دوباره فایل رو منتقل کن و امتحان کن.',
      'mode_banner_encrypt': 'در حال آماده‌سازی برای رمزنگاری فایل‌ها',
      'mode_banner_decrypt': 'در حال آماده‌سازی برای رمزگشایی فایل‌ها',
      'section_about': 'درباره',
      'about_app_name': 'SFE - رمزنگاری امن فایل',
      'about_version_label': 'نسخه',
      'about_github': 'مشاهده در گیت‌هاب',
      'about_report_issue': 'گزارش مشکل / پیشنهاد',
      'about_license': 'مجوز',
      'could_not_open_link': 'باز کردن لینک ممکن نشد.',
      'section_scenarios': 'سناریوها',
      'save_current_as_scenario': 'ذخیره‌ی تنظیمات فعلی به‌عنوان سناریوی جدید',
      'no_scenarios_yet': 'هنوز سناریویی ذخیره نشده',
      'new_scenario_title': 'اسم سناریو رو وارد کن',
      'scenario_name_hint': 'مثلاً: عکس‌های شخصی',
      'save': 'ذخیره',
      'scenario_applied_prefix': 'سناریو اعمال شد: ',
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
      'warn_no_files': 'اول حداقل یک فایل انتخاب کن.',
      'warn_no_password': 'لطفاً رمز عبور رو وارد کن.',
      'warn_no_secondary': 'رمز دوم رو هم وارد کن.',
      'list_cleared_undo': 'لیست فایل‌ها پاک شد.',
      'undo_action': 'بازگردانی',
      'unlock_failed': 'باز کردن قفل ناموفق بود؛ دوباره امتحان کن.',
      'strength_weak': 'ضعیف',
      'strength_medium': 'متوسط',
      'strength_strong': 'قوی',
      'strength_very_strong': 'خیلی قوی',
      'secondary_password_warn': '⚠️ اگه رمز دوم فراموش بشه، فایل‌ها غیرقابل بازیابی هستن.',
      'autosave_all_ok': 'همه‌ی فایل‌ها در پوشه‌ی انتخابی ذخیره شدن ✓',
      'delete_scenario_title': 'حذف سناریو',
      'delete_scenario_body': 'این سناریو برای همیشه حذف می‌شه:',
      'delete_yes': 'بله، حذف کن',
      'name_style_cache_desc': 'نام‌هایی شبیه فایل‌های موقت سیستم — کاملاً نامحسوس',
      'name_style_data_desc': 'نام‌هایی شبیه فایل‌های داده‌ی برنامه',
      'name_style_guid_desc': 'یک کد تصادفی بدون هیچ الگو',
    },
    'en': {
      'app_title': 'SFE',
      'settings_tooltip': 'Settings',
      'no_files_yet': 'No files selected yet',
      'add_file': 'Add file',
      'clear_list_tooltip': 'Clear list',
      'output_dir_not_chosen': 'Output folder: not chosen (outputs stay temporary until you save them)',
      'choose_output_dir_title': 'Choose output folder',
      'password_label': 'Password',
      'use_secondary_password': 'Use secondary password',
      'secondary_password_label': 'Secondary password',
      'delete_source_title': 'Delete temporary copy when done',
      'delete_source_subtitle': 'The original file in Gallery/Downloads stays untouched',
      'delete_confirm_title': 'Delete temporary copy',
      'delete_confirm_body':
          'Due to a technical limitation on Android, the app can only delete '
              'the temporary copy it created for processing; it has no access '
              'to delete the original file in Gallery/Downloads. If you want '
              'the original file gone, delete it yourself from Gallery/File '
              'Manager after the operation.\n\n'
              'Enable this temporary-copy cleanup?',
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
      'error_out_of_memory':
          'Your device doesn\'t have enough memory for this operation. Close other apps and try again.',
      'error_incomplete_file':
          'The encrypted file is incomplete (likely cut off during transfer). Re-transfer it and try again.',
      'mode_banner_encrypt': 'Preparing to encrypt files',
      'mode_banner_decrypt': 'Preparing to decrypt files',
      'section_about': 'About',
      'about_app_name': 'SFE - Secure File Encryption',
      'about_version_label': 'Version',
      'about_github': 'View on GitHub',
      'about_report_issue': 'Report an issue / suggestion',
      'about_license': 'License',
      'could_not_open_link': 'Could not open the link.',
      'section_scenarios': 'Scenarios',
      'save_current_as_scenario': 'Save current settings as a new scenario',
      'no_scenarios_yet': 'No scenarios saved yet',
      'new_scenario_title': 'Enter a scenario name',
      'scenario_name_hint': 'e.g. Personal photos',
      'save': 'Save',
      'scenario_applied_prefix': 'Scenario applied: ',
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
      'warn_no_files': 'Select at least one file first.',
      'warn_no_password': 'Please enter a password.',
      'warn_no_secondary': 'Please enter the secondary password too.',
      'list_cleared_undo': 'File list cleared.',
      'undo_action': 'Undo',
      'unlock_failed': 'Unlock failed; try again.',
      'strength_weak': 'Weak',
      'strength_medium': 'Medium',
      'strength_strong': 'Strong',
      'strength_very_strong': 'Very strong',
      'secondary_password_warn': '⚠️ If the secondary password is forgotten, files cannot be recovered.',
      'autosave_all_ok': 'All files saved to the chosen folder ✓',
      'delete_scenario_title': 'Delete scenario',
      'delete_scenario_body': 'This scenario will be permanently deleted:',
      'delete_yes': 'Yes, delete',
      'name_style_cache_desc': 'Names like system temp files — fully inconspicuous',
      'name_style_data_desc': 'Names like app data files',
      'name_style_guid_desc': 'A random code with no pattern',
    },
  };
}
