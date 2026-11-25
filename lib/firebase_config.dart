import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseConfig {
  /// If your Realtime Database is in asia-southeast1 or another non-US region,
  /// enter the URL here (e.g. "https://do-it-now-default-rtdb.asia-southeast1.firebasedatabase.app").
  /// Otherwise, leave null and Firebase will use the default URL from google-services.json.
  static const String? customDatabaseUrl = null;

  static FirebaseDatabase get database {
    if (customDatabaseUrl != null && customDatabaseUrl!.isNotEmpty) {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: customDatabaseUrl!,
      );
    }
    return FirebaseDatabase.instance;
  }
}
