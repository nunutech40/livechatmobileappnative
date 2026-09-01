import '../../core/auth/auth_provider.dart';

/// Coordinates concurrent token refreshes so one expired token creates one
/// host refresh operation, not one refresh operation per failed request.
final class TokenCoordinator {
  TokenCoordinator(this._authProvider);

  final AuthProvider _authProvider;
  Future<String?>? _refreshInFlight;

  Future<String?> refresh() {
    final running = _refreshInFlight;
    if (running != null) return running;

    late final Future<String?> refreshFuture;
    refreshFuture = _authProvider
        .getAccessToken(forceRefresh: true)
        .whenComplete(() {
          if (identical(_refreshInFlight, refreshFuture)) {
            _refreshInFlight = null;
          }
        });
    _refreshInFlight = refreshFuture;
    return refreshFuture;
  }

  void clear() => _refreshInFlight = null;
}
