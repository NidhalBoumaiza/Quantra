import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:http/http.dart" as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<Unit> signUp(UserModel userModel);

  Future<Unit> forgetPassword(String email);

  Future<Unit> resetPasswordStepOne(String passwordResetCode);

  Future<Unit> resetPasswordStepTwo(
      String passwordResetCode, String password, String passwordConfirm);

  Future<UserModel> signIn(String email, String password);

  /// NEXT METHODS ARE FOR AUTHENTICATED USERS

  Future<Unit> updateUserPassword(
      String oldPassword, String newPassword, String newPasswordConfirm);

  Future<Unit> disableMyAccount();

  Future<UserModel> modifyMyInformation(UserModel userModel);
}

//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;

  UserRemoteDataSourceImpl({required this.client});

  @override
  Future<Unit> signUp(UserModel userModel) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          "${dotenv.env['URL']}/users/signup"), // replace with your endpoint
    );
    if (userModel.profilePicture != "") {
      final imagePart = await http.MultipartFile.fromPath(
        'image', // key for the API
        userModel.profilePicture,
        contentType: MediaType('image', 'jpg'),
      );
      request.files.add(imagePart);
    }

    request.fields.addAll({
      "email": userModel.email,
      "password": userModel.password,
      "passwordConfirm": userModel.passwordConfirm,
      "firstName": userModel.firstName,
      "lastName": userModel.lastName,
      "phoneNumber": userModel.phoneNumber,
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return handleResponse(response);
    // final response = await client.post(
    //   Uri.parse("${dotenv.env['URL']}/users/signup"),
    //   body: body,
    // );
  }

//--------------------------------------------------------
// --------------------------------------------------------
  @override
  Future<Unit> forgetPassword(String email) async {
    final body = {
      "email": email,
    };
    final response = await client.post(
      Uri.parse("${dotenv.env['URL']}/users/forgotpassword"),
      body: body,
    );

    return handleResponse(response);
  }

  @override
  Future<Unit> resetPasswordStepOne(String passwordResetCode) async {
    final body = {
      "passwordResetCode": passwordResetCode,
    };
    final response = await client.post(
      Uri.parse("${dotenv.env['URL']}/users/resetPasswordStepOne"),
      body: body,
    );
    return handleResponse(response);
  }

  @override
  Future<Unit> resetPasswordStepTwo(
      String passwordResetCode, String password, String passwordConfirm) async {
    final body = {
      "passwordResetCode": passwordResetCode,
      "password": password,
      "passwordConfirm": passwordConfirm,
    };
    final response = await client.patch(
      Uri.parse("${dotenv.env['URL']}/users/resetPasswordStepTwo"),
      body: body,
    );
    return handleResponse(response);
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    final body = {
      "email": email,
      "password": password,
    };
    final response = await client.post(
      Uri.parse("${dotenv.env['URL']}/users/login"),
      body: body,
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final token = responseBody['token'];
      saveToken(token);
      return UserModel.fromJson(responseBody['data']['user']);
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body);
      final errorMessage = responseBody['message'] as String;

      ServerMessageFailure.message = errorMessage;

      throw ServerMessageException();
    } else {
      throw ServerException();
    }
  }

  //Require Authentication

  @override
  Future<Unit> updateUserPassword(
      String oldPassword, String newPassword, String newPasswordConfirm) async {
    final body = {
      "oldPassword": oldPassword,
      "newPassword": newPassword,
      "newPasswordConfirm": newPasswordConfirm,
    };
    dynamic token = await this.token;
    if (token == null) {
      token = "";
    }
    final response = await client.patch(
      Uri.parse("${dotenv.env['URL']}/users/updateUserPassword"),
      body: body,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return handleResponse(response);
  }

  @override
  Future<Unit> disableMyAccount() async {
    final token = await this.token;
    final response = await client.patch(
      Uri.parse("${dotenv.env['URL']}/users/disableMyAccount"),
      headers: {"Authorization": "Bearer $token"},
    );
    return handleResponse(response);
  }

  Future<UserModel> modifyMyInformation(UserModel userModel) async {
    dynamic imagePart;
    if (userModel.profilePicture != "") {
      imagePart = await http.MultipartFile.fromPath(
        'image', // key for the API
        userModel.profilePicture,
        contentType: MediaType('image', 'jpg'),
      );
    }

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(
          "${dotenv.env['URL']}/users/updateMe"), // replace with your endpoint
    );
    request.fields.addAll({
      "email": userModel.email,
      "firstName": userModel.firstName,
      "lastName": userModel.lastName,
      "phoneNumber": userModel.phoneNumber,
    });
    if (imagePart != null) {
      request.files.add(imagePart);
    }
    final token = await this.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return UserModel.fromJson(responseBody['user']);
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body);
      final errorMessage = responseBody['message'] as String;
      ServerMessageFailure.message = errorMessage;
      throw ServerMessageException();
    } else if (response.statusCode == 410) {
      throw const UnauthorizedException();
    } else {
      throw ServerException();
    }
  }

  Future<Unit> handleResponse(http.Response response) async {
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseBody.containsKey('token')) {
        final token = responseBody['token'];
        saveToken(token);
      }
      return Future.value(unit);
    } else if (response.statusCode == 400) {
      final errorMessage = responseBody['message'] as String;

      ServerMessageFailure.message = errorMessage;
      throw ServerMessageException();
    } else if (response.statusCode == 410) {
      final errorMessage = responseBody['message'] as String;

      UnauthorizedFailure.message = errorMessage;
      throw const UnauthorizedException();
    } else {
      throw ServerException();
    }
  }

  saveToken(String token) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    sharedPreferences.setString('token', token);
  }

  Future<dynamic> get token async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    return sharedPreferences.getString('token');
  }
}
