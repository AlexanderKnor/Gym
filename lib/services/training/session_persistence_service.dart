import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/active_training_session.dart';
import '../../models/training_plan_screen/training_plan_model.dart';
import '../../models/training_plan_screen/training_day_model.dart';
import '../../models/training_history/training_session_model.dart';
import '../../models/progression_manager_screen/training_set_model.dart';
import '../../models/training_plan_screen/exercise_model.dart';

class SessionPersistenceService {
  static const String ACTIVE_SESSION_KEY = 'active_training_session';
  static const String SESSION_TIMESTAMP_KEY = 'session_timestamp';
  static const int SESSION_EXPIRY_HOURS = 24;

  Future<void> saveSession(ActiveTrainingSession session) async {
    try {
      print('SessionPersistenceService: Starte Speichervorgang...');
      final prefs = await SharedPreferences.getInstance();
      
      final sessionData = _encodeSession(session);
      final jsonString = jsonEncode(sessionData);
      
      await prefs.setString(ACTIVE_SESSION_KEY, jsonString);
      await prefs.setString(SESSION_TIMESTAMP_KEY, DateTime.now().toIso8601String());
      
      print('SessionPersistenceService: Training session saved successfully (${jsonString.length} chars)');
    } catch (e) {
      print('SessionPersistenceService: Error saving training session: $e');
    }
  }

  Future<ActiveTrainingSession?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final timestampString = prefs.getString(SESSION_TIMESTAMP_KEY);
      if (timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final hoursSinceLastSave = DateTime.now().difference(timestamp).inHours;
        
        if (hoursSinceLastSave >= SESSION_EXPIRY_HOURS) {
          print('Session is too old (${hoursSinceLastSave} hours). Discarding.');
          await clearSession();
          return null;
        }
      }
      
      final jsonString = prefs.getString(ACTIVE_SESSION_KEY);
      if (jsonString == null) {
        return null;
      }
      
      final sessionData = jsonDecode(jsonString) as Map<String, dynamic>;
      return _decodeSession(sessionData);
    } catch (e) {
      print('Error loading training session: $e');
      await clearSession();
      return null;
    }
  }

  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Prüfe erst, ob Session-Key existiert
    if (!prefs.containsKey(ACTIVE_SESSION_KEY)) {
      print('SessionPersistenceService: hasActiveSession = false (kein Session-Key)');
      return false;
    }
    
    // Prüfe Session-Ablaufzeit
    final timestampString = prefs.getString(SESSION_TIMESTAMP_KEY);
    if (timestampString != null) {
      final timestamp = DateTime.parse(timestampString);
      final hoursSinceLastSave = DateTime.now().difference(timestamp).inHours;
      
      if (hoursSinceLastSave >= SESSION_EXPIRY_HOURS) {
        print('SessionPersistenceService: Session ist abgelaufen (${hoursSinceLastSave} Stunden). Lösche automatisch.');
        await clearSession();
        return false;
      }
    }
    
    print('SessionPersistenceService: hasActiveSession = true (gültige Session gefunden)');
    return true;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ACTIVE_SESSION_KEY);
    await prefs.remove(SESSION_TIMESTAMP_KEY);
    print('Training session cleared');
  }

  Map<String, dynamic> _encodeSession(ActiveTrainingSession session) {
    try {
      print('Encoding session...');
      
      final data = <String, dynamic>{
        'trainingPlan': session.trainingPlan.toJson(),
        'trainingDay': session.trainingDay.toJson(),
        'dayIndex': session.dayIndex,
        'weekIndex': session.weekIndex,
        'currentSession': session.currentSession?.toJson(),
        'hasBeenSaved': session.hasBeenSaved,
        'currentExerciseIndex': session.currentExerciseIndex,
        'exerciseSets': _encodeExerciseSets(session.exerciseSets),
        'activeSetByExercise': _convertIntKeys(session.activeSetByExercise),
        'exerciseCompletionStatus': _convertIntKeysBool(session.exerciseCompletionStatus),
        'lastCompletedSetIndexByExercise': _convertIntKeys(session.lastCompletedSetIndexByExercise),
        'isResting': session.isResting,
        'restTimeRemaining': session.restTimeRemaining,
        'isPaused': session.isPaused,
        'isTrainingCompleted': session.isTrainingCompleted,
        'originalExercises': _encodeExerciseMap(session.originalExercises),
        'exerciseConfigModified': _convertIntKeysBool(session.exerciseConfigModified),
        'addedExercises': session.addedExercises.map((e) => e.toJson()).toList(),
        'deletedExercises': session.deletedExercises.map((e) => e.toJson()).toList(),
      };
      
      print('Session encoded successfully');
      return data;
    } catch (e) {
      print('Error encoding session: $e');
      rethrow;
    }
  }

  Map<String, int> _convertIntKeys(Map<int, int> intMap) {
    final result = <String, int>{};
    intMap.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  Map<String, bool> _convertIntKeysBool(Map<int, bool> intMap) {
    final result = <String, bool>{};
    intMap.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  Map<int, int> _decodeIntKeys(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final result = <int, int>{};
    data.forEach((key, value) {
      result[int.parse(key)] = value as int;
    });
    return result;
  }

  Map<int, bool> _decodeIntKeysBool(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final result = <int, bool>{};
    data.forEach((key, value) {
      result[int.parse(key)] = value as bool;
    });
    return result;
  }

  ActiveTrainingSession _decodeSession(Map<String, dynamic> data) {
    final session = ActiveTrainingSession(
      trainingPlan: TrainingPlanModel.fromJson(data['trainingPlan']),
      trainingDay: TrainingDayModel.fromJson(data['trainingDay']),
      dayIndex: data['dayIndex'],
      weekIndex: data['weekIndex'] ?? 0,
    );
    
    session.currentSession = data['currentSession'] != null 
        ? TrainingSessionModel.fromJson(data['currentSession']) 
        : null;
    session.hasBeenSaved = data['hasBeenSaved'] ?? false;
    session.currentExerciseIndex = data['currentExerciseIndex'] ?? 0;
    session.exerciseSets = _decodeExerciseSets(data['exerciseSets']);
    session.activeSetByExercise = _decodeIntKeys(data['activeSetByExercise']);
    session.exerciseCompletionStatus = _decodeIntKeysBool(data['exerciseCompletionStatus']);
    session.lastCompletedSetIndexByExercise = _decodeIntKeys(data['lastCompletedSetIndexByExercise']);
    session.isResting = data['isResting'] ?? false;
    session.restTimeRemaining = data['restTimeRemaining'] ?? 0;
    session.isPaused = data['isPaused'] ?? false;
    session.isTrainingCompleted = data['isTrainingCompleted'] ?? false;
    session.originalExercises = _decodeExerciseMap(data['originalExercises']);
    session.exerciseConfigModified = _decodeIntKeysBool(data['exerciseConfigModified']);
    session.addedExercises = (data['addedExercises'] as List<dynamic>?)
        ?.map((e) => ExerciseModel.fromJson(e))
        .toList() ?? [];
    session.deletedExercises = (data['deletedExercises'] as List<dynamic>?)
        ?.map((e) => ExerciseModel.fromJson(e))
        .toList() ?? [];
    
    return session;
  }

  Map<String, dynamic> _encodeExerciseSets(Map<int, List<TrainingSetModel>> exerciseSets) {
    final encoded = <String, dynamic>{};
    exerciseSets.forEach((key, value) {
      encoded[key.toString()] = value.map((set) => set.toJson()).toList();
    });
    return encoded;
  }

  Map<int, List<TrainingSetModel>> _decodeExerciseSets(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final decoded = <int, List<TrainingSetModel>>{};
    data.forEach((key, value) {
      final exerciseIndex = int.parse(key);
      final sets = (value as List<dynamic>)
          .map((setData) => TrainingSetModel.fromJson(setData))
          .toList();
      decoded[exerciseIndex] = sets;
    });
    return decoded;
  }

  Map<String, dynamic> _encodeExerciseMap(Map<int, ExerciseModel> exerciseMap) {
    final encoded = <String, dynamic>{};
    exerciseMap.forEach((key, value) {
      encoded[key.toString()] = value.toJson();
    });
    return encoded;
  }

  Map<int, ExerciseModel> _decodeExerciseMap(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final decoded = <int, ExerciseModel>{};
    data.forEach((key, value) {
      final exerciseIndex = int.parse(key);
      decoded[exerciseIndex] = ExerciseModel.fromJson(value);
    });
    return decoded;
  }
}