import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory ChallengeService() {
    return _instance;
  }

  ChallengeService._internal();

  Future<Challenge> createChallenge({
    required String creatorId,
    required String type,
    required int targetCount,
    required Duration duration,
    required String title,
    required String description,
  }) async {
    try {
      final challengeId = _firestore.collection('challenges').doc().id;
      final endsAt = DateTime.now().add(duration);
      final shareCode = _generateShareCode();

      final challenge = Challenge(
        challengeId: challengeId,
        creatorId: creatorId,
        type: type,
        title: title,
        description: description,
        targetCount: targetCount,
        duration: duration,
        createdAt: DateTime.now(),
        endsAt: endsAt,
        shareCode: shareCode,
        participantIds: [creatorId],
        status: ChallengeStatus.active,
      );

      await _firestore.collection('challenges').doc('active').collection('list').doc(challengeId).set({
        'challengeId': challengeId,
        'creatorId': creatorId,
        'type': type,
        'title': title,
        'description': description,
        'targetCount': targetCount,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'endsAt': Timestamp.fromDate(endsAt),
        'shareCode': shareCode,
        'participantIds': [creatorId],
        'status': 'active',
      });

      return challenge;
    } catch (e) {
      print('Error creating challenge: $e');
      rethrow;
    }
  }

  Future<void> joinChallenge(String userId, String challengeCode) async {
    try {
      final challengeDoc = await _firestore
          .collection('challenges')
          .doc('active')
          .collection('list')
          .where('shareCode', isEqualTo: challengeCode)
          .limit(1)
          .get();

      if (challengeDoc.docs.isNotEmpty) {
        final challengeId = challengeDoc.docs.first.id;

        await _firestore
            .collection('challenges')
            .doc('active')
            .collection('list')
            .doc(challengeId)
            .update({
          'participantIds': FieldValue.arrayUnion([userId]),
        });

        await _firestore
            .collection('challenges')
            .doc('progress')
            .collection(challengeId)
            .doc(userId)
            .set({
          'userId': userId,
          'challengeId': challengeId,
          'progress': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error joining challenge: $e');
    }
  }

  Future<void> updateChallengeProgress(
      String userId, String challengeId) async {
    try {
      final progressDoc = await _firestore
          .collection('challenges')
          .doc('progress')
          .collection(challengeId)
          .doc(userId)
          .get();

      final currentProgress = (progressDoc['progress'] ?? 0) + 1;

      await _firestore
          .collection('challenges')
          .doc('progress')
          .collection(challengeId)
          .doc(userId)
          .update({'progress': currentProgress});
    } catch (e) {
      print('Error updating challenge progress: $e');
    }
  }

  Future<List<ChallengeLeaderboard>> getChallengeLeaderboard(
      String challengeId) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .doc('progress')
          .collection(challengeId)
          .orderBy('progress', descending: true)
          .get();

      return snapshot.docs
          .asMap()
          .entries
          .map((e) {
            final data = e.value.data();
            return ChallengeLeaderboard(
              rank: e.key + 1,
              userId: data['userId'] ?? '',
              username: data['username'] ?? 'Unknown',
              score: data['progress'] ?? 0,
              progress: data['progress'] ?? 0,
              completionPercentage: 0.0,
            );
          })
          .toList();
    } catch (e) {
      print('Error fetching challenge leaderboard: $e');
      return [];
    }
  }

  Future<void> distributeChallengeRewards(String challengeId) async {
    try {
      final leaderboard = await getChallengeLeaderboard(challengeId);

      for (final entry in leaderboard.take(3)) {
        final points = [100, 50, 25][leaderboard.indexOf(entry)];
        await _firestore
            .collection('user_rewards')
            .doc(entry.userId)
            .update({
          'totalPoints': FieldValue.increment(points),
        });
      }

      await _firestore
          .collection('challenges')
          .doc('active')
          .collection('list')
          .doc(challengeId)
          .update({'status': 'completed'});
    } catch (e) {
      print('Error distributing challenge rewards: $e');
    }
  }

  Future<List<Challenge>> getUserActiveChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .doc('active')
          .collection('list')
          .where('participantIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => Challenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user active challenges: $e');
      return [];
    }
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    for (int i = 0; i < 6; i++) {
      result += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return result;
  }
}

class Challenge {
  final String challengeId;
  final String creatorId;
  final String type;
  final String title;
  final String description;
  final int targetCount;
  final Duration duration;
  final DateTime createdAt;
  final DateTime endsAt;
  final String shareCode;
  final List<String> participantIds;
  final ChallengeStatus status;

  Challenge({
    required this.challengeId,
    required this.creatorId,
    required this.type,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.duration,
    required this.createdAt,
    required this.endsAt,
    required this.shareCode,
    required this.participantIds,
    required this.status,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      challengeId: json['challengeId'] ?? '',
      creatorId: json['creatorId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetCount: json['targetCount'] ?? 0,
      duration: Duration(days: json['duration'] ?? 7),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? (json['endsAt'] as Timestamp).toDate()
          : DateTime.now().add(Duration(days: 7)),
      shareCode: json['shareCode'] ?? '',
      participantIds: List<String>.from(json['participantIds'] ?? []),
      status: _parseStatus(json['status']),
    );
  }

  static ChallengeStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return ChallengeStatus.completed;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.active;
    }
  }
}

class ChallengeLeaderboard {
  final int rank;
  final String userId;
  final String username;
  final int score;
  final int progress;
  final double completionPercentage;

  ChallengeLeaderboard({
    required this.rank,
    required this.userId,
    required this.username,
    required this.score,
    required this.progress,
    required this.completionPercentage,
  });
}

enum ChallengeStatus { active, completed, cancelled }
