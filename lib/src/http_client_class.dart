import 'dart:developer';

import 'package:http/http.dart' as http;
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:stack_trace/stack_trace.dart';

class LoggingHttpClient extends http.BaseClient {
  final http.Client inner = http.Client();

  static Type get multipartFile => http.MultipartFile;

  // ### [packageName] It is the name of the project.
  // You can find it in the [yaml] file. In the first line, you will find the name
  // or you can use function [getName(ymalPath)] to get name automatcly
  final String packageName;

  // ### [isShowResponse] is optional variable to show response or not
  // Make this an false when building the [product] or don't pass it on
  bool showResponse;

  // Map to hold files with their names as keys
  Map<String, http.MultipartFile>? files;
  Map<String, String>? fields;

  LoggingHttpClient(
      {
      // required this.inner,
      required this.packageName,
      this.showResponse = true});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final response = await inner.send(request);

    // Read the response stream
    final bytes = await response.stream.toBytes();
    final body = utf8.decode(bytes);

    // Stop stopwatch
    stopwatch.stop();

    // Print response details
    if (showResponse) {
      log('''
******** HTTP Response ********
- Status Code: ${response.statusCode}
- Duration: ${stopwatch.elapsedMilliseconds}ms
- Response Body: $body

******** END Response *********
*******************************
''');
    }
    // Create a new response with the same body
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
    );
  }

// Global instance of the logging client
  // final LoggingHttpClient globalClient = LoggingHttpClient(inner: sl());

  void _printRequest(String method, Uri url, String frame, dynamic repose,
      {dynamic body, dynamic headers}) {
    List<String> frameList = frame.split(' ');
    if (showResponse) {
      log("""
******** HTTP Request ********
$method - $url
- Header: $headers
- Body: $body

- Location: ${frame.split("package:$packageName").last}
- File: ${frameList.first}
- Method: ${frameList.last}
- Line: ${frameList[1]}
- Response Body: ${repose is http.Response ? jsonDecode(repose.body) : repose};
******** END Request ********
*****************************
""");
    }
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final frame = Trace.current().frames[1];
    final response = await inner.get(url, headers: headers);
    _printRequest(
      'GET',
      url,
      frame.toString(),
      response,
      headers: headers,
    );
    return response;
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final frame = Trace.current().frames[1];

    final response =
        await inner.post(url, headers: headers, body: body, encoding: encoding);
    _printRequest(
      'POST',
      url,
      frame.toString(),
      response,
      headers: headers,
      body: body,
    );
    return response;
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final frame = Trace.current().frames[1];
    final response =
        await inner.put(url, headers: headers, body: body, encoding: encoding);
    _printRequest(
      'PUT',
      url,
      frame.toString(),
      response,
      headers: headers,
      body: body,
    );
    return response;
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final frame = Trace.current().frames[1];
    final response = await inner.delete(url,
        headers: headers, body: body, encoding: encoding);
    _printRequest('DELETE', url, frame.toString(), response,
        headers: headers, body: body);
    return response;
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    final frame = Trace.current().frames[1];
    final String response = await inner.read(url, headers: headers);
    _printRequest(
      'READ',
      url,
      frame.toString(),
      response,
      headers: headers,
    );
    return response;
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    final frame = Trace.current().frames[1];
    final response = await inner.head(url, headers: headers);
    _printRequest(
      'HEAD',
      url,
      frame.toString(),
      response,
      headers: headers,
    );
    return response;
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final frame = Trace.current().frames[1];
    final response = await inner.patch(url,
        headers: headers, body: body, encoding: encoding);
    _printRequest(
      'PATCH',
      url,
      frame.toString(),
      response,
      headers: headers,
      body: body,
    );
    return response;
  }

  Future<http.Response> multipartRequest(String methodType, Uri url,
      {Map<String, String>? headers}) async {
    final frame = Trace.current().frames[1];

    final request = http.MultipartRequest(methodType, url);

    // Add fields to the request if provided
    if (fields != null) {
      fields?.forEach((key, value) {
        request.fields[key] = value;
      });
    }

    // Add files from the internal `files` map
    if (files != null) {
      for (var entry in files!.entries) {
        request.files.add(http.MultipartFile(
          entry.key, // Use the key as the field name
          entry.value.finalize(), // Get the stream of the file
          entry.value.length, // Get the length of the file
          filename: entry.key, // Use the entry key as the filename
        ));
      }
    }

    // Add headers to the request if provided
    if (headers != null) {
      request.headers.addAll(headers);
    }

    final streamedResponse = await send(request);

    final bytes = await streamedResponse.stream.toBytes();
    final response = utf8.decode(bytes);

    _printRequest(
      'MULTIPARTREQUEST $methodType',
      url,
      frame.toString(),
      response,
      headers: headers,
      body: fields.toString(),
    );

    // Create and return a new response
    return http.Response(response, streamedResponse.statusCode,
        headers: streamedResponse.headers);
  }
}
