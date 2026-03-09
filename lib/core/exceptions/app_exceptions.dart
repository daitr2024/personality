// Custom exception classes for structured error handling.
// Replaces generic `catch (e)` with specific exception types.

/// Thrown when an API key is not configured.
class ApiKeyNotSetException implements Exception {
  @override
  String toString() => 'API anahtarı ayarlanmamış';
}

/// Thrown when the API key is invalid or unauthorized.
class ApiKeyInvalidException implements Exception {
  final int statusCode;
  const ApiKeyInvalidException(this.statusCode);

  @override
  String toString() => 'API anahtarı geçersiz veya yetkisiz ($statusCode)';
}

/// Thrown when API quota/rate limit is exceeded.
class ApiQuotaExceededException implements Exception {
  @override
  String toString() => 'API kota limiti aşıldı. Lütfen biraz bekleyin.';
}

/// Thrown when the API returns an unexpected error.
class ApiErrorException implements Exception {
  final int statusCode;
  final String? details;
  const ApiErrorException(this.statusCode, [this.details]);

  @override
  String toString() =>
      'API hatası ($statusCode)${details != null ? ': $details' : ''}';
}

/// Thrown when audio transcription returns empty result.
class TranscriptionEmptyException implements Exception {
  @override
  String toString() => 'Ses anlaşılamadı. Lütfen tekrar deneyin.';
}

/// Thrown when a required file is not found.
class FileNotFoundException implements Exception {
  final String path;
  const FileNotFoundException(this.path);

  @override
  String toString() => 'Dosya bulunamadı: $path';
}

/// Thrown when network connection fails.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'Bağlantı hatası: $message';
}
