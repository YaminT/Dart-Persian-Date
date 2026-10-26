import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'holiday_source.dart';

/// Query parameters that carry secrets and are hidden in exceptions.
const _secretParameters = {'key', 'api_key', 'apikey', 'token'};

/// [uri] with secret query parameters replaced by `REDACTED`.
Uri redactUri(Uri uri) {
  if (!uri.queryParameters.keys.any(_secretParameters.contains)) return uri;
  return uri.replace(queryParameters: {
    for (final entry in uri.queryParameters.entries)
      entry.key:
          _secretParameters.contains(entry.key) ? 'REDACTED' : entry.value,
  });
}

/// GETs [uri] and decodes the JSON body.
///
/// Every failure, including timeouts, network and TLS errors, non-200
/// responses, and invalid JSON, becomes a [HolidaySourceException] whose
/// URI has its secrets redacted.
Future<Object?> getJson(http.Client client, Uri uri, Duration timeout) async {
  final shown = redactUri(uri);
  final http.Response response;
  try {
    response = await client.get(uri).timeout(timeout);
  } on TimeoutException {
    throw HolidaySourceException('Request timed out', uri: shown);
  } on http.ClientException catch (error) {
    throw HolidaySourceException(error.message, uri: shown);
  } on Object catch (error, stack) {
    // TLS, socket, and other platform errors.
    Error.throwWithStackTrace(
      HolidaySourceException('$error', uri: shown),
      stack,
    );
  }
  if (response.statusCode != 200) {
    throw HolidaySourceException(
      'Unexpected response',
      uri: shown,
      statusCode: response.statusCode,
    );
  }
  try {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException catch (error) {
    throw HolidaySourceException('Invalid JSON: ${error.message}', uri: shown);
  }
}

/// Runs [read] on a decoded response and turns any shape mismatch into a
/// [HolidaySourceException].
T readResponse<T>(Uri uri, T Function() read) {
  try {
    return read();
  } on HolidaySourceException {
    rethrow;
  } on Object catch (error) {
    throw HolidaySourceException(
      'Unexpected response shape: $error',
      uri: redactUri(uri),
    );
  }
}
