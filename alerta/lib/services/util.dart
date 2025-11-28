import 'dart:convert';

import 'package:CareAlert/models/user.model.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setIsAppInitiated() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool('isAppInitiated', true);
}

Future<bool> isAppInitiated() async {
  final prefs = await SharedPreferences.getInstance();
  // prefs.setBool('isAppInitiated', false);
  return prefs.getBool('isAppInitiated') ?? false;
}

Future<Either<bool, User>> getUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user');
  if (userJson != null && userJson.isNotEmpty) {
    return right(User.fromJson(jsonDecode(userJson)));
  } else {
    return left(false);
  }
}
