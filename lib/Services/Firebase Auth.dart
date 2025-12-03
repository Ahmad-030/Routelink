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

  // Add a getter to check if user data is loaded
  bool get isUserDataLoaded => _currentUser.value != null && _firebaseUser.value != null;

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
        final data = doc.data()!;
        _currentUser.value = UserModel.fromMap(data);

        // Debug print to verify role is loaded correctly
        print('✅ User data loaded successfully:');
        print('   Name: ${_currentUser.value?.name}');
        print('   Email: ${_currentUser.value?.email}');
        print('   Role (enum): ${_currentUser.value?.role}');
        print('   Role (string): ${data['role']}');
        print('   Is Driver: ${_currentUser.value?.role == UserRole.driver}');
        print('   Is Passenger: ${_currentUser.value?.role == UserRole.passenger}');
      } else {
        print('❌ User document does not exist in Firestore');
        _currentUser.value = null;
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      _currentUser.value = null;

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

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        // Update display name
        await credential.user!.updateDisplayName(name);

        print('✅ User created successfully:');
        print('   UID: ${credential.user!.uid}');
        print('   Role: $role');

        // Manually set the current user to avoid race condition
        _currentUser.value = userModel;

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Sign up error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  /// Sign in existing user - IMPROVED VERSION
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
        print('✅ Sign in successful: ${credential.user!.uid}');

        // Force load user data immediately to avoid race conditions
        await _loadUserData(credential.user!.uid);

        // Wait a bit to ensure data is fully loaded
        int attempts = 0;
        while (_currentUser.value == null && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        if (_currentUser.value != null) {
          print('✅ User data loaded, role: ${_currentUser.value!.role}');
          return true;
        } else {
          print('❌ Failed to load user data after sign in');
          return false;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
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
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
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
      print('❌ Reset password error: $e');
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
      print('❌ Update profile error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }
}