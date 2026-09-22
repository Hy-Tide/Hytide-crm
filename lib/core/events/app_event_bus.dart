// lib/core/events/app_event_bus.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_domain_events.dart';

/// Central application-wide event bus for decoupled state synchronization
class AppEventBus {
  final _controller = StreamController<AppDomainEvent>.broadcast();

  Stream<AppDomainEvent> get stream => _controller.stream;

  /// Subscribe to a specific subtype of [AppDomainEvent]
  Stream<T> on<T extends AppDomainEvent>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  /// Emit a new domain event to all active listeners
  void emit(AppDomainEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Global provider for the application event bus
final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
