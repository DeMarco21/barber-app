import 'package:flutter/material.dart';
import 'models.dart';
import 'confirm_booking_screen.dart';

class AvailabilityScreen extends StatefulWidget {
  final Barber barber;
  const AvailabilityScreen({super.key, required this.barber});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  String? selectedDate;
  String? selectedTime;
  String? selectedService;

  @override
  void initState() {
    super.initState();
    // Preselect first available date and time if present
    if (widget.barber.availability.isNotEmpty) {
      selectedDate = widget.barber.availability.keys.first;
      final slots = widget.barber.availability[selectedDate]!;
      if (slots.isNotEmpty) selectedTime = slots.first;
    }
    if (widget.barber.services.isNotEmpty) {
      selectedService = widget.barber.services.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final dates = widget.barber.availability.keys.toList();

    final timeSlots = (selectedDate != null)
        ? widget.barber.availability[selectedDate] ?? []
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: Text('Availability — ${widget.barber.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Services
            const Text('Service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedService,
              dropdownColor: colors.surface,
              decoration: _fieldDecoration(colors),
              iconEnabledColor: colors.primary,
              items: widget.barber.services
                  .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (val) => setState(() => selectedService = val),
            ),
            const SizedBox(height: 16),

            // Dates
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedDate,
              dropdownColor: colors.surface,
              decoration: _fieldDecoration(colors),
              iconEnabledColor: colors.primary,
              items: dates
                  .map((d) => DropdownMenuItem(
                value: d,
                child: Text(d, style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedDate = val;
                  // reset time when date changes
                  final slots = widget.barber.availability[selectedDate] ?? [];
                  selectedTime = slots.isNotEmpty ? slots.first : null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Time slots
            const Text('Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            if (timeSlots.isEmpty)
              const Text('No slots available for this date.', style: TextStyle(color: Colors.white70))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlots.map((slot) {
                  final isSelected = slot == selectedTime;
                  return ChoiceChip(
                    label: Text(slot),
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    onSelected: (_) => setState(() => selectedTime = slot),
                  );
                }).toList(),
              ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (selectedDate != null && selectedTime != null && selectedService != null)
                    ? () {
                  final draft = AppointmentDraft(
                    barber: widget.barber,
                    date: selectedDate!,
                    timeSlot: selectedTime!,
                    service: selectedService!,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConfirmBookingScreen(draft: draft),
                    ),
                  );
                }
                    : null,
                child: const Text('Review & Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme colors) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}