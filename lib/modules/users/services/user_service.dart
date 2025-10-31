import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  /// Manages user creation and lookup in Firestore and Firebase Auth.
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Create a new Firebase Auth user and store a users document. Returns detected role.
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

    // Default semester assignment for students (can be changed later).
    if (role == 'student') {
      userData['semester'] = '7';
    }

    await _usersRef.doc(uid).set(userData);
    return role;
  }

  /// Stream users filtered by `role` for admin UIs.
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _usersRef.where('role', isEqualTo: role).snapshots();
  }

  /// Lightweight role detection based on email prefix used in demo/test data.
  String _detectRole(String email) {
    if (email.startsWith('sample.faculty.')) return 'faculty';
    if (email.startsWith('sample.student.')) return 'student';
    return 'unknown';
  }
}
