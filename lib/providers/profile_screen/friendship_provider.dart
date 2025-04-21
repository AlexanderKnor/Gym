// lib/providers/profile_screen/friendship_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/profile_screen/friendship_model.dart';
import '../../models/profile_screen/friend_request_model.dart';
import '../../models/auth/user_model.dart';
import '../../services/profile_screen/friendship_service.dart';

class FriendshipProvider with ChangeNotifier {
  final FriendshipService _friendshipService = FriendshipService();

  // State-Variablen
  List<FriendshipModel> _friends = [];
  List<FriendRequestModel> _receivedRequests = [];
  List<FriendRequestModel> _sentRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Abonnements
  StreamSubscription<List<FriendshipModel>>? _friendsSubscription;
  StreamSubscription<List<FriendRequestModel>>? _receivedRequestsSubscription;
  StreamSubscription<List<FriendRequestModel>>? _sentRequestsSubscription;

  // Getters
  List<FriendshipModel> get friends => _friends;
  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasReceivedRequests => _receivedRequests.isNotEmpty;

  // Konstruktor
  FriendshipProvider() {
    // Streams abonnieren
    _subscribeToStreams();

    // Einmalige Initialisierung
    refreshFriendData();
  }

  // Stream-Abonnements
  void _subscribeToStreams() {
    // Freunde-Stream abonnieren
    _friendsSubscription?.cancel();
    _friendsSubscription =
        _friendshipService.getFriendsStream().listen((friends) {
      _friends = friends;
      notifyListeners();
    });

    // Empfangene Anfragen abonnieren
    _receivedRequestsSubscription?.cancel();
    _receivedRequestsSubscription =
        _friendshipService.getReceivedRequestsStream().listen((requests) {
      print('PROVIDER: Empfangene Anfragen aktualisiert: ${requests.length}');
      _receivedRequests = requests;
      notifyListeners();
    });

    // Gesendete Anfragen abonnieren
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription =
        _friendshipService.getSentRequestsStream().listen((requests) {
      _sentRequests = requests;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _friendsSubscription?.cancel();
    _receivedRequestsSubscription?.cancel();
    _sentRequestsSubscription?.cancel();
    super.dispose();
  }

  // Laden der Freunde und Anfragen
  Future<void> refreshFriendData() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final friendsResult = await _friendshipService.getFriends();
      final receivedRequestsResult =
          await _friendshipService.getReceivedRequests();
      final sentRequestsResult = await _friendshipService.getSentRequests();

      _friends = friendsResult;
      _receivedRequests = receivedRequestsResult;
      _sentRequests = sentRequestsResult;
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Freundschaftsdaten: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Benutzer nach E-Mail suchen
  Future<UserModel?> findUserByEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await _friendshipService.findUserByEmail(email);
    } catch (e) {
      _errorMessage = 'Fehler beim Suchen des Benutzers: $e';
      print(_errorMessage);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Benutzer nach Benutzername suchen
  Future<List<UserModel>> findUsersByUsername(String username) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await _friendshipService.findUsersByUsername(username);
    } catch (e) {
      _errorMessage = 'Fehler beim Suchen der Benutzer: $e';
      print(_errorMessage);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Freundschaftsanfrage senden
  Future<bool> sendFriendRequest(UserModel receiver) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _friendshipService.sendFriendRequest(receiver);

      if (result) {
        // Bei Erfolg die gesendeten Anfragen aktualisieren
        final updatedSentRequests = await _friendshipService.getSentRequests();
        _sentRequests = updatedSentRequests;
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Senden der Freundschaftsanfrage: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Anfrage akzeptieren
  Future<bool> acceptFriendRequest(FriendRequestModel request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _friendshipService.acceptFriendRequest(request);

      if (result) {
        // Bei Erfolg alle Daten aktualisieren
        await refreshFriendData();
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Akzeptieren der Anfrage: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Anfrage ablehnen
  Future<bool> rejectFriendRequest(FriendRequestModel request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _friendshipService.rejectFriendRequest(request);

      if (result) {
        // Bei Erfolg die empfangenen Anfragen aktualisieren
        _receivedRequests =
            _receivedRequests.where((r) => r.id != request.id).toList();
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Ablehnen der Anfrage: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Freund entfernen
  Future<bool> removeFriend(String friendId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _friendshipService.removeFriend(friendId);

      if (result) {
        // Bei Erfolg die Freundesliste aktualisieren
        _friends = _friends.where((f) => f.friendId != friendId).toList();
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Entfernen des Freundes: $e';
      print(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Debug-Methode, die in der UI aufgerufen werden kann
  Future<void> debugReceivedRequests() async {
    print('===== DEBUG: EMPFANGENE ANFRAGEN =====');
    try {
      // Direkt die Anfragen über die existierende Methode abrufen
      final requests = await _friendshipService.getReceivedRequests();

      print('Aktueller Benutzer: [User-ID wird über Service abgerufen]');
      print('Alle Anfragen: ${requests.length}');

      for (var request in requests) {
        print('Anfrage: ${request.id}');
        print('Daten: Sender=${request.senderId}, Status=${request.status}');
      }

      // Gefilterte Anfragen (nur ausstehende)
      final pendingRequests =
          requests.where((r) => r.status == 'pending').toList();
      print('Ausstehende Anfragen: ${pendingRequests.length}');

      // Lokale Daten
      print('Im Provider gespeicherte Anfragen: ${_receivedRequests.length}');
      for (var request in _receivedRequests) {
        print('Request ID: ${request.id}');
        print('Sender: ${request.senderUsername} (${request.senderId})');
        print('Status: ${request.status}');
      }
    } catch (e) {
      print('Debug-Fehler: $e');
    }
    print('===== ENDE DEBUG =====');
  }

  // Hilfsmethode: Loading-Zustand aktualisieren
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
