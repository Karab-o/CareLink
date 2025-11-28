import 'package:flutter/foundation.dart';

/// Provider for managing navigation state and bottom navigation
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isEmergencyMode = false;

  // Getters
  int get currentIndex => _currentIndex;
  bool get isEmergencyMode => _isEmergencyMode;

  /// Set the current navigation index
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Navigate to home screen
  void navigateToHome() {
    setCurrentIndex(0);
  }

  /// Navigate to contacts screen
  void navigateToContacts() {
    setCurrentIndex(1);
  }

  /// Navigate to alerts history screen
  void navigateToAlerts() {
    setCurrentIndex(2);
  }

  /// Navigate to settings screen
  void navigateToSettings() {
    setCurrentIndex(3);
  }

  /// Enter emergency mode (changes UI behavior)
  void enterEmergencyMode() {
    if (!_isEmergencyMode) {
      _isEmergencyMode = true;
      notifyListeners();
    }
  }

  /// Exit emergency mode
  void exitEmergencyMode() {
    if (_isEmergencyMode) {
      _isEmergencyMode = false;
      notifyListeners();
    }
  }

  /// Toggle emergency mode
  void toggleEmergencyMode() {
    _isEmergencyMode = !_isEmergencyMode;
    notifyListeners();
  }

  /// Reset navigation state
  void reset() {
    _currentIndex = 0;
    _isEmergencyMode = false;
    notifyListeners();
  }
}