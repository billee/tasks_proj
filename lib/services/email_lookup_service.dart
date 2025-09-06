// lib/services/email_lookup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/email_validator.dart';

// EmailLookup model for structured data storage
class EmailLookup {
  final String name;
  final String emailAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailLookup({
    required this.name,
    required this.emailAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email_address': emailAddress,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory EmailLookup.fromMap(Map<String, dynamic> map) {
    return EmailLookup(
      name: map['name'] ?? '',
      emailAddress: map['email_address'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class EmailLookupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'email-lookup';

  /// Saves an email contact to the Firestore email-lookup collection
  /// Returns true if saved successfully, false if failed
  Future<bool> saveEmailContact(String name, String emailAddress) async {
    try {
      // Input validation
      if (name.trim().isEmpty) {
        print('Error: Name cannot be empty');
        return false;
      }

      if (emailAddress.trim().isEmpty ||
          !EmailValidator.isValidEmail(emailAddress)) {
        print('Error: Invalid email address format');
        return false;
      }

      print(
          'Attempting to save contact: name=$name, emailAddress=$emailAddress');

      // Normalize the name for consistent storage and lookup
      final normalizedName = name.trim().toLowerCase();
      final normalizedEmail = emailAddress.trim().toLowerCase();

      // Create EmailLookup instance with current timestamp
      final emailLookup = EmailLookup(
        name: normalizedName,
        emailAddress: normalizedEmail,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore using normalized name as document ID
      await _firestore
          .collection(_collectionName)
          .doc(normalizedName)
          .set(emailLookup.toMap(), SetOptions(merge: true));

      print('Firestore save result: success');
      return true;
    } catch (e) {
      print('Firestore save result: failure - Error saving email contact: $e');
      return false;
    }
  }

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
        return data?['email_address'] as String?;
      }

      return null; // No email found for this name
    } catch (e) {
      print('Error looking up email for name "$name": $e');
      return null;
    }
  }
}
