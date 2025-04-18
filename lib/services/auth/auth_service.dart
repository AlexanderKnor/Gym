import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Aktueller Benutzer
  User? get currentUser => _auth.currentUser;

  // Authentifizierungsstatus-Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrierung mit E-Mail und Passwort
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Log firebase auth exceptions for debugging
      print(
          'Firebase Auth Exception bei Registrierung: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Allgemeiner Fehler bei Registrierung: $e');
      rethrow;
    }
  }

  // Anmeldung mit E-Mail und Passwort
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception bei Anmeldung: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Allgemeiner Fehler bei Anmeldung: $e');
      rethrow;
    }
  }

  // Passwort zurücksetzen
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception beim Passwort-Reset: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Allgemeiner Fehler beim Passwort-Reset: $e');
      rethrow;
    }
  }

  // Abmelden
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Fehler beim Abmelden: $e');
      rethrow;
    }
  }
}
