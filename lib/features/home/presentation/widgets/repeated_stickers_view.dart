import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';

/// Vista de pegatinas repetidas (duplicados). Se muestra al pulsar "Repetidas" en el bottom nav.
class RepeatedStickersView extends StatelessWidget {
  const RepeatedStickersView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.homeFilterSwaps,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Repetidas',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
