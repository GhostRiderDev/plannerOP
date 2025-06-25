import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:plannerop/dto/auth/signin.dart';

class SigninService extends ChangeNotifier {
  final String API_URL = dotenv.get('API_URL');
  Future<ResSigninDto> signin(
      String user, String password, BuildContext context) async {
    try {
      var url = Uri.parse(API_URL + '/login');
      var response =
          await http.post(url, body: {'username': user, 'password': password});
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        return ResSigninDto(
            accessToken: jsonResponse['access_token'], isSuccess: true);
      } else {
        return ResSigninDto(accessToken: '', isSuccess: false);
      }
    } catch (e) {
      return ResSigninDto(accessToken: '', isSuccess: false);
    }
  }
}
