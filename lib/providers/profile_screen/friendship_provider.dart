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
  bool _isInitialized = false;
  bool _isInitializing = false;

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
  bool get isInitialized => _isInitialized;

  // Konstruktor
  FriendshipProvider() {
    // Die Initialisierung erfolgt durch die init()-Methode
  }

  // Initialisierung nach dem Anmelden
  Future<void> init() async {
    print('FriendshipProvider: Initialisiere Provider nach Anmeldung');

    if (_isInitialized) {
      print(
          'FriendshipProvider: Provider bereits initialisiert, aktualisiere Daten');
      return refreshFriendData();
    }

    if (_isInitializing) {
      print('FriendshipProvider: Initialisierung läuft bereits, überspringe');
      return;
    }

    _isInitializing = true;
    _isLoading = true; // Verwende _isLoading direkt statt _setLoading

    try {
      // Alte Abonnements bereinigen, falls vorhanden
      _cancelSubscriptions();

      // Streams abonnieren (keine direkten notifyListeners-Aufrufe)
      _subscribeToStreams();

      // Daten initial laden
      print('FriendshipProvider: Lade initiale Daten');

      // Daten separat laden, um Typprobleme zu vermeiden
      final receivedRequests = await _friendshipService.getReceivedRequests();
      print(
          'FriendshipProvider: ${receivedRequests.length} empfangene Anfragen geladen');
      _receivedRequests = receivedRequests;

      final sentRequests = await _friendshipService.getSentRequests();
      print(
          'FriendshipProvider: ${sentRequests.length} gesendete Anfragen geladen');
      _sentRequests = sentRequests;

      final friends = await _friendshipService.getFriends();
      print('FriendshipProvider: ${friends.length} Freunde geladen');
      _friends = friends;

      print('FriendshipProvider: Initialisierung abgeschlossen');
      _isInitialized = true;
    } catch (e) {
      print('FriendshipProvider: Fehler bei der Initialisierung: $e');
      _errorMessage = 'Fehler beim Laden der Freundschaftsdaten: $e';
    } finally {
      _isInitializing = false;
      _isLoading = false;

      // Verzögere die Benachrichtigung bis nach dem aktuellen Build-Zyklus
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Stream-Abonnements
  void _subscribeToStreams() {
    print('FriendshipProvider: Abonniere Streams');

    // Freunde-Stream abonnieren
    _friendsSubscription?.cancel();
    _friendsSubscription =
        _friendshipService.getFriendsStream().listen((friends) {
      _friends = friends;
      print('PROVIDER: Freundesliste aktualisiert: ${friends.length} Freunde');

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }, onError: (e) {
      print('Fehler im Freunde-Stream: $e');
    });

    // Empfangene Anfragen abonnieren
    _receivedRequestsSubscription?.cancel();
    _receivedRequestsSubscription =
        _friendshipService.getReceivedRequestsStream().listen((requests) {
      print('PROVIDER: Empfangene Anfragen aktualisiert: ${requests.length}');
      _receivedRequests = requests;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }, onError: (e) {
      print('Fehler im Empfangene-Anfragen-Stream: $e');
    });

    // Gesendete Anfragen abonnieren
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription =
        _friendshipService.getSentRequestsStream().listen((requests) {
      _sentRequests = requests;
      print('PROVIDER: Gesendete Anfragen aktualisiert: ${requests.length}');

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }, onError: (e) {
      print('Fehler im Gesendete-Anfragen-Stream: $e');
    });
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // Abonnements beenden
  void _cancelSubscriptions() {
    print('Beende alle Freundschafts-Stream-Abonnements');
    _friendsSubscription?.cancel();
    _friendsSubscription = null;
    _receivedRequestsSubscription?.cancel();
    _receivedRequestsSubscription = null;
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = null;
  }

  // Zurücksetzen des Providers beim Abmelden
  void reset() {
    print('Setze FriendshipProvider zurück');
    _cancelSubscriptions();
    _friends = [];
    _receivedRequests = [];
    _sentRequests = [];
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    _isInitializing = false;

    // Verzögere die Benachrichtigung
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Laden der Freunde und Anfragen
  Future<void> refreshFriendData() async {
    if (!_isInitialized && !_isInitializing) {
      return init();
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      print('FriendshipProvider: Lade Freundschaftsdaten neu');

      // Daten separat laden statt mit Future.wait
      final receivedRequests = await _friendshipService.getReceivedRequests();
      _receivedRequests = receivedRequests;

      final sentRequests = await _friendshipService.getSentRequests();
      _sentRequests = sentRequests;

      final friends = await _friendshipService.getFriends();
      _friends = friends;

      print('Freundschaftsdaten aktualisiert: ${_friends.length} Freunde, ' +
          '${_receivedRequests.length} empfangene Anfragen, ' +
          '${_sentRequests.length} gesendete Anfragen');
    } catch (e) {
      _errorMessage = 'Fehler beim Laden der Freundschaftsdaten: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Benutzer nach E-Mail suchen
  Future<UserModel?> findUserByEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      return await _friendshipService.findUserByEmail(email);
    } catch (e) {
      _errorMessage = 'Fehler beim Suchen des Benutzers: $e';
      print(_errorMessage);
      return null;
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Benutzer nach Benutzername suchen
  Future<List<UserModel>> findUsersByUsername(String username) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      return await _friendshipService.findUsersByUsername(username);
    } catch (e) {
      _errorMessage = 'Fehler beim Suchen der Benutzer: $e';
      print(_errorMessage);
      return [];
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Freundschaftsanfrage senden
  Future<bool> sendFriendRequest(UserModel receiver) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      final result = await _friendshipService.sendFriendRequest(receiver);

      if (result) {
        // Bei Erfolg die gesendeten Anfragen aktualisieren
        final sentRequestsResult = await _friendshipService.getSentRequests();
        _sentRequests = sentRequestsResult;
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Senden der Freundschaftsanfrage: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Anfrage akzeptieren
  Future<bool> acceptFriendRequest(FriendRequestModel request) async {
    _isLoading = true;
    notifyListeners();
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
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Anfrage ablehnen
  Future<bool> rejectFriendRequest(FriendRequestModel request) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      final result = await _friendshipService.rejectFriendRequest(request);

      if (result) {
        // Bei Erfolg die empfangenen Anfragen aktualisieren
        final receivedRequestsResult =
            await _friendshipService.getReceivedRequests();
        _receivedRequests = receivedRequestsResult;
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Ablehnen der Anfrage: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Freund entfernen
  Future<bool> removeFriend(String friendId) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;

    try {
      print('FriendshipProvider: Starte Entfernen des Freundes $friendId');
      final result = await _friendshipService.removeFriend(friendId);

      if (result) {
        // Bei Erfolg die lokale Freundesliste aktualisieren
        print(
            'FriendshipProvider: Freund erfolgreich entfernt, aktualisiere lokale Liste');
        final friendsResult = await _friendshipService.getFriends();
        _friends = friendsResult;
      } else {
        print('FriendshipProvider: Fehler beim Entfernen des Freundes');
      }

      return result;
    } catch (e) {
      _errorMessage = 'Fehler beim Entfernen des Freundes: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;

      // Verzögere die Benachrichtigung
      Future.microtask(() {
        notifyListeners();
      });
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
      final pendingRequests = requests
          .where((r) => r.status == FriendRequestStatus.pending)
          .toList();
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
}
