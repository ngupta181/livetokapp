import 'package:bubbly/utils/session_manager.dart';

class LocationUtils {
  static final SessionManager _sessionManager = SessionManager();
  
  /// Get user's country from session
  static String? getUserCountry() {
    final user = _sessionManager.getUser();
    return user?.data?.userCountry;
  }
  
  /// Get user's state from session
  static String? getUserState() {
    final user = _sessionManager.getUser();
    return user?.data?.userState;
  }
  
  /// Get user's city from session
  static String? getUserCity() {
    final user = _sessionManager.getUser();
    return user?.data?.userCity;
  }
  
  /// Get user's timezone from session
  static String? getUserTimezone() {
    final user = _sessionManager.getUser();
    // Use the existing timezone field from the database
    return user?.data?.timezone;
  }
  
  /// Get user's IP address from session
  static String? getUserIp() {
    final user = _sessionManager.getUser();
    return user?.data?.userIp;
  }
  
  /// Get full location string (City, State, Country)
  static String getFullLocationString() {
    final city = getUserCity();
    final state = getUserState();
    final country = getUserCountry();
    
    List<String> locationParts = [];
    
    if (city != null && city.isNotEmpty && city != 'Unknown') {
      locationParts.add(city);
    }
    
    if (state != null && state.isNotEmpty && state != 'Unknown') {
      locationParts.add(state);
    }
    
    if (country != null && country.isNotEmpty && country != 'Unknown') {
      locationParts.add(country);
    }
    
    return locationParts.isEmpty ? 'Location not available' : locationParts.join(', ');
  }
  
  /// Get country and state only
  static String getCountryStateString() {
    final state = getUserState();
    final country = getUserCountry();
    
    List<String> locationParts = [];
    
    if (state != null && state.isNotEmpty && state != 'Unknown') {
      locationParts.add(state);
    }
    
    if (country != null && country.isNotEmpty && country != 'Unknown') {
      locationParts.add(country);
    }
    
    return locationParts.isEmpty ? 'Location not available' : locationParts.join(', ');
  }
  
  /// Check if location data is available
  static bool hasLocationData() {
    final country = getUserCountry();
    return country != null && country.isNotEmpty && country != 'Unknown';
  }
  
  /// Get location data as a map
  static Map<String, String?> getLocationData() {
    return {
      'country': getUserCountry(),
      'state': getUserState(),
      'city': getUserCity(),
      'timezone': getUserTimezone(),
      'ip': getUserIp(),
    };
  }
} 