import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // We append a dummy domain to use Firebase Email/Password Auth securely.
  // The system remains strictly private without needing custom tokens setup.
  String _generateEmail(String uniqueId) => "$uniqueId@mygfchat.internal";

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUpOrLogin(String uniqueId, String password) async {
    final email = _generateEmail(uniqueId);
    try {
      // Attempt login first
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _secureSaveId(uniqueId);
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          // If not found, attempt creation
          final cred = await _auth.createUserWithEmailAndPassword(
            email: email, 
            password: password
          );
          await _secureSaveId(uniqueId);
          return cred;
        } catch (createError) {
          throw Exception("Login Failed: \$createError");
        }
      }
      throw Exception("Auth Error: \${e.message}");
    }
  }

  Future<void> _secureSaveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_uid', id);
  }

  Future<String?> getSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_uid');
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_uid');
    await _auth.signOut();
  }
}
