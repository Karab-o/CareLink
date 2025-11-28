import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_alert.dart';

/// Service for handling location-related functionality
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Get current location with high accuracy for emergency situations
  Future<AlertLocation?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with high accuracy
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return AlertLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get location with address (reverse geocoding would be implemented here)
  Future<AlertLocation?> getCurrentLocationWithAddress() async {
    final location = await getCurrentLocation();
    if (location == null) return null;

    // TODO: Implement reverse geocoding to get address
    // This would typically use a geocoding service like Google Maps API
    final String? address = await _reverseGeocode(
      location.latitude,
      location.longitude,
    );

    return AlertLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      address: address,
      accuracy: location.accuracy,
      timestamp: location.timestamp,
    );
  }

  /// Start continuous location tracking (for emergency situations)
  Stream<Position> trackLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Open location in maps app
  Future<void> openInMaps(double latitude, double longitude) async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      print('Error opening maps: $e');
    }
  }

  /// Format coordinates for sharing
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Generate Google Maps URL for sharing
  String generateMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Private method for reverse geocoding (placeholder)
  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    // TODO: Implement actual reverse geocoding
    // This would typically use a service like Google Geocoding API
    // For now, return a placeholder
    return 'Location: ${formatCoordinates(latitude, longitude)}';
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  /// Open app settings for location permission
  Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}