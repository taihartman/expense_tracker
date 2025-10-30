/// Data Transfer Object representing the response from /version.json endpoint
class VersionResponse {
  /// The semantic version string in format "major.minor.patch+build"
  final String version;

  VersionResponse({required this.version});

  /// Creates a VersionResponse from JSON data
  ///
  /// Throws [TypeError] if the version field is missing
  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      version: json['version'] as String,
    );
  }

  /// Converts this VersionResponse to JSON
  Map<String, dynamic> toJson() => {
        'version': version,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionResponse && other.version == version;
  }

  @override
  int get hashCode => version.hashCode;

  @override
  String toString() => 'VersionResponse(version: $version)';
}
