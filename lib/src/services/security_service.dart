import 'package:cloud_firestore/cloud_firestore.dart';

// Phase R: セキュリティ & コンプライアンス
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory SecurityService() => _instance;
  SecurityService._internal();

  Future<void> enableTwoFactorAuth(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      '2faEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordDataRequest(String userId, String requestType) async {
    await _firestore.collection('compliance').doc('data_requests').collection('all').add({
      'userId': userId,
      'requestType': requestType,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> logSecurityEvent(String userId, String eventType, String details) async {
    await _firestore.collection('security_audit').add({
      'userId': userId,
      'eventType': eventType,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserData(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    await _firestore.collection('rankings').doc('global').collection('players').doc(userId).delete();
  }
}
