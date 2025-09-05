// lib/models/email_lookup_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailLookup {
  final String name;
  final String emailAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EmailLookup({
    required this.name,
    required this.emailAddress,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document
  factory EmailLookup.fromMap(Map<String, dynamic> data) {
    return EmailLookup(
      name: data['name'] as String,
      emailAddress: data['email_address'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name.toLowerCase().trim(),
      'email_address': emailAddress.toLowerCase().trim(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  EmailLookup copyWith({
    String? name,
    String? emailAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailLookup(
      name: name ?? this.name,
      emailAddress: emailAddress ?? this.emailAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
