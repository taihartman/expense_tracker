import 'package:pub_semver/pub_semver.dart';

/// Represents the transient state of update checking for debouncing purposes
class UpdateCheckState {
  /// Timestamp of the last successful version check
  final DateTime? lastCheckTime;

  /// Whether a version check is currently in progress
  final bool isCheckingNow;

  /// Whether an update is available (server version > local version)
  final bool updateAvailable;

  /// The server version if known
  final Version? serverVersion;

  const UpdateCheckState({
    this.lastCheckTime,
    this.isCheckingNow = false,
    this.updateAvailable = false,
    this.serverVersion,
  });

  /// Returns true if a new check should be debounced based on minimum interval
  ///
  /// Returns false if this is the first check or enough time has passed
  bool shouldDebounce(Duration minimumInterval) {
    if (lastCheckTime == null) return false;
    return DateTime.now().difference(lastCheckTime!) < minimumInterval;
  }

  /// Creates a copy of this state with updated values
  UpdateCheckState copyWith({
    DateTime? lastCheckTime,
    bool? isCheckingNow,
    bool? updateAvailable,
    Version? serverVersion,
  }) {
    return UpdateCheckState(
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      isCheckingNow: isCheckingNow ?? this.isCheckingNow,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateCheckState &&
        other.lastCheckTime == lastCheckTime &&
        other.isCheckingNow == isCheckingNow &&
        other.updateAvailable == updateAvailable &&
        other.serverVersion == serverVersion;
  }

  @override
  int get hashCode => Object.hash(
        lastCheckTime,
        isCheckingNow,
        updateAvailable,
        serverVersion,
      );

  @override
  String toString() {
    return 'UpdateCheckState('
        'lastCheckTime: $lastCheckTime, '
        'isCheckingNow: $isCheckingNow, '
        'updateAvailable: $updateAvailable, '
        'serverVersion: $serverVersion)';
  }
}
