// lib/services/auth/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/auth/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Aktueller Benutzer
  User? get currentUser => _auth.currentUser;

  // Authentifizierungsstatus-Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrierung mit E-Mail, Passwort und Benutzername
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      // Benutzer in Firebase Auth erstellen
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Benutzerprofil in Firestore erstellen
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
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

  // Benutzerdaten abrufen
  Future<UserModel?> getCurrentUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Fehler beim Abrufen der Benutzerdaten: $e');
      return null;
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
