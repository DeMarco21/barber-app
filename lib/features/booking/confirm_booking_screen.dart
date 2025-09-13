import 'package:flutter/material.dart';
import 'models.dart';

class ConfirmBookingScreen extends StatelessWidget {
  final AppointmentDraft draft;
  const ConfirmBookingScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _RowItem(label: 'Barber', value: draft.barber.name),
                    const SizedBox(height: 8),
                    _RowItem(label: 'Service', value: draft.service),
                    const SizedBox(height: 8),
                    _RowItem(label: 'Date', value: draft.date),
                    const SizedBox(height: 8),
                    _RowItem(label: 'Time', value: draft.timeSlot),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // For now, show success only (no backend yet)
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.black,
                          title: const Text('Booked!', style: TextStyle(color: Colors.white)),
                          content: Text(
                            'Your appointment with ${draft.barber.name} on ${draft.date} at ${draft.timeSlot} is set.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('OK', style: TextStyle(color: colors.primary)),
                            )
                          ],
                        ),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}