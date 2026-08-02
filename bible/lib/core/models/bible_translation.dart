/// Bible translations selectable in Settings.
///
/// Only [kjv] and [web] ship with real bundled verse text — both are public
/// domain. NIV/ESV/etc. require a license from Biblica/Crossway before their
/// text can be bundled or displayed, so they're modeled here but marked
/// unavailable until that's in place.
enum BibleTranslation {
  kjv('KJV', 'King James Version', available: true),
  web('WEB', 'World English Bible', available: true),
  niv('NIV', 'New International Version', available: false),
  esv('ESV', 'English Standard Version', available: false);

  const BibleTranslation(this.code, this.fullName, {required this.available});

  final String code;
  final String fullName;
  final bool available;

  static BibleTranslation fromCode(String code) => BibleTranslation.values.firstWhere(
        (t) => t.code == code,
        orElse: () => BibleTranslation.kjv,
      );
}
