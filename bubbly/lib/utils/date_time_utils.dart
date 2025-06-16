import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format a DateTime to a user-friendly string
  static String formatDateTime(DateTime dateTime) {
    try {
      // Print the actual dates for debugging
      print('DATE TO FORMAT: $dateTime');
      print('CURRENT TIME: ${DateTime.now()}');
      
      final DateTime now = DateTime.now();
      final difference = now.difference(dateTime);
      
      // Handle the case where dateTime is in the future or has timezone issues
      if (difference.isNegative) {
        // For timestamps that appear to be in the future but might be timezone issues
        // Calculate the absolute difference for a more reasonable display
        final absDifference = difference.abs();
        
        if (absDifference.inHours < 1) {
          return 'Just now';
        } else if (absDifference.inHours < 24) {
          // If within a day, show as recent
          return 'Recently';
        } else {
          // If more than a day in the future, just show the formatted date
          return DateFormat('MMM d, h:mm a').format(dateTime);
        }
      }
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          } else {
            return '${difference.inMinutes} minutes ago';
          }
        } else {
          return '${difference.inHours} hours ago';
        }
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      // Fallback for any parsing or formatting errors
      print('Error formatting date: $e');
      return 'Recently'; // Safe fallback
    }
  }
  
  /// Format a DateTime to a short format (e.g., Aug 12)
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }
  
  /// Format a DateTime to show only the time (e.g., 3:45 PM)
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
