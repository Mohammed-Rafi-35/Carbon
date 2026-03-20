import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity state
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Connectivity state notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final Connectivity _connectivity;
  
  ConnectivityNotifier(this._connectivity) : super(ConnectivityStatus.unknown) {
    _init();
  }

  void _init() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectivityStatus(results);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      state = ConnectivityStatus.unknown;
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      state = ConnectivityStatus.offline;
      return;
    }

    // Check if any connection is available
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    state = hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }
}

/// Connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier(Connectivity());
});
