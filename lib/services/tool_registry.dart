// lib/services/tool_registry.dart
import 'base_tool_service.dart';
import 'email/email_tool_service.dart'; // Import the refactored email service
import '../models/llm_models.dart';

class ToolRegistry {
  final Map<String, BaseToolService> _services = {};
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    // Register all available services
    registerService(EmailToolService());
    // Add other services here as they're created

    _isInitialized = true;
  }

  void registerService(BaseToolService service) {
    _services[service.serviceId] = service;
  }

  BaseToolService? getServiceForTool(String toolName) {
    for (final service in _services.values) {
      if (service.canHandle(toolName)) {
        return service;
      }
    }
    return null;
  }

  List<LLMTool> getAllTools() {
    return _services.values
        .expand((service) => service.availableTools)
        .toList();
  }

  List<LLMTool> getToolsByCategory(String category) {
    // For now, return all tools as we don't have categories implemented
    return getAllTools();
  }

  List<ToolSearchResult> searchTools(String query) {
    final results = <ToolSearchResult>[];
    final queryLower = query.toLowerCase();

    for (final service in _services.values) {
      for (final tool in service.availableTools) {
        if (tool.name.toLowerCase().contains(queryLower) ||
            tool.description.toLowerCase().contains(queryLower)) {
          results.add(ToolSearchResult(
            tool: tool,
            serviceId: service.serviceId,
            serviceName: service.serviceName,
          ));
        }
      }
    }

    return results;
  }

  List<ServiceInfo> getServicesInfo() {
    return _services.values
        .map((service) => ServiceInfo(
              serviceId: service.serviceId,
              serviceName: service.serviceName,
              toolCount: service.availableTools.length,
              isEnabled: true, // All services are enabled by default
            ))
        .toList();
  }

  Map<String, dynamic> getStats() {
    return {
      'service_count': _services.length,
      'tool_count': getAllTools().length,
      'is_initialized': _isInitialized,
    };
  }

  bool validateRegistry() {
    return _isInitialized && _services.isNotEmpty;
  }
}
