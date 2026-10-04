import 'bible_translation.dart';
import 'difficulty.dart';

class AppSettings {
  const AppSettings({
    this.translation = BibleTranslation.kjv,
    this.defaultDifficulty = Difficulty.adult,
    this.kidMode = false,
    this.soundOn = true,
    this.musicOn = true,
    this.customMusicPath,
    this.customMusicName,
    this.dailyReminderEnabled = true,
    this.fontScale = 1.0,
    this.highContrast = false,
    this.darkMode = false,
  });

  final BibleTranslation translation;
  final Difficulty defaultDifficulty;
  final bool kidMode;
  final bool soundOn;
  final bool musicOn;

  /// Local filesystem path to a copy of a music file the user picked from
  /// their own device (see SettingsScreen). Null means "use the bundled
  /// default track". The file is copied into app storage on pick so
  /// playback doesn't depend on the original (e.g. iCloud-hosted) file
  /// staying reachable.
  final String? customMusicPath;

  /// Original filename of [customMusicPath], kept only for display in
  /// Settings since the copied file's path isn't human-readable.
  final String? customMusicName;
  final bool dailyReminderEnabled;
  final double fontScale;
  final bool highContrast;
  final bool darkMode;

  AppSettings copyWith({
    BibleTranslation? translation,
    Difficulty? defaultDifficulty,
    bool? kidMode,
    bool? soundOn,
    bool? musicOn,
    String? customMusicPath,
    String? customMusicName,
    bool clearCustomMusic = false,
    bool? dailyReminderEnabled,
    double? fontScale,
    bool? highContrast,
    bool? darkMode,
  }) => AppSettings(
    translation: translation ?? this.translation,
    defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
    kidMode: kidMode ?? this.kidMode,
    soundOn: soundOn ?? this.soundOn,
    musicOn: musicOn ?? this.musicOn,
    customMusicPath: clearCustomMusic ? null : (customMusicPath ?? this.customMusicPath),
    customMusicName: clearCustomMusic ? null : (customMusicName ?? this.customMusicName),
    dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
    fontScale: fontScale ?? this.fontScale,
    highContrast: highContrast ?? this.highContrast,
    darkMode: darkMode ?? this.darkMode,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    translation: BibleTranslation.fromCode(json['translation'] as String? ?? 'KJV'),
    defaultDifficulty: Difficulty.fromJson(json['defaultDifficulty'] as String? ?? 'adult'),
    kidMode: json['kidMode'] as bool? ?? false,
    soundOn: json['soundOn'] as bool? ?? true,
    musicOn: json['musicOn'] as bool? ?? true,
    customMusicPath: json['customMusicPath'] as String?,
    customMusicName: json['customMusicName'] as String?,
    dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
    fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
    highContrast: json['highContrast'] as bool? ?? false,
    darkMode: json['darkMode'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'translation': translation.code,
    'defaultDifficulty': defaultDifficulty.name,
    'kidMode': kidMode,
    'soundOn': soundOn,
    'musicOn': musicOn,
    'customMusicPath': customMusicPath,
    'customMusicName': customMusicName,
    'dailyReminderEnabled': dailyReminderEnabled,
    'fontScale': fontScale,
    'highContrast': highContrast,
    'darkMode': darkMode,
  };
}
