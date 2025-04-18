import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth/auth_service.dart';

enum AuthStatus {
  uninitialized, // Initial state
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _error;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;

  // Constructor with auth state monitoring
  AuthProvider() {
    // Listen to authentication state changes
    _authService.authStateChanges.listen((User? user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        _status = AuthStatus.authenticated;
        _user = user;
      }
      notifyListeners();
    });
  }

  // Registration with email and password
  Future<bool> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      _setLoading(true);
      await _authService.registerWithEmailAndPassword(email, password);
      _error = null;
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      await _authService.signInWithEmailAndPassword(email, password);
      _error = null;
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _authService.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
    } catch (e) {
      _error = _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Error handling for auth errors
  String _handleAuthError(dynamic error) {
    String errorMessage = 'Ein unbekannter Fehler ist aufgetreten.';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          errorMessage = 'Die E-Mail-Adresse ist ungültig.';
          break;
        case 'user-disabled':
          errorMessage = 'Dieser Benutzer wurde deaktiviert.';
          break;
        case 'user-not-found':
          errorMessage = 'Kein Benutzer mit dieser E-Mail-Adresse gefunden.';
          break;
        case 'wrong-password':
          errorMessage = 'Falsches Passwort.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Diese E-Mail-Adresse wird bereits verwendet.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Diese Anmeldemethode ist nicht aktiviert.';
          break;
        case 'weak-password':
          errorMessage =
              'Das Passwort ist zu schwach. Bitte wähle ein stärkeres Passwort.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Zu viele Anmeldeversuche. Bitte versuche es später erneut.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Netzwerkfehler. Bitte überprüfe deine Internetverbindung.';
          break;
        default:
          errorMessage = 'Fehler: ${error.message}';
          break;
      }
    }

    return errorMessage;
  }
}
