// lib/services/email/data_sources/local_email_data_source.dart
import '../models/email_models.dart';
import 'email_data_source.dart';

class LocalEmailDataSource implements EmailDataSource {
  final List<EmailStatus> _emailHistory = [];

  @override
  Future<List<EmailStatus>> getEmailHistory(
      {int limit = 10, String? statusFilter}) async {
    var history = List<EmailStatus>.from(_emailHistory);

    if (statusFilter != null) {
      history = history.where((email) => email.status == statusFilter).toList();
    }

    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history.take(limit).toList();
  }

  @override
  Future<void> saveEmailStatus(EmailStatus status) async {
    _emailHistory.add(status);
  }

  @override
  Future<EmailStatus?> getEmailStatus(String emailId) async {
    try {
      return _emailHistory.lastWhere((status) => status.emailId == emailId);
    } catch (e) {
      return null;
    }
  }
}
