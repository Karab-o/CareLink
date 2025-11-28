// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Getter to check if the current user's email is verified
  bool get isEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Optional: send verification email
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty || name.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Please fill in all required fields',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        final Map<String, dynamic> userData = {
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'trustedContacts': [],
          'emergencySettings': {
            'autoAlert': false,
            'shakeToAlert': true,
            'locationSharing': true,
          },
          'isActive': true,
          'profileComplete': false,
        };

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);

        // Save to local storage
        await _saveUserToLocal(user.uid, email, name, phone);

        if (kDebugMode) {
          print('✅ User created successfully: ${user.uid}');
        }

        return {
          'success': true,
          'message': 'Account created successfully',
          'user': user,
          'userData': userData,
        };
      }

      return {
        'success': false,
        'message': 'Failed to create account',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      }

      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Password should be at least 6 characters';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = e.message ?? 'Sign up failed. Please try again';
      }

      return {
        'success': false,
        'message': message,
        'errorCode': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during sign up: $e');
      }
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter email and password',
        };
      }

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Get user data from Firestore
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Update last login
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          // Save to local storage
          await _saveUserToLocal(
            user.uid,
            userData['email'] ?? email,
            userData['name'] ?? 'User',
            userData['phone'] ?? '',
          );

          if (kDebugMode) {
            print('✅ User signed in successfully: ${user.uid}');
          }

          return {
            'success': true,
            'message': 'Signed in successfully',
            'user': user,
            'userData': userData,
          };
        } else {
          if (kDebugMode) {
            print('⚠️ User document not found in Firestore');
          }
          return {
            'success': false,
            'message': 'User data not found. Please contact support.',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to sign in',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      }

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = e.message ?? 'Sign in failed. Please try again';
      }

      return {
        'success': false,
        'message': message,
        'errorCode': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during sign in: $e');
      }
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearLocalStorage();
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error signing out: $e');
      }
      rethrow;
    }
  }

  // Save user to local storage
  Future<void> _saveUserToLocal(
    String uid,
    String email,
    String name,
    String phone,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('email', email);
      await prefs.setString('name', name);
      await prefs.setString('phone', phone);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginTime', DateTime.now().toIso8601String());
      if (kDebugMode) {
        print('✅ User data saved to local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving to local storage: $e');
      }
    }
  }

  // Check if user is logged in locally
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isLoggedIn = prefs.getBool('isLoggedIn');
    return (isLoggedIn ?? false) && currentUser != null;
  }

  // Get user from local storage
  Future<Map<String, String?>> getUserFromLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('uid'),
      'email': prefs.getString('email'),
      'name': prefs.getString('name'),
      'phone': prefs.getString('phone'),
    };
  }

  // Clear local storage
  Future<void> _clearLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user data: $e');
      }
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user data: $e');
      }
      return false;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Please enter your email address',
        };
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

      // Clear local storage
      await _clearLocalStorage();

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return {
          'success': false,
          'message': 'Please sign in again to delete your account',
          'requiresReauth': true,
        };
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to delete account',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Reload user to get updated email verification status
  Future<bool> reloadUser() async {
    try {
      await currentUser?.reload();
      return currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }
}
