/// معادل سبک‌شده‌ی Scenario.cs
/// چون در اندروید فایل‌ها هر بار دستی/از Share Sheet انتخاب میشن (نه از یک
/// مسیر ثابت مثل ویندوز)، این نسخه فقط «ترکیبی از تنظیمات» رو ذخیره می‌کنه،
/// نه خود مسیر فایل‌ها.
class Scenario {
  final String id;
  final String name;
  final int chunkSizeMb;
  final bool randomizeFilename;
  final int nameStyleIndex;
  final String? outputDir;

  Scenario({
    required this.id,
    required this.name,
    required this.chunkSizeMb,
    required this.randomizeFilename,
    required this.nameStyleIndex,
    this.outputDir,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chunkSizeMb': chunkSizeMb,
        'randomizeFilename': randomizeFilename,
        'nameStyleIndex': nameStyleIndex,
        'outputDir': outputDir,
      };

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
        id: json['id'] as String,
        name: json['name'] as String,
        chunkSizeMb: json['chunkSizeMb'] as int,
        randomizeFilename: json['randomizeFilename'] as bool,
        nameStyleIndex: json['nameStyleIndex'] as int,
        outputDir: json['outputDir'] as String?,
      );
}
