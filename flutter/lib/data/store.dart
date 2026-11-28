import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/completion.dart';
import '../domain/my_exercise.dart';
import '../domain/review_row.dart';

const _keep = Object();

/// Local snapshot. New sessions are appended. Edits and deletes rewrite the log.
class StoreData {
  const StoreData({
    required this.initialized,
    required this.exercises,
    required this.completions,
    this.deleted = const [],
    required this.reviews,
    required this.skippedReviewSession,
    this.use24Hour = true,
    this.darkMode = false,
    this.signedIn = true,
  });

  static const empty = StoreData(
    initialized: false,
    exercises: [],
    completions: [],
    reviews: [],
    skippedReviewSession: null,
  );

  final bool initialized;
  final List<MyExercise> exercises;
  final List<Completion> completions;
  final List<DeletedCompletion> deleted;
  final List<ReviewRow> reviews;
  final String? skippedReviewSession;
  final bool use24Hour;
  final bool darkMode;
  final bool signedIn;

  StoreData copyWith({
    bool? initialized,
    List<MyExercise>? exercises,
    List<Completion>? completions,
    List<DeletedCompletion>? deleted,
    List<ReviewRow>? reviews,
    Object? skippedReviewSession = _keep,
    bool? use24Hour,
    bool? darkMode,
    bool? signedIn,
  }) {
    return StoreData(
      initialized: initialized ?? this.initialized,
      exercises: exercises ?? this.exercises,
      completions: completions ?? this.completions,
      deleted: deleted ?? this.deleted,
      reviews: reviews ?? this.reviews,
      skippedReviewSession: identical(skippedReviewSession, _keep)
          ? this.skippedReviewSession
          : skippedReviewSession as String?,
      use24Hour: use24Hour ?? this.use24Hour,
      darkMode: darkMode ?? this.darkMode,
      signedIn: signedIn ?? this.signedIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': storeSchemaVersion,
    'initialized': initialized,
    'exercises': [for (final row in exercises) row.toJson()],
    'completions': [for (final row in completions) row.toJson()],
    'deleted': [for (final row in deleted) row.toJson()],
    'reviews': [for (final row in reviews) row.toJson()],
    'skippedReviewSession': skippedReviewSession,
    'use24Hour': use24Hour,
    'darkMode': darkMode,
    'signedIn': signedIn,
  };

  factory StoreData.fromJson(Map<String, dynamic> raw) {
    final json = _migrate(raw);
    return StoreData(
      initialized: json['initialized'] as bool? ?? false,
      exercises: _rows(json['exercises'], MyExercise.fromJson),
      completions: _rows(json['completions'], Completion.fromJson),
      deleted: _rows(json['deleted'], DeletedCompletion.fromJson),
      reviews: _rows(json['reviews'], ReviewRow.fromJson),
      skippedReviewSession: json['skippedReviewSession'] as String?,
      use24Hour: json['use24Hour'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      signedIn: json['signedIn'] as bool? ?? true,
    );
  }
}

/// Layout written by this build. Bump it and add a step to [_migrate] when a
/// saved field is renamed or changes meaning. Added fields only need a default
/// in their `fromJson`.
const storeSchemaVersion = 2;

Map<String, dynamic> _migrate(Map<String, dynamic> json) {
  var data = json;
  if ((data['schemaVersion'] as int? ?? 1) < 2) data = _namesToIds(data);
  return data;
}

/// Version 1 joined rows on the display name. Only these five existed then.
const _v1Ids = {
  'Arch roll': 'arch-roll',
  'Toe flex': 'toe-flex',
  'Small shoulder circles': 'small-shoulder-circles',
  'Large arm circles': 'large-arm-circles',
  'Ankle stretch': 'ankle-stretch',
};

Map<String, dynamic> _namesToIds(Map<String, dynamic> json) {
  List<Map<String, dynamic>> rename(String table, String oldField) {
    return [
      for (final row in json[table] as List? ?? const [])
        if (row case final Map<String, dynamic> row)
          {
            for (final entry in row.entries)
              if (entry.key != oldField) entry.key: entry.value,
            'movementId': _v1Ids[row[oldField]] ?? row[oldField],
          },
    ];
  }

  return {
    ...json,
    'schemaVersion': 2,
    'exercises': rename('exercises', 'movementName'),
    'completions': rename('completions', 'exerciseName'),
    'reviews': rename('reviews', 'exerciseName'),
  };
}

/// A row this build cannot read is skipped so the rest still loads. It is
/// dropped from storage on the next write.
List<T> _rows<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  final rows = <T>[];
  for (final row in raw is List ? raw : const []) {
    try {
      rows.add(parse(row as Map<String, dynamic>));
    } on Object {
      continue;
    }
  }
  return rows;
}

abstract class MendingStore {
  Future<StoreData> load();
  Future<void> saveExercises(List<MyExercise> exercises);
  Future<void> appendCompletion(Completion row);
  Future<void> appendReviews(List<ReviewRow> rows);
  Future<void> setSkippedReviewSession(String sessionKey);

  /// Replaces the log in one write. Exercises and the skip flag stay as they are.
  Future<void> saveLog({
    required List<Completion> completions,
    required List<DeletedCompletion> deleted,
    required List<ReviewRow> reviews,
  });

  Future<void> saveSettings({
    required bool use24Hour,
    required bool darkMode,
    required bool signedIn,
  });
}

/// In-memory store for tests and the first frame before prefs load.
class MemoryMendingStore implements MendingStore {
  MemoryMendingStore([StoreData? initial])
    : _cache = initial ?? StoreData.empty;

  StoreData _cache;
  var _loaded = false;

  @override
  Future<StoreData> load() async {
    _loaded = true;
    return _copy(_cache);
  }

  @override
  Future<void> saveExercises(List<MyExercise> exercises) async {
    _guard();
    _cache = _cache.copyWith(initialized: true, exercises: List.of(exercises));
  }

  @override
  Future<void> appendCompletion(Completion row) async {
    _guard();
    _cache = _cache.copyWith(completions: [..._cache.completions, row]);
  }

  @override
  Future<void> appendReviews(List<ReviewRow> rows) async {
    _guard();
    if (rows.isEmpty) return;
    _cache = _cache.copyWith(reviews: [..._cache.reviews, ...rows]);
  }

  @override
  Future<void> setSkippedReviewSession(String sessionKey) async {
    _guard();
    _cache = _cache.copyWith(skippedReviewSession: sessionKey);
  }

  @override
  Future<void> saveLog({
    required List<Completion> completions,
    required List<DeletedCompletion> deleted,
    required List<ReviewRow> reviews,
  }) async {
    _guard();
    _cache = _cache.copyWith(
      completions: List.of(completions),
      deleted: List.of(deleted),
      reviews: List.of(reviews),
    );
  }

  @override
  Future<void> saveSettings({
    required bool use24Hour,
    required bool darkMode,
    required bool signedIn,
  }) async {
    _guard();
    _cache = _cache.copyWith(
      use24Hour: use24Hour,
      darkMode: darkMode,
      signedIn: signedIn,
    );
  }

  void _guard() {
    if (!_loaded) {
      throw StateError('Call load before writing the store');
    }
  }
}

StoreData _copy(StoreData data) {
  return StoreData(
    initialized: data.initialized,
    exercises: List.of(data.exercises),
    completions: List.of(data.completions),
    deleted: List.of(data.deleted),
    reviews: List.of(data.reviews),
    skippedReviewSession: data.skippedReviewSession,
    use24Hour: data.use24Hour,
    darkMode: data.darkMode,
    signedIn: data.signedIn,
  );
}

/// Rewrites one document. New sessions are appended. Edits replace the log.
class PrefsMendingStore implements MendingStore {
  PrefsMendingStore({this._preferences});

  static const _key = 'mending.v1';

  SharedPreferences? _preferences;
  StoreData _cache = StoreData.empty;
  var _loaded = false;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<StoreData> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_key);
    _cache = raw == null
        ? StoreData.empty
        : StoreData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _loaded = true;
    return _copy(_cache);
  }

  @override
  Future<void> saveExercises(List<MyExercise> exercises) async {
    _guard();
    _cache = _cache.copyWith(initialized: true, exercises: List.of(exercises));
    await _write();
  }

  @override
  Future<void> appendCompletion(Completion row) async {
    _guard();
    _cache = _cache.copyWith(completions: [..._cache.completions, row]);
    await _write();
  }

  @override
  Future<void> appendReviews(List<ReviewRow> rows) async {
    _guard();
    if (rows.isEmpty) return;
    _cache = _cache.copyWith(reviews: [..._cache.reviews, ...rows]);
    await _write();
  }

  @override
  Future<void> setSkippedReviewSession(String sessionKey) async {
    _guard();
    _cache = _cache.copyWith(skippedReviewSession: sessionKey);
    await _write();
  }

  @override
  Future<void> saveLog({
    required List<Completion> completions,
    required List<DeletedCompletion> deleted,
    required List<ReviewRow> reviews,
  }) async {
    _guard();
    _cache = _cache.copyWith(
      completions: List.of(completions),
      deleted: List.of(deleted),
      reviews: List.of(reviews),
    );
    await _write();
  }

  @override
  Future<void> saveSettings({
    required bool use24Hour,
    required bool darkMode,
    required bool signedIn,
  }) async {
    _guard();
    _cache = _cache.copyWith(
      use24Hour: use24Hour,
      darkMode: darkMode,
      signedIn: signedIn,
    );
    await _write();
  }

  Future<void> _write() async {
    final prefs = await _prefs();
    await prefs.setString(_key, jsonEncode(_cache.toJson()));
  }

  void _guard() {
    if (!_loaded) {
      throw StateError('Call load before writing the store');
    }
  }
}
