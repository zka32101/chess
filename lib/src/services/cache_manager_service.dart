import 'package:flutter/foundation.dart';

/// Unified cache management service for Chess Tactics Master.
/// Implements LRU eviction policy and TTL-based expiration.
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration? ttl;
  DateTime lastAccessedAt;

  CacheEntry({
    required this.value,
    this.ttl,
  })  : createdAt = DateTime.now(),
        lastAccessedAt = DateTime.now();

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }

  T get(T? defaultValue) {
    if (isExpired) return defaultValue as T;
    lastAccessedAt = DateTime.now();
    return value;
  }
}

/// Central cache manager using LRU eviction and TTL expiration.
class CacheManagerService {
  static final CacheManagerService _instance = CacheManagerService._internal();
  static const int defaultMaxSize = 500;
  static const Duration defaultTtl = Duration(hours: 1);

  final Map<String, CacheEntry> _cache = {};
  final int _maxSize;
  final Duration _defaultTtl;

  factory CacheManagerService({int maxSize = defaultMaxSize, Duration? ttl}) {
    return _instance;
  }

  CacheManagerService._internal()
      : _maxSize = defaultMaxSize,
        _defaultTtl = defaultTtl;

  /// Store a value in cache with optional TTL.
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry<T>(
      value: value,
      ttl: ttl ?? _defaultTtl,
    );
    _evictIfNeeded();
  }

  /// Retrieve a value from cache.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.get(null) as T?;
  }

  /// Check if key exists and is not expired.
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove a specific key from cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache entries.
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries.
  void clearExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Get cache statistics.
  CacheStats getStats() {
    clearExpired();
    return CacheStats(
      totalEntries: _cache.length,
      maxSize: _maxSize,
      utilizationPercent: (_cache.length / _maxSize * 100).toStringAsFixed(1),
    );
  }

  /// Evict least recently used entry when cache is full.
  void _evictIfNeeded() {
    if (_cache.length <= _maxSize) return;

    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    final toRemove = sortedEntries.first.key;
    _cache.remove(toRemove);
  }
}

/// Cache statistics for monitoring.
class CacheStats {
  final int totalEntries;
  final int maxSize;
  final String utilizationPercent;

  CacheStats({
    required this.totalEntries,
    required this.maxSize,
    required this.utilizationPercent,
  });

  @override
  String toString() =>
      'CacheStats(entries: $totalEntries/$maxSize, utilization: $utilizationPercent%)';
}
