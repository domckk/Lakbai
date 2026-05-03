import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Full Mapbox integration requires a valid MAPBOX_TOKEN.
/// This scaffold renders the placeholder until the token is configured.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(title: const Text('Map')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, size: 72, color: TrailColors.onSurfaceMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Map coming soon', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Add your Mapbox token to MAPBOX_TOKEN env var and integrate mapbox_maps_flutter.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TrailColors.onSurfaceMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
