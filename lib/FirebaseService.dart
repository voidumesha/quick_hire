import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register student
  Future<User?> registerStudent(
      String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _firestore
          .collection('students')
          .doc(userCredential.user!.uid)
          .set({
        'username': username,
        'email': email,
      });
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Register company
  Future<User?> registerCompany(
      String email, String password, String companyName) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _firestore
          .collection('companies')
          .doc(userCredential.user!.uid)
          .set({
        'companyName': companyName,
        'email': email,
      });
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }
}
