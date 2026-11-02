import 'dart:math';

/// Short, easy-to-read id printed on every photo, e.g. SS-7K3QX9A2.
/// No 0/O/1/I/L so it can be read out over the phone.
class PhotoId {
  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  static String generate([Random? random]) {
    final r = random ?? Random.secure();
    final body = List.generate(
      8,
      (_) => _alphabet[r.nextInt(_alphabet.length)],
    ).join();
    return 'SS-$body';
  }

  static bool isValid(String id) =>
      RegExp(r'^SS-[2-9A-HJKMNP-Z]{8}$').hasMatch(id);
}
