// lib/services/email_lookup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailLookupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'email-lookup';

  /// Looks up an email address by name in the Firestore email-lookup collection
  /// Returns the email address if found, null if not found
  Future<String?> lookupEmailByName(String name) async {
    try {
      // Normalize the name for consistent lookup (trim and lowercase)
      final normalizedName = name.trim().toLowerCase();

      // Query the email-lookup collection for the name
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return data['email_address'] as String?;
      }

      return null; // No email found for this name
    } catch (e) {
      print('Error looking up email for name "$name": $e');
      return null;
    }
  }

  /// Alternative method if you want to search by document ID instead of field query
  /// Assumes the document ID is the name
  Future<String?> lookupEmailByNameAsDocId(String name) async {
    try {
      // Normalize the name for consistent lookup
      final normalizedName = name.trim().toLowerCase();

      // Get document by ID
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(normalizedName)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['email'] as String?;
      }

      return null; // No email found for this name
    } catch (e) {
      print('Error looking up email for name "$name": $e');
      return null;
    }
  }
}
