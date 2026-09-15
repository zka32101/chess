import 'package:cloud_firestore/cloud_firestore.dart';

class RankingService {
  static final RankingService _instance = RankingService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<PlayerRanking>> _rankingCache = {};

  factory RankingService() {
    return _instance;
  }

  RankingService._internal();

  Future<List<PlayerRanking>> getGlobalRankings(int limit) async {
    if (_rankingCache.containsKey('global')) {
      return _rankingCache['global']!;
    }

    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      final rankings = snapshot.docs
          .asMap()
          .entries
          .map((e) => PlayerRanking.fromJson(e.value.data(), rank: e.key + 1))
          .toList();

      _rankingCache['global'] = rankings;
      Future.delayed(Duration(minutes: 5)).then((_) {
        _rankingCache.remove('global');
      });

      return rankings;
    } catch (e) {
      print('Error fetching global rankings: $e');
      return [];
    }
  }

  Future<List<PlayerRanking>> getRegionalRankings(
      String region, int limit) async {
    final cacheKey = 'region_$region';
    if (_rankingCache.containsKey(cacheKey)) {
      return _rankingCache[cacheKey]!;
    }

    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('regional')
          .collection(region)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      final rankings = snapshot.docs
          .asMap()
          .entries
          .map((e) => PlayerRanking.fromJson(e.value.data(), rank: e.key + 1))
          .toList();

      _rankingCache[cacheKey] = rankings;
      Future.delayed(Duration(minutes: 5)).then((_) {
        _rankingCache.remove(cacheKey);
      });

      return rankings;
    } catch (e) {
      print('Error fetching regional rankings: $e');
      return [];
    }
  }

  Future<List<PlayerRanking>> getFriendRankings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final friendIds = List<String>.from(userDoc['friends'] ?? []);

      if (friendIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .where(FieldPath.documentId, whereIn: friendIds)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlayerRanking.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching friend rankings: $e');
      return [];
    }
  }

  Future<int> getUserRankPosition(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .orderBy('rating', descending: true)
          .get();

      final index = snapshot.docs.indexWhere((doc) => doc.id == userId);
      return index >= 0 ? index + 1 : -1;
    } catch (e) {
      print('Error fetching user rank: $e');
      return -1;
    }
  }

  Future<void> updatePlayerRanking(String userId, GameResult result) async {
    try {
      final playerDoc = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .doc(userId)
          .get();

      int currentRating = playerDoc['rating'] ?? 1000;
      int wins = playerDoc['wins'] ?? 0;
      int losses = playerDoc['losses'] ?? 0;

      if (result.isWin) {
        wins++;
        currentRating += 16;
      } else if (!result.isDraw) {
        losses++;
        currentRating -= 16;
      }

      final newWinRate = wins / (wins + losses);

      await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .doc(userId)
          .update({
        'rating': currentRating,
        'wins': wins,
        'losses': losses,
        'winRate': newWinRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _rankingCache.clear();
    } catch (e) {
      print('Error updating player ranking: $e');
    }
  }

  Future<RankingStatistics> getRankingStatistics() async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('players')
          .get();

      final ratings = snapshot.docs.map((doc) => doc['rating'] as int).toList();
      final totalPlayers = ratings.length;
      final averageRating =
          ratings.fold(0, (a, b) => a + b) / (totalPlayers > 0 ? totalPlayers : 1);
      final topPlayerRating = ratings.isNotEmpty ? ratings.first : 0;

      return RankingStatistics(
        totalPlayers: totalPlayers,
        averageRating: averageRating,
        topPlayerRating: topPlayerRating,
        distribution: [],
      );
    } catch (e) {
      print('Error fetching ranking statistics: $e');
      return RankingStatistics(
        totalPlayers: 0,
        averageRating: 0,
        topPlayerRating: 0,
        distribution: [],
      );
    }
  }
}

class PlayerRanking {
  final String userId;
  final String username;
  final int rating;
  final int rank;
  final int wins;
  final int losses;
  final double winRate;
  final String region;
  final DateTime updatedAt;

  PlayerRanking({
    required this.userId,
    required this.username,
    required this.rating,
    required this.rank,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.region,
    required this.updatedAt,
  });

  factory PlayerRanking.fromJson(Map<String, dynamic> json, {int rank = 0}) {
    return PlayerRanking(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      rating: json['rating'] ?? 1000,
      rank: rank,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      winRate: (json['winRate'] ?? 0.0).toDouble(),
      region: json['region'] ?? 'Global',
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'rating': rating,
      'wins': wins,
      'losses': losses,
      'winRate': winRate,
      'region': region,
      'updatedAt': updatedAt,
    };
  }
}

class RankingStatistics {
  final int totalPlayers;
  final double averageRating;
  final int topPlayerRating;
  final List<RatingDistribution> distribution;

  RankingStatistics({
    required this.totalPlayers,
    required this.averageRating,
    required this.topPlayerRating,
    required this.distribution,
  });
}

class RatingDistribution {
  final String tier;
  final int playerCount;
  final double percentage;

  RatingDistribution({
    required this.tier,
    required this.playerCount,
    required this.percentage,
  });
}

class GameResult {
  final bool isWin;
  final bool isDraw;

  GameResult({required this.isWin, required this.isDraw});
}
