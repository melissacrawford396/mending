import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/completion.dart';
import '../domain/my_exercise.dart';
import '../domain/review_row.dart';

/// Local snapshot. Completions and reviews are append-only rows.
class StoreData {
  const StoreData({
    required this.initialized,
    required this.exercises,
    required this.completions,
    required this.reviews,
    required this.skippedReviewSession,
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
  final List<ReviewRow> reviews;
  final String? skippedReviewSession;

  Map<String, dynamic> toJson() => {
    'initialized': initialized,
    'exercises': [for (final row in exercises) row.toJson()],
    'completions': [for (final row in completions) row.toJson()],
    'reviews': [for (final row in reviews) row.toJson()],
    'skippedReviewSession': skippedReviewSession,
  };

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      initialized: json['initialized'] as bool? ?? false,
      exercises: [
        for (final row in json['exercises'] as List? ?? const [])
          MyExercise.fromJson(row as Map<String, dynamic>),
      ],
      completions: [
        for (final row in json['completions'] as List? ?? const [])
          Completion.fromJson(row as Map<String, dynamic>),
      ],
      reviews: [
        for (final row in json['reviews'] as List? ?? const [])
          ReviewRow.fromJson(row as Map<String, dynamic>),
      ],
      skippedReviewSession: json['skippedReviewSession'] as String?,
    );
  }
}

abstract class MendingStore {
  Future<StoreData> load();
  Future<void> saveExercises(List<MyExercise> exercises);
  Future<void> appendCompletion(Completion row);
  Future<void> appendReviews(List<ReviewRow> rows);
  Future<void> setSkippedReviewSession(String sessionKey);
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
    _cache = StoreData(
      initialized: true,
      exercises: List.of(exercises),
      completions: _cache.completions,
      reviews: _cache.reviews,
      skippedReviewSession: _cache.skippedReviewSession,
    );
  }

  @override
  Future<void> appendCompletion(Completion row) async {
    _guard();
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: [..._cache.completions, row],
      reviews: _cache.reviews,
      skippedReviewSession: _cache.skippedReviewSession,
    );
  }

  @override
  Future<void> appendReviews(List<ReviewRow> rows) async {
    _guard();
    if (rows.isEmpty) return;
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: _cache.completions,
      reviews: [..._cache.reviews, ...rows],
      skippedReviewSession: _cache.skippedReviewSession,
    );
  }

  @override
  Future<void> setSkippedReviewSession(String sessionKey) async {
    _guard();
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: _cache.completions,
      reviews: _cache.reviews,
      skippedReviewSession: sessionKey,
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
    reviews: List.of(data.reviews),
    skippedReviewSession: data.skippedReviewSession,
  );
}

/// Rewrites one document, but completion and review rows are only appended.
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
    _cache = StoreData(
      initialized: true,
      exercises: List.of(exercises),
      completions: _cache.completions,
      reviews: _cache.reviews,
      skippedReviewSession: _cache.skippedReviewSession,
    );
    await _write();
  }

  @override
  Future<void> appendCompletion(Completion row) async {
    _guard();
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: [..._cache.completions, row],
      reviews: _cache.reviews,
      skippedReviewSession: _cache.skippedReviewSession,
    );
    await _write();
  }

  @override
  Future<void> appendReviews(List<ReviewRow> rows) async {
    _guard();
    if (rows.isEmpty) return;
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: _cache.completions,
      reviews: [..._cache.reviews, ...rows],
      skippedReviewSession: _cache.skippedReviewSession,
    );
    await _write();
  }

  @override
  Future<void> setSkippedReviewSession(String sessionKey) async {
    _guard();
    _cache = StoreData(
      initialized: _cache.initialized,
      exercises: _cache.exercises,
      completions: _cache.completions,
      reviews: _cache.reviews,
      skippedReviewSession: sessionKey,
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
