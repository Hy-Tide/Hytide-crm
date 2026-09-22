// lib/core/utils/error_handler.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRoleException implements Exception {
  final String message;
  const AuthRoleException([this.message = 'Access denied. Admin access is required.']);
  @override
  String toString() => message;
}

class AuthInactiveException implements Exception {
  final String message;
  const AuthInactiveException([
    this.message = 'Your account is currently inactive. Please contact an administrator.',
  ]);
  @override
  String toString() => message;
}

class ErrorHandler {
  ErrorHandler._();

  static String getMessage(dynamic error) {
    if (error is AuthRoleException) {
      return error.message;
    }
    if (error is AuthInactiveException) {
      return error.message;
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'Your account has been disabled. Please contact an administrator.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few moments and try again.';
        case 'network-request-failed':
          return 'Unable to connect. Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Email and password sign-in is not enabled.';
        default:
          return 'Login failed. Please verify your credentials and try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'The service is temporarily unavailable. Please try again shortly.';
        case 'deadline-exceeded':
          return 'The request timed out. Please check your network and retry.';
        default:
          return 'A server error occurred. Please try again.';
      }
    }

    if (error is Exception) {
      final str = error.toString();
      if (str.contains('SocketException') || str.contains('Failed host lookup')) {
        return 'No internet connection. Please check your network.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
