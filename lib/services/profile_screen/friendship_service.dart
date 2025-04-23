// lib/services/profile_screen/friendship_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile_screen/friendship_model.dart';
import '../../models/profile_screen/friend_request_model.dart';
import '../../models/auth/user_model.dart';

class FriendshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hilfsmethode zum Abrufen der Benutzer-ID
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  // Referenz zur Freundesliste-Sammlung eines Benutzers
  CollectionReference _getFriendsCollection() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore.collection('users').doc(userId).collection('friends');
  }

  // Referenz zur eingehenden Anfragen-Sammlung eines Benutzers
  CollectionReference _getIncomingRequestsCollection() {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friend_requests');
  }

  // Referenz zur ausgehenden Anfragen-Sammlung eines Benutzers
  CollectionReference _getOutgoingRequestsCollection(String receiverId) {
    final userId = _getUserId();
    if (userId == null) throw Exception('Benutzer ist nicht angemeldet');

    return _firestore
        .collection('users')
        .doc(receiverId)
        .collection('friend_requests');
  }

  // Hilfsmethode zum Abrufen der aktuellen Benutzerdaten
  Future<UserModel?> getCurrentUserData() async {
    try {
      final userId = _getUserId();
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Fehler beim Abrufen der Benutzerdaten: $e');
      return null;
    }
  }

  // Stream für Freundesliste
  Stream<List<FriendshipModel>> getFriendsStream() {
    final userId = _getUserId();
    if (userId == null) {
      print('Kann Freunde nicht streamen, Benutzer nicht angemeldet');
      return Stream.value([]);
    }

    return _getFriendsCollection().snapshots().map((snapshot) {
      print('Freundesliste Aktualisierung: ${snapshot.docs.length} Dokumente');
      return snapshot.docs
          .map((doc) =>
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Freunde abrufen (einmalige Abfrage)
  Future<List<FriendshipModel>> getFriends() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Freunde nicht abrufen, Benutzer nicht angemeldet');
        return [];
      }

      final snapshot = await _getFriendsCollection().get();
      return snapshot.docs
          .map((doc) =>
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Freunde: $e');
      return [];
    }
  }

  // Stream für empfangene Anfragen
  Stream<List<FriendRequestModel>> getReceivedRequestsStream() {
    final userId = _getUserId();
    if (userId == null) {
      print('Kann Anfragen nicht streamen, Benutzer nicht angemeldet');
      return Stream.value([]);
    }

    return _getIncomingRequestsCollection()
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      print(
          'Empfangene Anfragen Aktualisierung: ${snapshot.docs.length} Dokumente');
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              print('Anfrage-Daten: $data');
              return FriendRequestModel.fromMap(data);
            } catch (e) {
              print('Fehler beim Konvertieren einer Anfrage: $e');
              return null;
            }
          })
          .where((model) => model != null)
          .cast<FriendRequestModel>()
          .toList();
    });
  }

  // Empfangene Anfragen abrufen (einmalige Abfrage)
  Future<List<FriendRequestModel>> getReceivedRequests() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Anfragen nicht abrufen, Benutzer nicht angemeldet');
        return [];
      }

      final snapshot = await _getIncomingRequestsCollection()
          .where('status', isEqualTo: 'pending')
          .get();

      print('Empfangene Anfragen Snapshot: ${snapshot.docs.length} Dokumente');

      return snapshot.docs
          .map((doc) =>
              FriendRequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Anfragen: $e');
      return [];
    }
  }

  // Stream für gesendete Anfragen - GEÄNDERT
  Stream<List<FriendRequestModel>> getSentRequestsStream() {
    final userId = _getUserId();
    if (userId == null) {
      print('Kann Anfragen nicht streamen, Benutzer nicht angemeldet');
      return Stream.value([]);
    }

    // Diese Abfrage ist komplexer, da wir alle Anfragen von verschiedenen Empfängern finden müssen
    return _firestore
        .collectionGroup('friend_requests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        // Sortierung nach createdAt statt name
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
          'Gesendete Anfragen Aktualisierung: ${snapshot.docs.length} Dokumente');
      return snapshot.docs
          .map((doc) =>
              FriendRequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Gesendete Anfragen abrufen (einmalige Abfrage) - GEÄNDERT
  Future<List<FriendRequestModel>> getSentRequests() async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Anfragen nicht abrufen, Benutzer nicht angemeldet');
        return [];
      }

      // Sammlung mit allen friend_requests-Subsammlungen durchsuchen
      final snapshot = await _firestore
          .collectionGroup('friend_requests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          // Sortierung nach createdAt statt name
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              FriendRequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Anfragen: $e');
      return [];
    }
  }

  // Benutzer nach E-Mail suchen
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      print('Suche Benutzer mit E-Mail: $email');

      // Normalisiere die E-Mail (zu Kleinbuchstaben)
      final normalizedEmail = email.trim().toLowerCase();

      // Prüfen, ob der aktuelle Benutzer nach sich selbst sucht
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase() == normalizedEmail) {
        print('Benutzer sucht nach sich selbst, das ist nicht erlaubt');
        return null;
      }

      // Zwei Abfragen: Eine mit exakter E-Mail und eine mit kleingeschriebener E-Mail
      final querySnapshot1 = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final querySnapshot2 = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      print(
          'Abfrageergebnis 1: ${querySnapshot1.docs.length} Dokumente gefunden');
      print(
          'Abfrageergebnis 2: ${querySnapshot2.docs.length} Dokumente gefunden');

      // Verwende das erste nicht-leere Ergebnis
      final querySnapshot =
          querySnapshot1.docs.isNotEmpty ? querySnapshot1 : querySnapshot2;

      if (querySnapshot.docs.isEmpty) {
        print('Keine Dokumente gefunden für E-Mail: $email');
        return null;
      }

      final userData = querySnapshot.docs.first.data();
      print('Dokument gefunden: $userData');

      return UserModel.fromMap(userData as Map<String, dynamic>);
    } catch (e) {
      print('Fehler beim Suchen des Benutzers: $e');
      return null;
    }
  }

  // Benutzer nach Benutzername suchen
  Future<List<UserModel>> findUsersByUsername(String username) async {
    try {
      print('Suche Benutzer mit Benutzernamen: $username');

      // Prüfen, ob der aktuelle Benutzer nach sich selbst sucht
      final currentUser = _auth.currentUser;
      final currentUserData = await getCurrentUserData();
      final currentUsername = currentUserData?.username;

      // Suche nach exakter Übereinstimmung
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // Zu Testzwecken
      print('Gefundene Benutzer: ${querySnapshot.docs.length}');

      // Liste der gefundenen Benutzer (außer dem aktuellen Benutzer)
      final users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) =>
              user.uid != currentUser?.uid) // Filtere den aktuellen Benutzer
          .toList();

      return users;
    } catch (e) {
      print('Fehler beim Suchen der Benutzer: $e');
      return [];
    }
  }

  // Freundschaftsanfrage senden
  Future<bool> sendFriendRequest(UserModel receiver) async {
    try {
      final userId = _getUserId();
      final currentUser = _auth.currentUser;

      if (userId == null || currentUser == null) {
        print('Kann Anfrage nicht senden, Benutzer nicht angemeldet');
        return false;
      }

      // Aktuellen Benutzer abrufen für den Benutzernamen
      final currentUserData = await getCurrentUserData();
      final senderUsername = currentUserData?.username ?? 'Unbekannt';

      // Prüfen, ob bereits eine Anfrage existiert
      final existingRequests = await _firestore
          .collection('users')
          .doc(receiver.uid)
          .collection('friend_requests')
          .where('senderId', isEqualTo: userId)
          .get();

      if (existingRequests.docs.isNotEmpty) {
        print('Es existiert bereits eine Anfrage für diesen Benutzer');
        return false;
      }

      // Prüfen, ob bereits befreundet
      final existingFriendship = await _getFriendsCollection()
          .where('friendId', isEqualTo: receiver.uid)
          .get();

      if (existingFriendship.docs.isNotEmpty) {
        print('Ihr seid bereits befreundet');
        return false;
      }

      // Neue Anfrage erstellen - jetzt als Unterdokument des Empfängers
      final requestId = _firestore
          .collection('users')
          .doc(receiver.uid)
          .collection('friend_requests')
          .doc()
          .id;

      final request = FriendRequestModel(
        id: requestId,
        senderId: userId,
        senderUsername: senderUsername,
        receiverId: receiver.uid,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(receiver.uid)
          .collection('friend_requests')
          .doc(requestId)
          .set(request.toMap());

      print('Freundschaftsanfrage erfolgreich gesendet');
      return true;
    } catch (e) {
      print('Fehler beim Senden der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Anfrage akzeptieren
  Future<bool> acceptFriendRequest(FriendRequestModel request) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Anfrage nicht akzeptieren, Benutzer nicht angemeldet');
        return false;
      }

      print(
          'Beginne, Freundschaftsanfrage von ${request.senderId} an $userId zu akzeptieren');

      // Freundschaft für beide Benutzer speichern
      // 1. Freundschaft für den aktuellen Benutzer
      final senderData =
          await _firestore.collection('users').doc(request.senderId).get();

      if (!senderData.exists) {
        print('Sender-Benutzerdaten nicht gefunden: ${request.senderId}');
        return false;
      }

      final senderUser =
          UserModel.fromMap(senderData.data() as Map<String, dynamic>);

      final friendship1 = FriendshipModel(
        id: 'friendship_${userId}_${request.senderId}',
        userId: userId,
        friendId: request.senderId,
        friendUsername: senderUser.username,
        friendEmail: senderUser.email,
        createdAt: DateTime.now(),
      );

      print(
          'Freundschaftsmodell für aktuellen Benutzer erstellt: ${friendship1.id}');

      // 2. Freundschaft für den Anfrage-Sender
      final receiverData =
          await _firestore.collection('users').doc(userId).get();

      if (!receiverData.exists) {
        print('Empfänger-Benutzerdaten nicht gefunden: $userId');
        return false;
      }

      final receiverUser =
          UserModel.fromMap(receiverData.data() as Map<String, dynamic>);

      final friendship2 = FriendshipModel(
        id: 'friendship_${request.senderId}_${userId}',
        userId: request.senderId,
        friendId: userId,
        friendUsername: receiverUser.username,
        friendEmail: receiverUser.email,
        createdAt: DateTime.now(),
      );

      print('Freundschaftsmodell für Freund erstellt: ${friendship2.id}');

      // Batch-Schreibvorgang verwenden für bessere Atomizität
      final batch = _firestore.batch();

      // Referenzen auf Freundschaftsdokumente
      final friendship1Ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendship1.id);

      final friendship2Ref = _firestore
          .collection('users')
          .doc(request.senderId)
          .collection('friends')
          .doc(friendship2.id);

      // Referenz auf das Anfragedokument im neuen Pfad
      final requestRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .doc(request.id);

      // Batch-Operationen hinzufügen
      batch.set(friendship1Ref, friendship1.toMap());
      batch.set(friendship2Ref, friendship2.toMap());

      // Anfrage löschen
      batch.delete(requestRef);

      // Batch ausführen
      await batch.commit();
      print('Beide Freundschaftseinträge erfolgreich gespeichert');
      print('Freundschaftsanfrage erfolgreich gelöscht');

      print('Freundschaftsanfrage erfolgreich akzeptiert');
      return true;
    } catch (e) {
      print('Fehler beim Akzeptieren der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Anfrage ablehnen
  Future<bool> rejectFriendRequest(FriendRequestModel request) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Anfrage nicht ablehnen, Benutzer nicht angemeldet');
        return false;
      }

      // Anfrage im neuen Pfad löschen
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .doc(request.id)
          .delete();

      print('Freundschaftsanfrage erfolgreich abgelehnt und gelöscht');
      return true;
    } catch (e) {
      print('Fehler beim Ablehnen der Freundschaftsanfrage: $e');
      return false;
    }
  }

  // Freund entfernen
  Future<bool> removeFriend(String friendId) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        print('Kann Freund nicht entfernen, Benutzer nicht angemeldet');
        return false;
      }

      print('Entferne Freundschaft zwischen $userId und $friendId');

      // Dokument-IDs für die Freundschaften
      final myFriendshipId = 'friendship_${userId}_$friendId';
      final theirFriendshipId = 'friendship_${friendId}_$userId';

      // Prüfen, ob die Dokumente existieren
      final myFriendshipDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(myFriendshipId)
          .get();

      print('Mein Freundschaftsdokument existiert: ${myFriendshipDoc.exists}');

      // 1. Eigenes Freundschaftsdokument löschen
      bool friendshipRemoved = false;
      if (myFriendshipDoc.exists) {
        try {
          print('Lösche mein Freundschaftsdokument: $myFriendshipId');
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('friends')
              .doc(myFriendshipId)
              .delete();

          print('Mein Freundschaftsdokument erfolgreich gelöscht');
          friendshipRemoved = true;
        } catch (e) {
          print('Fehler beim Löschen meines Freundschaftsdokuments: $e');
        }
      }

      // 2. Freundschaftsdokument des anderen Benutzers löschen
      try {
        print(
            'Versuche, Freundschaftsdokument des anderen Benutzers zu löschen: $theirFriendshipId');
        await _firestore
            .collection('users')
            .doc(friendId)
            .collection('friends')
            .doc(theirFriendshipId)
            .delete();

        print(
            'Freundschaftsdokument des anderen Benutzers erfolgreich gelöscht');
        friendshipRemoved = true;
      } catch (e) {
        print(
            'Fehler beim Löschen des Freundschaftsdokuments des anderen Benutzers: $e');
      }

      return friendshipRemoved;
    } catch (e) {
      print('Fehler beim Entfernen des Freundes: $e');
      return false;
    }
  }
}
