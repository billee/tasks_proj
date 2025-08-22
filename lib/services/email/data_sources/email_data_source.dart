// lib/services/email/data_sources/email_data_source.dart
import '../models/email_models.dart';

abstract class EmailDataSource {
  Future<List<EmailStatus>> getEmailHistory({int limit, String? statusFilter});
  Future<void> saveEmailStatus(EmailStatus status);
  Future<EmailStatus?> getEmailStatus(String emailId);
}
