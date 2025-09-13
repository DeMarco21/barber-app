import 'package:flutter/material.dart';
import 'models.dart';
import 'availability_screen.dart';

class BarberListScreen extends StatelessWidget {
  const BarberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Barber')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockBarbers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final barber = mockBarbers[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: colors.primary),
              ),
              title: Text(barber.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                barber.services.join(' • '),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AvailabilityScreen(barber: barber),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}