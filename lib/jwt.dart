import 'dart:math';

import 'package:jaguar_jwt/jaguar_jwt.dart' as jaguar_jwt;

import 'database.dart';

class Jwt {
  Jwt._();
  static final instance = Jwt._();

  String token(String email) {
    const chars = '0123456789'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz';
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);
    final buf = StringBuffer();

    for (var x = 0; x < 128; x++) {
      buf.write(chars[rnd.nextInt(chars.length)]);
    }
    // Create a claim set
    final claimSet = jaguar_jwt.JwtClaim(
      maxAge: const Duration(days: 365),
      expiry: DateTime.now().add(const Duration(days: 365)),
      jwtId: buf.toString(),
      issuer: email,
      audience: <String>['furb.br'],
    );

    // Generate a JWT from the claim set
    final token = jaguar_jwt.issueJwtHS256(claimSet, 'furb_mqtt_demo');

    print('JWT: "$token"\n');
    return token;
  }

  bool validateUser(String token) {
    try {
      final decClaimSet = jaguar_jwt.verifyJwtHS256Signature(
        token,
        'furb_mqtt_demo',
      );

      final person = Database.instance.getPersonJwt(token);

      decClaimSet.validate(issuer: person?.email, audience: 'furb.br');
      return true;
    } on jaguar_jwt.JwtException catch (e) {
      print('Error: bad JWT: $e');
    } catch (e) {
      print(e.toString());
    }
    return false;
  }
}
