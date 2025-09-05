// lib/services/email/email_lookup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/email_lookup_model.dart';

class EmailLookupService {
  static const String _collectionName = 'email-lookup';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if a name has an associated email address
  Future<String?> getEmailByName(String name) async {
    try {
      final normalizedName = name.toLowerCase().trim();
      print(
          '===============================Looking up email for name: $normalizedName');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final emailLookup =
            EmailLookup.fromMap(querySnapshot.docs.first.data());
        print(
            '==========================Found email for $name: ${emailLookup.emailAddress}');
        return emailLookup.emailAddress;
      }

      print('=======================No email found for name: $name');
      return null;
    } catch (e) {
      print(
          '================================Error looking up email for name $name: $e');
      return null;
    }
  }

  // Save a new name-email mapping
  Future<bool> saveEmailLookup(String name, String emailAddress) async {
    try {
      print('====== saveEmailLookup called ======');
      final normalizedName = name.toLowerCase().trim();
      final normalizedEmail = emailAddress.toLowerCase().trim();

      print('Saving email lookup: $normalizedName -> $normalizedEmail');
      print('Firebase instance: $_firestore');
      print('Collection name: $_collectionName');

      // Check if the name already exists
      print('Checking if name already exists...');
      final existingQuery = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      print(
          'Existing query result: ${existingQuery.docs.length} documents found');

      final emailLookup = EmailLookup(
        name: normalizedName,
        emailAddress: normalizedEmail,
        createdAt: DateTime.now(),
        updatedAt: existingQuery.docs.isNotEmpty ? DateTime.now() : null,
      );

      print('EmailLookup object created: ${emailLookup.toMap()}');

      if (existingQuery.docs.isNotEmpty) {
        // Update existing record
        print('Updating existing record...');
        await _firestore
            .collection(_collectionName)
            .doc(existingQuery.docs.first.id)
            .update(emailLookup.toMap());
        print('Updated existing email lookup for $name');
      } else {
        // Create new record
        print('Creating new record...');
        final docRef = await _firestore
            .collection(_collectionName)
            .add(emailLookup.toMap());
        print('Created new email lookup for $name with doc ID: ${docRef.id}');
      }

      print('Save operation completed successfully');
      return true;
    } catch (e) {
      print('ERROR saving email lookup for $name: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Get all email lookups (for admin/debugging purposes)
  Future<List<EmailLookup>> getAllEmailLookups() async {
    try {
      final querySnapshot =
          await _firestore.collection(_collectionName).orderBy('name').get();

      return querySnapshot.docs
          .map((doc) => EmailLookup.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all email lookups: $e');
      return [];
    }
  }

  // Delete an email lookup
  Future<bool> deleteEmailLookup(String name) async {
    try {
      final normalizedName = name.toLowerCase().trim();

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore
            .collection(_collectionName)
            .doc(querySnapshot.docs.first.id)
            .delete();
        print('Deleted email lookup for $name');
        return true;
      }

      print('No email lookup found to delete for $name');
      return false;
    } catch (e) {
      print('Error deleting email lookup for $name: $e');
      return false;
    }
  }

  // Check if an email address is valid format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email.trim());
  }

  // Extract potential name from user input (for cases like "email to Tony")
  String? extractNameFromInput(String input) {
    // Common patterns for extracting names from user input
    final patterns = [
      RegExp(r'email\s+to\s+(\w+)', caseSensitive: false),
      RegExp(r'send\s+email\s+to\s+(\w+)', caseSensitive: false),
      RegExp(r'write\s+to\s+(\w+)', caseSensitive: false),
      RegExp(r'contact\s+(\w+)', caseSensitive: false),
      RegExp(r'message\s+(\w+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.toLowerCase().trim();
      }
    }

    return null;
  }
}
