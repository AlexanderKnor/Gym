// lib/providers/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth/auth_service.dart';
import '../../models/auth/user_model.dart';

enum AuthStatus {
  uninitialized, // Initial state
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userData;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _error;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  UserModel? get userData => _userData;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;

  // Constructor with auth state monitoring
  AuthProvider() {
    // Listen to authentication state changes
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        print(
            'AUTH PROVIDER: Benutzer abgemeldet, setze Status auf unauthenticated');
        _status = AuthStatus.unauthenticated;
        _user = null;
        _userData = null;
      } else {
        print(
            'AUTH PROVIDER: Benutzer angemeldet, setze Status auf authenticated');
        _status = AuthStatus.authenticated;
        _user = user;

        // Lade Benutzerdaten aus Firestore
        _userData = await _authService.getCurrentUserData();
      }
      notifyListeners();
    });
  }

  // Registration with email, password and username
  Future<bool> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      _setLoading(true);
      await _authService.registerWithEmailAndPassword(
          email, password, username);
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
      print('AUTH PROVIDER: Starte Abmeldeprozess');
      _setLoading(true);

      // Wir rufen hier keine Provider-Reset-Methoden auf, da das in der UI-Schicht
      // vor dem Aufruf von signOut() geschehen sollte

      await _authService.signOut();
      print('AUTH PROVIDER: Abmeldevorgang abgeschlossen');
    } catch (e) {
      _error = _handleAuthError(e);
      print('AUTH PROVIDER: Fehler beim Abmelden: $_error');
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
