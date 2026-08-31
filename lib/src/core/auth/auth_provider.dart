/// Supplies access tokens from the host application's auth session.
///
/// The SDK never receives or stores a refresh token. When [forceRefresh] is
/// true, the host must perform its own refresh flow and return the new token.
abstract interface class AuthProvider {
  Future<String?> getAccessToken({bool forceRefresh = false});
}

final class UserIdentity {
  const UserIdentity({required this.userId, required this.email});

  final String userId;
  final String email;
}
