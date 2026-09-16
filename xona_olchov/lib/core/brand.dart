/// «Natyajnoy potolok» bo'limining doimiy ma'lumotlari.
///
/// Bir joyda turgani uchun telefon raqami yoki kanal nomi o'zgarsa, faqat shu
/// fayl tahrirlanadi.
abstract final class Brand {
  /// Bo'lim nomi — pastdagi menyuda va sarlavhada.
  static const String section = 'Potolok';

  /// Bosh sarlavha — mijozlar taniydigan yozuv.
  static const String headline = 'НАТЯЖНОЙ ПОТОЛОК';

  static const String slogan = 'Bir kunda — tekis, toza va kafolatli shift';

  /// Kafolat muddati, yil.
  static const int warrantyYears = 15;

  /// Tajriba, yil («10+»).
  static const int experienceYears = 10;

  /// Ish hududlari.
  static const List<String> regions = <String>['Buxoro', 'Navoiy'];

  static String get regionsText => regions.join(' · ');

  /// Telegram kanali (@siz).
  static const String telegramChannel = 'NATYAJN0Y';

  /// Ariza qabul qiladigan bot (@siz).
  static const String telegramBot = 'premium_potolok_ariza_bot';

  /// Sayt manzili.
  static const String siteUrl = 'https://premium-potolok.vercel.app';

  /// Ariza yuboriladigan server.
  static const String apiHost = 'premium-potolok.vercel.app';

  /// Ariza qabul qiluvchi yo'l.
  static const String leadPath = '/api/lead';

  /// Ilova arizani qaysi manbadan yuborganini serverga bildiradi.
  static const String source = 'hisob-app';

  static String telegramUrl(String handle) => 'https://t.me/$handle';
}
