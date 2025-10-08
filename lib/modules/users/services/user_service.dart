import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Create a new user with email and password
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final role = _detectRole(email);

    if (role == 'unknown') {
      throw Exception("Invalid email format for role detection.");
    }

    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user!.uid;

    final userData = {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.now(),
    };

    if (role == 'student') {
      userData['semester'] = '7';
    }

    await _usersRef.doc(uid).set(userData);

    return role;
  }

  /// Stream all users of a specific role
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _usersRef.where('role', isEqualTo: role).snapshots();
  }

  /// Simple role detection from email
  String _detectRole(String email) {
    if (email.startsWith('sample.faculty.')) return 'faculty';
    if (email.startsWith('sample.student.')) return 'student';
    return 'unknown';
  }
}
