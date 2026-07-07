// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseConfig {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;

  static Future<void> initialize() async {
    try {
      _app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'YOUR_API_KEY',
          appId: 'YOUR_APP_ID',
          messagingSenderId: 'YOUR_SENDER_ID',
          projectId: 'YOUR_PROJECT_ID',
          authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
          storageBucket: 'YOUR_PROJECT_ID.appspot.com',
        ),
      );
      
      _auth = FirebaseAuth.instanceFor(app: _app!);
      _firestore = FirebaseFirestore.instanceFor(app: _app!);
      _storage = FirebaseStorage.instanceFor(app: _app!);
      
      // Enable offline persistence
      await _firestore!.enablePersistence();
      
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return _auth!;
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return _firestore!;
  }

  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return _storage!;
  }

  static bool get isInitialized => _app != null;

  // ============================================================
  // FIREBASE AUTH HELPER
  // ============================================================

  static Future<String?> getCurrentUserId() async {
    final user = auth.currentUser;
    return user?.uid;
  }

  static Future<String?> getCurrentUserEmail() async {
    final user = auth.currentUser;
    return user?.email;
  }

  static Future<bool> isEmailVerified() async {
    final user = auth.currentUser;
    return user?.emailVerified ?? false;
  }

  static Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await user.sendEmailVerification();
  }

  static Future<void> reloadUser() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await user.reload();
  }

  // ============================================================
  // FIRESTORE HELPERS
  // ============================================================

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> document(String path) {
    return firestore.doc(path);
  }

  static WriteBatch batch() {
    return firestore.batch();
  }

  static Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) {
    return firestore.runTransaction(transaction);
  }

  // ============================================================
  // STORAGE HELPERS
  // ============================================================

  static Reference ref(String path) {
    return storage.ref(path);
  }

  static Future<String> uploadFile(String path, Uint8List data) async {
    final ref = storage.ref(path);
    await ref.putData(data);
    return await ref.getDownloadURL();
  }

  static Future<void> deleteFile(String path) async {
    final ref = storage.ref(path);
    await ref.delete();
  }

  static Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = storage.ref(path);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
