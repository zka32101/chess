import 'package:cloud_firestore/cloud_firestore.dart';

class PaginationParams {
  final int pageSize;
  final DocumentSnapshot? startAfter;
  final bool descending;

  PaginationParams({
    this.pageSize = 20,
    this.startAfter,
    this.descending = true,
  }) : assert(pageSize > 0 && pageSize <= 100, 'Page size must be between 1 and 100');
}

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? nextPageToken;
  final bool hasMore;
  final int totalRetrieved;

  PaginatedResult({
    required this.items,
    required this.nextPageToken,
    required this.hasMore,
    required this.totalRetrieved,
  });

  factory PaginatedResult.empty() {
    return PaginatedResult(
      items: [],
      nextPageToken: null,
      hasMore: false,
      totalRetrieved: 0,
    );
  }
}

class CursorPaginationParams {
  final String? cursor;
  final int pageSize;
  final String cursorField;

  CursorPaginationParams({
    this.cursor,
    this.pageSize = 20,
    required this.cursorField,
  }) : assert(pageSize > 0 && pageSize <= 100);
}

class CursorPaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  CursorPaginatedResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  factory CursorPaginatedResult.empty() {
    return CursorPaginatedResult(
      items: [],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class QueryOptimizer {
  static Query<Map<String, dynamic>> applyPagination(
    Query<Map<String, dynamic>> baseQuery,
    PaginationParams params,
  ) {
    Query<Map<String, dynamic>> query = baseQuery;

    if (params.startAfter != null) {
      query = query.startAfterDocument(params.startAfter!);
    }

    query = query.limit(params.pageSize + 1);

    return query;
  }

  static Future<PaginatedResult<T>> executePaginatedQuery<T>(
    Query<Map<String, dynamic>> query,
    PaginationParams params,
    T Function(Map<String, dynamic>) converter,
  ) async {
    try {
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return PaginatedResult.empty();
      }

      final hasMore = snapshot.docs.length > params.pageSize;
      final items = snapshot.docs
          .take(params.pageSize)
          .map((doc) => converter(doc.data()))
          .toList();

      final nextToken = hasMore ? snapshot.docs[params.pageSize - 1] : null;

      return PaginatedResult(
        items: items,
        nextPageToken: nextToken,
        hasMore: hasMore,
        totalRetrieved: items.length,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class BatchQueryHelper {
  static List<List<T>> chunk<T>(List<T> items, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < items.length; i += chunkSize) {
      chunks.add(items.sublist(
        i,
        i + chunkSize > items.length ? items.length : i + chunkSize,
      ));
    }
    return chunks;
  }

  static Future<List<T>> executeBatchQueries<T>(
    List<Future<List<T>> Function()> queryFunctions,
  ) async {
    final results = <T>[];
    for (final queryFunc in queryFunctions) {
      final items = await queryFunc();
      results.addAll(items);
    }
    return results;
  }
}
