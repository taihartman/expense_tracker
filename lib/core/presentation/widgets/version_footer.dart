import 'package:flutter/material.dart';
import '../../services/version_service.dart';

/// A super small version display widget positioned at the top left of the screen.
///
/// Displays the app version in format "1.0.0+1" with minimal visual footprint.
class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Text(
        VersionService.getFullVersion(),
        style: TextStyle(
          fontSize: 8,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
