import 'dart:convert';
import 'dart:js_util' show jsify;
import 'dart:typed_data';

import 'package:js_bindings/js_bindings.dart' as interop;

import './utils.dart';
import 'blob.dart';
import 'body.dart';
import 'form_data.dart';
import 'headers.dart';
import 'readable_stream.dart';

class Response implements Body {
  final interop.Response _delegate;

  Response._(this._delegate);

  Response(
    Object? body, {
    int? status,
    String? statusText,
    Headers? headers,
  }) : _delegate = interop.Response(
          convertBody(body),
          interop.ResponseInit(
            status: status ?? 200,
            statusText: statusText ?? 'OK',
            headers: headers?.delegate ?? interop.Headers(),
          ),
        );

  factory Response.error() {
    return Response._(interop.Response.error());
  }

  factory Response.redirect(Uri url, [int? status = 302]) {
    return Response._(
      interop.Response.redirect(url.toString(), status),
    );
  }

  factory Response.json(
    Object? data, {
    int? status,
    String? statusText,
    Headers? headers,
  }) {
    return Response._(
      interop.Response.json(
        data != null ? jsify(data) : null,
        interop.ResponseInit(
          status: status,
          statusText: statusText,
          headers: headers?.delegate,
        ),
      ),
    );
  }

  interop.ResponseType get type => _delegate.type;
  Uri get url => Uri.parse(_delegate.url);
  bool get redirected => _delegate.redirected;
  int get status => _delegate.status;
  bool get ok => _delegate.ok;
  String get statusText => _delegate.statusText;
  Headers get headers => headersFromJsObject(_delegate.headers);
  Response clone() => Response._(_delegate.clone());

  @override
  Future<ByteBuffer> arrayBuffer() => _delegate.arrayBuffer();

  @override
  Future<Object> blob() async => blobFromJsObject(await _delegate.blob());

  @override
  ReadableStream? get body {
    final body = _delegate.body;
    return body == null ? null : readableStreamFromJsObject(body);
  }

  @override
  bool get bodyUsed => _delegate.bodyUsed;

  @override
  Future<FormData> formData() async =>
      formDataFromJsObject(await _delegate.formData());

  @override
  Future<Object?> json() async {
    // We don't call `_delegate.json()` directly, as it decodes the JSON
    // from JS `JSON.parse`, which does not translate all values back to Dart
    // correctly (e.g. a List is not translated to a JsArray).
    final text = await _delegate.text();
    return jsonDecode(text);
  }

  @override
  Future<String> text() => _delegate.text();
}

extension ResponseExtension on Response {
  interop.Response get delegate => _delegate;
}

Response responseFromJsObject(interop.Response delegate) {
  return Response._(delegate);
}
