/// Stub for web storage when dart:html is not available (e.g., in VM tests)
///
/// This file provides no-op implementations for web-specific functionality
/// when running in non-web environments.

class Storage {
  Iterable<String> get keys => [];
  int get length => 0;
  String? operator [](String key) => null;
  void operator []=(String key, String value) {}
}

class Window {
  Storage get localStorage => Storage();
}

final window = Window();
