import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Matchmaking state enum
enum MatchmakingStatus {
  idle,
  searching,
  found,
  declined,
  timeout,
  error,
}

// Matchmaking notification model
class MatchmakingNotification {
  MatchmakingNotification({
    required this.opponentId,
    required this.opponentName,
    required this.opponentRating,
    this.opponentPhotoUrl,
  });
  final String opponentId;
  final String opponentName;
  final int opponentRating;
  final String? opponentPhotoUrl;
}

// Matchmaking queue service
class MatchmakingService {
  MatchmakingService(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Join matchmaking queue
  Future<String> joinQueue({
    required String timeControl,
    int? ratingRange = 200, // Rating range to match within
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Get user's current rating
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userRating = userDoc.data()?['onlineRating'] as int? ?? 1600;

      // Create queue entry
      final queueEntry = {
        'userId': user.uid,
        'rating': userRating,
        'timeControl': timeControl,
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'ratingMin': userRating - (ratingRange ?? 200),
        'ratingMax': userRating + (ratingRange ?? 200),
      };

      // Add to matchmaking queue
      final docRef =
          await _firestore.collection('matchmaking_queue').add(queueEntry);
      return docRef.id;
    } catch (e) {
      print('Error joining matchmaking queue: $e');
      rethrow;
    }
  }

  // Leave matchmaking queue
  Future<void> leaveQueue(String queueEntryId) async {
    try {
      await _firestore
          .collection('matchmaking_queue')
          .doc(queueEntryId)
          .delete();
    } catch (e) {
      print('Error leaving matchmaking queue: $e');
      rethrow;
    }
  }

  // Accept match offer
  Future<String> acceptMatch(String matchId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Update match status to accepted
      final matchDoc =
          await _firestore.collection('matches').doc(matchId).get();

      if (matchDoc.exists) {
        final matchData = matchDoc.data()!;
        final whiteId = matchData['whiteId'];
        final blackId = matchData['blackId'];
        final acceptingUserId = user.uid;

        // Determine player color based on who's accepting
        final updatedData = {...matchData};

        if (acceptingUserId == whiteId) {
          updatedData['whiteAccepted'] = true;
        } else if (acceptingUserId == blackId) {
          updatedData['blackAccepted'] = true;
        }

        // If both players accepted, create a game
        if (updatedData['whiteAccepted'] == true &&
            updatedData['blackAccepted'] == true) {
          updatedData['status'] = 'matched';
          updatedData['matchedAt'] = FieldValue.serverTimestamp();
        }

        await _firestore.collection('matches').doc(matchId).update(updatedData);

        return matchId;
      }

      throw Exception('Match not found');
    } catch (e) {
      print('Error accepting match: $e');
      rethrow;
    }
  }

  // Decline match offer
  Future<void> declineMatch(String matchId) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error declining match: $e');
      rethrow;
    }
  }

  // Get pending match for current user
  Future<Map<String, dynamic>?> getPendingMatch() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final snapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'pending')
          .where(
            Filter.or(
              Filter('whiteId', isEqualTo: user.uid),
              Filter('blackId', isEqualTo: user.uid),
            ),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching pending match: $e');
      return null;
    }
  }

  // Get matchmaking stats
  Future<Map<String, dynamic>> getMatchmakingStats() async {
    try {
      final queueSnapshot =
          await _firestore.collection('matchmaking_queue').get();
      final activeMatches = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'pending')
          .get();

      return {
        'queueSize': queueSnapshot.size,
        'activePendingMatches': activeMatches.size,
        'averageWaitTime': 15, // Placeholder - should be calculated from server
      };
    } catch (e) {
      print('Error fetching matchmaking stats: $e');
      return {'queueSize': 0, 'activePendingMatches': 0, 'averageWaitTime': 0};
    }
  }
}

// Riverpod Providers
final matchmakingServiceProvider = Provider((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return MatchmakingService(firestore, auth);
});

// Matchmaking status notifier
class MatchmakingStatusNotifier extends StateNotifier<MatchmakingStatus> {
  MatchmakingStatusNotifier() : super(MatchmakingStatus.idle);

  void setStatus(MatchmakingStatus status) {
    state = status;
  }

  void reset() {
    state = MatchmakingStatus.idle;
  }
}

final matchmakingStatusProvider =
    StateNotifierProvider<MatchmakingStatusNotifier, MatchmakingStatus>(
  (ref) => MatchmakingStatusNotifier(),
);

// Current queue entry ID provider
final currentQueueEntryProvider = StateProvider<String?>((ref) => null);

// Matchmaking stats provider
final matchmakingStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final matchmakingService = ref.watch(matchmakingServiceProvider);
  return matchmakingService.getMatchmakingStats();
});

// Pending match provider
final pendingMatchProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final matchmakingService = ref.watch(matchmakingServiceProvider);
  return matchmakingService.getPendingMatch();
});

// Watch pending matches in real-time
final pendingMatchStreamProvider =
    StreamProvider<Map<String, dynamic>?>((ref) async* {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    yield null;
    return;
  }

  try {
    await for (final snapshot in firestore
        .collection('matches')
        .where('status', isEqualTo: 'pending')
        .where(
          Filter.or(
            Filter('whiteId', isEqualTo: user.uid),
            Filter('blackId', isEqualTo: user.uid),
          ),
        )
        .limit(1)
        .snapshots()) {
      if (snapshot.docs.isNotEmpty) {
        yield snapshot.docs.first.data();
      } else {
        yield null;
      }
    }
  } catch (e) {
    print('Error watching pending matches: $e');
    yield null;
  }
});
