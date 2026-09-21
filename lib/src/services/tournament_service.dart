import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/phase_k_models.dart';

/// Tournament management service for organized competitive play
class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Tournament> _tournamentCache = {};
  final Map<String, List<TournamentMatch>> _matchCache = {};
  final Map<String, TournamentStandings> _standingsCache = {};

  factory TournamentService() => _instance;
  TournamentService._internal();

  static TournamentService get instance => _instance;

  /// Create new tournament
  Future<Tournament> createTournament({
    required String name,
    required String description,
    required String format,
    required int maxParticipants,
    required String timeControl,
    required int entryFee,
    required int prizePool,
    required String createdBy,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final tournamentId = DateTime.now().millisecondsSinceEpoch.toString();

      final tournament = Tournament(
        tournamentId: tournamentId,
        name: name,
        description: description,
        status: 'registration',
        startDate: startDate,
        endDate: endDate,
        format: format,
        maxParticipants: maxParticipants,
        currentParticipants: 0,
        timeControl: timeControl,
        entryFee: entryFee,
        prizePool: prizePool,
        createdBy: createdBy,
        participantIds: [],
      );

      await _firestore.collection('tournaments').doc(tournamentId).set({
        'tournamentId': tournamentId,
        'name': name,
        'description': description,
        'status': 'registration',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': FieldValue.serverTimestamp(),
        'format': format,
        'maxParticipants': maxParticipants,
        'currentParticipants': 0,
        'timeControl': timeControl,
        'entryFee': entryFee,
        'prizePool': prizePool,
        'createdBy': createdBy,
        'participantIds': [],
      });

      return tournament;
    } catch (e) {
      debugPrint('Error creating tournament: $e');
      rethrow;
    }
  }

  /// Register participant
  Future<void> registerParticipant(
    String tournamentId,
    String userId,
    String username,
    int seedRating,
  ) async {
    try {
      final participantId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.runTransaction((transaction) async {
        // Add participant
        transaction.set(
            _firestore
                .collection('tournaments')
                .doc(tournamentId)
                .collection('participants')
                .doc(participantId),
            {
              'participantId': participantId,
              'tournamentId': tournamentId,
              'userId': userId,
              'username': username,
              'seedRating': seedRating,
              'joinedAt': FieldValue.serverTimestamp(),
              'status': 'registered',
              'points': 0,
              'wins': 0,
              'losses': 0,
              'draws': 0,
              'opponentIds': [],
            });

        // Update tournament participant count
        transaction
            .update(_firestore.collection('tournaments').doc(tournamentId), {
          'currentParticipants': FieldValue.increment(1),
          'participantIds': FieldValue.arrayUnion([userId]),
        });
      });

      _tournamentCache.remove(tournamentId);
    } catch (e) {
      debugPrint('Error registering participant: $e');
      rethrow;
    }
  }

  /// Generate tournament bracket
  Future<List<TournamentMatch>> generateBracket(
    String tournamentId,
  ) async {
    try {
      final participantsSnapshot = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .where('status', isEqualTo: 'registered')
          .get();

      final participants = participantsSnapshot.docs
          .map((doc) => TournamentParticipant.fromJson(doc.data()))
          .toList();

      // Sort by seed rating
      participants.sort((a, b) => b.seedRating.compareTo(a.seedRating));

      final matches = <TournamentMatch>[];
      int round = 1;

      // Simple pairing for round 1
      for (int i = 0; i < participants.length - 1; i += 2) {
        final matchId =
            DateTime.now().millisecondsSinceEpoch.toString() + '_$i';

        matches.add(TournamentMatch(
          matchId: matchId,
          tournamentId: tournamentId,
          round: round,
          player1Id: participants[i].userId,
          player2Id: participants[i + 1].userId,
          status: 'scheduled',
          scheduledAt: DateTime.now().add(Duration(hours: round)),
          startedAt: null,
          completedAt: null,
          winnerId: null,
          loserId: null,
          gameId: null,
        ));
      }

      // Save matches to Firestore
      for (final match in matches) {
        await _firestore
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(match.matchId)
            .set({
          'matchId': match.matchId,
          'tournamentId': match.tournamentId,
          'round': match.round,
          'player1Id': match.player1Id,
          'player2Id': match.player2Id,
          'status': 'scheduled',
          'scheduledAt': FieldValue.serverTimestamp(),
          'startedAt': null,
          'completedAt': null,
          'winnerId': null,
          'loserId': null,
          'gameId': null,
        });
      }

      _matchCache.remove(tournamentId);
      return matches;
    } catch (e) {
      debugPrint('Error generating bracket: $e');
      rethrow;
    }
  }

  /// Record match result
  Future<void> recordMatchResult({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required String gameId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update match
        transaction.update(
            _firestore
                .collection('tournaments')
                .doc(tournamentId)
                .collection('matches')
                .doc(matchId),
            {
              'status': 'completed',
              'winnerId': winnerId,
              'loserId': loserId,
              'gameId': gameId,
              'completedAt': FieldValue.serverTimestamp(),
            });

        // Update winner stats
        transaction.update(
            _firestore
                .collection('tournaments')
                .doc(tournamentId)
                .collection('participants')
                .doc(winnerId),
            {
              'wins': FieldValue.increment(1),
              'points': FieldValue.increment(3),
            });

        // Update loser stats
        transaction.update(
            _firestore
                .collection('tournaments')
                .doc(tournamentId)
                .collection('participants')
                .doc(loserId),
            {
              'losses': FieldValue.increment(1),
            });
      });

      _matchCache.remove(tournamentId);
      _standingsCache.remove(tournamentId);
    } catch (e) {
      debugPrint('Error recording match result: $e');
      rethrow;
    }
  }

  /// Get tournament details
  Future<Tournament> getTournament(String tournamentId) async {
    if (_tournamentCache.containsKey(tournamentId)) {
      return _tournamentCache[tournamentId]!;
    }

    try {
      final doc =
          await _firestore.collection('tournaments').doc(tournamentId).get();

      if (!doc.exists) throw Exception('Tournament not found');

      final tournament = Tournament.fromJson(doc.data()!);
      _tournamentCache[tournamentId] = tournament;
      return tournament;
    } catch (e) {
      debugPrint('Error fetching tournament: $e');
      rethrow;
    }
  }

  /// Get tournament standings
  Future<TournamentStandings> getStandings(String tournamentId) async {
    if (_standingsCache.containsKey(tournamentId)) {
      return _standingsCache[tournamentId]!;
    }

    try {
      final participantsSnapshot = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants')
          .orderBy('points', descending: true)
          .orderBy('wins', descending: true)
          .get();

      final rankings = participantsSnapshot.docs.asMap().entries.map((entry) {
        final doc = entry.value.data();
        return TournamentRanking(
          position: entry.key + 1,
          userId: doc['userId'],
          username: doc['username'],
          points: doc['points'] ?? 0,
          wins: doc['wins'] ?? 0,
          losses: doc['losses'] ?? 0,
          draws: doc['draws'] ?? 0,
          buchholz: 0.0,
          performance: 0,
        );
      }).toList();

      final standings = TournamentStandings(
        tournamentId: tournamentId,
        rankings: rankings,
        lastUpdated: DateTime.now(),
      );

      _standingsCache[tournamentId] = standings;
      return standings;
    } catch (e) {
      debugPrint('Error fetching standings: $e');
      rethrow;
    }
  }

  /// Get tournament matches
  Future<List<TournamentMatch>> getTournamentMatches(
    String tournamentId, {
    int? round,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .orderBy('round')
          .orderBy('scheduledAt');

      if (round != null) {
        query = query.where('round', isEqualTo: round);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => TournamentMatch.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching tournament matches: $e');
      return [];
    }
  }

  /// Get active tournaments
  Future<List<Tournament>> getActiveTournaments() async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .where('status', whereIn: ['registration', 'in-progress'])
          .orderBy('startDate')
          .get();

      return snapshot.docs
          .map((doc) => Tournament.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active tournaments: $e');
      return [];
    }
  }

  /// Distribute prizes
  Future<void> distributePrizes(String tournamentId) async {
    try {
      final standings = await getStandings(tournamentId);
      final tournament = await getTournament(tournamentId);

      final prizeDistribution = _calculatePrizeDistribution(
          tournament.prizePool, standings.rankings.length);

      for (int i = 0; i < standings.rankings.length && i < 3; i++) {
        final ranking = standings.rankings[i];
        final prizeAmount = prizeDistribution[i];

        await _firestore.collection('user_rewards').doc(ranking.userId).update({
          'totalPrizeWinnings': FieldValue.increment(prizeAmount),
          'tournaments': FieldValue.increment(1),
        });
      }

      // Mark tournament as completed
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .update({'status': 'completed'});

      _tournamentCache.remove(tournamentId);
    } catch (e) {
      debugPrint('Error distributing prizes: $e');
      rethrow;
    }
  }

  /// Calculate prize distribution
  List<int> _calculatePrizeDistribution(int totalPrize, int participantCount) {
    // Standard 50-30-20 distribution for top 3
    if (participantCount >= 3) {
      return [
        (totalPrize * 0.5).toInt(),
        (totalPrize * 0.3).toInt(),
        (totalPrize * 0.2).toInt(),
      ];
    } else if (participantCount == 2) {
      return [
        (totalPrize * 0.6).toInt(),
        (totalPrize * 0.4).toInt(),
      ];
    } else {
      return [totalPrize];
    }
  }

  /// Clear cache
  void clearCache() {
    _tournamentCache.clear();
    _matchCache.clear();
    _standingsCache.clear();
  }
}

// Extension methods for Tournament.fromJson
extension TournamentFromJson on Tournament {
  static Tournament fromJson(Map<String, dynamic> json) {
    return Tournament(
      tournamentId: json['tournamentId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      format: json['format'] as String,
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
      timeControl: json['timeControl'] as String,
      entryFee: json['entryFee'] as int,
      prizePool: json['prizePool'] as int,
      createdBy: json['createdBy'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
    );
  }
}

// Extension methods for TournamentParticipant.fromJson
extension TournamentParticipantFromJson on TournamentParticipant {
  static TournamentParticipant fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      participantId: json['participantId'] as String,
      tournamentId: json['tournamentId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      seedRating: json['seedRating'] as int,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      status: json['status'] as String,
      points: json['points'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      opponentIds: List<String>.from(json['opponentIds'] as List? ?? []),
    );
  }
}

// Extension methods for TournamentMatch.fromJson
extension TournamentMatchFromJson on TournamentMatch {
  static TournamentMatch fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      matchId: json['matchId'] as String,
      tournamentId: json['tournamentId'] as String,
      round: json['round'] as int,
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
      status: json['status'] as String,
      scheduledAt: (json['scheduledAt'] as Timestamp).toDate(),
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      winnerId: json['winnerId'] as String?,
      loserId: json['loserId'] as String?,
      gameId: json['gameId'] as String?,
    );
  }
}
