import 'dart:convert';
import 'dart:developer';

import 'package:CareAlert/models/server-response.model.dart';
import 'package:CareAlert/models/user.model.dart';
import 'package:CareAlert/services/app.storage.ioc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  final url = 'http://127.0.0.1:4040';

  bool _loading = false;
  bool get isLoading => _loading;
  void setLoading({required bool value}) {
    _loading = value;
    notifyListeners();
  }

  User _user = User();
  User get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<Either<ServerResponse, User>> signUp(User user) async {
    try {
      setLoading(value: true);
      
      final requestUrl = Uri.parse('$url/api/auth/register');
      final requestBody = jsonEncode({
        'fullName': user.fullName,  // Use fullName instead of name
        'email': user.email,
        'phoneNumber': user.phoneNumber,  // Use phoneNumber instead of phone
        'password': user.password,
        'dateOfBirth': user.dateOfBirth,
        'emergencyMedicalInfo': user.emergencyMedicalInfo,
      });
      
      log('Sending signup request to: $requestUrl', name: 'SignUp');
      log('Request body: $requestBody', name: 'SignUp');
      
      final response = await http.post(
        requestUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      
      log('Response status: ${response.statusCode}', name: 'SignUp');
      log('Response body: ${response.body}', name: 'SignUp');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);
        
        // Save token and user data
        final prefs = AppStorageIOC();
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        await prefs.setString('user', user.toJson());
        
        setUser(user);
        setLoading(value: false);
        return right(user);
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        setLoading(value: false);
        final data = jsonDecode(response.body);
        return left(ServerResponse(
          success: false, 
          message: data['message'] ?? 'Registration failed'
        ));
      } else {
        setLoading(value: false);
        return left(ServerResponse.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      log('SignUp error: $e', name: 'SignUp');
      setLoading(value: false);
      return left(ServerResponse(success: false, message: e.toString()));
    }
  }

  Future<Either<ServerResponse, User>> signIn(User user) async {
    try {
      setLoading(value: true);
      final response = await http.post(
        Uri.parse('$url/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email,
          'password': user.password,
        }),
      );

      log('Response status: ${response.statusCode}', name: 'SignIn');
      log('Response body: ${response.body}', name: 'SignIn');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User loggedUser = User.fromJson(data['user']);
        
        // Save token and user data
        final prefs = AppStorageIOC();
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        await prefs.setString('user', loggedUser.toJson());
        
        setUser(loggedUser);
        setLoading(value: false);
        return right(loggedUser);
      } else if (response.statusCode == 401) {
        setLoading(value: false);
        return left(
          ServerResponse(success: false, message: 'Invalid email or password'),
        );
      } else {
        setLoading(value: false);
        return left(ServerResponse.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      log('SignIn error: $e', name: 'SignIn');
      setLoading(value: false);
      return left(ServerResponse(success: false, message: e.toString()));
    }
  }

  Future<Either<ServerResponse, User>> getProfile() async {
    try {
      setLoading(value: true);

      final token = await AppStorageIOC().getString('token');
      log('Token: $token', name: 'GetProfile Token');
      
      final response = await http.get(
        Uri.parse('$url/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
          'ngrok-skip-browser-warning': 'true',
        },
      );
      log(response.body, name: 'GetProfile Response');

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);
        
        log('User profile fetched successfully', name: 'Fetched User');
        
        setUser(user);
        setLoading(value: false);
        return right(user);
      } else if (response.statusCode == 401) {
        setLoading(value: false);
        return left(
          ServerResponse(success: false, message: 'Invalid Credentials'),
        );
      } else {
        setLoading(value: false);
        return left(ServerResponse.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      setLoading(value: false);
      return left(ServerResponse(success: false, message: e.toString()));
    }
  }

  Future<Either<ServerResponse, User>> addContact({
    required String name,
    required String phone,
    required String email,
    required String relationship,
  }) async {
    try {
      setLoading(value: true);

      final token = await AppStorageIOC().getString('token');
      final response = await http.post(
        Uri.parse('$url/contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'relationship': relationship,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);
        final prefs = AppStorageIOC();
        await prefs.setString('user', user.toJson());
        setUser(user);
        setLoading(value: false);
        return right(user);
      } else if (response.statusCode == 401) {
        setLoading(value: false);
        return left(
          ServerResponse(success: false, message: 'Invalid Credentials'),
        );
      } else {
        setLoading(value: false);
        return left(ServerResponse.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      setLoading(value: false);
      return left(ServerResponse(success: false, message: e.toString()));
    }
  }
}