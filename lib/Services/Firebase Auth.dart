import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../Models/user_model.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  User? get firebaseUser => _firebaseUser.value;
  UserModel? get currentUser => _currentUser.value;

  bool get isAuthenticated => _firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());

    // Listen to user changes and load user data
    ever(_firebaseUser, _handleAuthChanged);
  }

  /// Handle authentication state changes
  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      _currentUser.value = null;
      print('User logged out');
    } else {
      print('User logged in: ${user.uid}');
      await _loadUserData(user.uid);
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        _currentUser.value = UserModel.fromMap(doc.data()!);
        print('User data loaded: ${_currentUser.value?.name}, Role: ${_currentUser.value?.role}');
      } else {
        print('User document does not exist in Firestore');
        // User exists in Auth but not in Firestore - handle this edge case
        _currentUser.value = null;
      }
    } catch (e) {
      print('Error loading user data: $e');
      _currentUser.value = null;

      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to load user data. Please try logging in again.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          profileImage: '',
          rating: 0.0,
          totalRides: 0,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        // Update display name
        await credential.user!.updateDisplayName(name);

        print('User created successfully: ${credential.user!.uid}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('Sign up error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  /// Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('Sign in successful: ${credential.user!.uid}');
        // User data will be loaded automatically by _handleAuthChanged
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('Sign in error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser.value = null;
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      Get.snackbar(
        'Error',
        'Failed to sign out. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent. Check your inbox.',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('Reset password error: $e');
      Get.snackbar(
        'Error',
        'Failed to send reset email. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  /// Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = 'This email is already registered. Please sign in instead.';
        break;
      case 'invalid-email':
        message = 'Invalid email address. Please check and try again.';
        break;
      case 'operation-not-allowed':
        message = 'Operation not allowed. Please contact support.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please use a stronger password.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'user-not-found':
        message = 'No account found with this email. Please sign up first.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please check your email and password.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message ?? "Unknown error"}';
    }

    Get.snackbar(
      'Authentication Error',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      if (_currentUser.value == null) return false;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser.value!.uid)
            .update(updates);

        // Reload user data
        await _loadUserData(_currentUser.value!.uid);

        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }
}