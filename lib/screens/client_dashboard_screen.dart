import 'package:flutter/material.dart';

class ClientDashboardScreen extends StatefulWidget {
  final List<Map<String, String>> barbers;
  const ClientDashboardScreen({super.key, required this.barbers});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final String clientName = "Demar";
  String? selectedBarber;
  DateTime? selectedDate;
  String? selectedTime;
  String? serviceNotes;

  final Map<String, List<String>> busySlots = {
    "Marcus Bailey": ["10:00 AM", "1:00 PM"],
    "Shane Morgan": ["11:00 AM"],
  };

  final List<String> allSlots = [
    "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"
  ];

  List<Map<String, dynamic>> appointments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: CustomScrollView(
        slivers: [
          _buildHeroSection(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  _buildBarberSelection(),
                  if (selectedBarber != null) _buildDatePicker(),
                  if (selectedDate != null) _buildTimeSlots(),
                  if (selectedTime != null) _buildNotesField(),
                  if (selectedTime != null) _buildConfirmButton(),
                  const SizedBox(height: 32),
                  _buildUpcomingTimeline(),
                  const SizedBox(height: 24),
                  _buildHistoryTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HERO SECTION
  Widget _buildHeroSection() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/shop_bg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $clientName",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Your next cut awaits",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP INDICATOR (3 steps now)
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, selectedBarber != null),
        _buildStepLine(),
        _buildStepCircle(2, selectedDate != null),
        _buildStepLine(),
        _buildStepCircle(3, selectedTime != null),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.transparent,
        border: Border.all(color: Colors.amber, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "$step",
          style: TextStyle(
            color: active ? Colors.black : Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.amber.withOpacity(0.5),
      ),
    );
  }

  // STEP 1: BARBER SELECTION
  Widget _buildBarberSelection() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.barbers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final barber = widget.barbers[index];
          final isSelected = selectedBarber == barber["name"];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedBarber = barber["name"];
                selectedDate = null;
                selectedTime = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.amber,
                    child: Text(
                      barber["name"]![0],
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    barber["name"]!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    barber["specialty"]!,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // STEP 2: DATE PICKER
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text("Select Date",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.amber)),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
                selectedTime = null;
              });
            }
          },
          child: Text(selectedDate == null
              ? "Pick a Date"
              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!
              .year}"),
        ),
      ],
    );
  }

  // STEP 3: TIME SLOTS
  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text("Select Time",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.amber)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allSlots.map((slot) {
            final isBusy = busySlots[selectedBarber]?.contains(slot) ?? false;
            final isSelected = selectedTime == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: isBusy
                  ? null
                  : (selected) {
                setState(() {
                  selectedTime = slot;
                });
              },
              selectedColor: Colors.amber,
              backgroundColor: Colors.grey[800],
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
              disabledColor: Colors.redAccent,
            );
          }).toList(),
        ),
      ],
    );
  }

  // NOTES FIELD (optional)
  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text("Describe Your Cut (optional)",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.amber)),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => serviceNotes = value,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Low fade with beard trim...",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // CONFIRM BUTTON
  Widget _buildConfirmButton() {
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              _addAppointment();
            },
            child: const Text("Confirm Booking"),
          ),
        ),
      ],
    );
  }

  // UPCOMING TIMELINE
  Widget _buildUpcomingTimeline() {
    final upcoming = appointments.where((a) => a['status'] == 'upcoming');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upcoming Appointments",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.amber)),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const Text("No upcoming appointments",
              style: TextStyle(color: Colors.white70))
        else
          Column(
            children:
            upcoming.map((appt) => _buildTimelineTile(appt, true)).toList(),
          ),
      ],
    );
  }

  // HISTORY TIMELINE
  Widget _buildHistoryTimeline() {
    final history = appointments.where((a) => a['status'] != 'upcoming');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Appointment History",
            style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.amber)),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Text("No past appointments",
              style: TextStyle(color: Colors.white70))
        else
          Column(
            children:
            history.map((appt) => _buildTimelineTile(appt, false)).toList(),
          ),
      ],
    );
  }

  Widget _buildTimelineTile(Map<String, dynamic> appt, bool isUpcoming) {
    final dateStr =
        "${appt['date'].day}/${appt['date'].month}/${appt['date'].year}";
    final statusColor = appt['status'] == 'completed'
        ? Colors.green
        : appt['status'] == 'cancelled'
        ? Colors.redAccent
        : Colors.amber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: Colors.white24,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.black.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text("${appt['barber']} • ${appt['time']}",
                  style: const TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$dateStr • ${appt['status']}",
                      style: const TextStyle(color: Colors.white70)),
                  if ((appt['notes'] ?? "").isNotEmpty)
                    Text("Notes: ${appt['notes']}",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                color: const Color(0xFF1C1C1C),
                iconColor: Colors.amber,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editNotes(appt);
                      break;
                    case 'cancel':
                      _confirmCancel(appt);
                      break;
                    case 'complete':
                      setState(() => appt['status'] = 'completed');
                      break;
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  items.add(
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text("Edit notes",
                          style: TextStyle(color: Colors.white)),
                    ),
                  );
                  if (isUpcoming) {
                    items.addAll([
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text("Mark completed",
                            style: TextStyle(color: Colors.white)),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text("Cancel appointment",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ]);
                  }
                  return items;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editNotes(Map<String, dynamic> appt) {
    final controller = TextEditingController(text: appt['notes'] ?? "");
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text(
                "Edit Notes", style: TextStyle(color: Colors.amber)),
            content: TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Update notes...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    "Cancel", style: TextStyle(color: Colors.amber)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  setState(() => appt['notes'] = controller.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.black87,
                      content: Text("Notes updated",
                          style: TextStyle(color: Colors.amber)),
                    ),
                  );
                },
                child: const Text("Save",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
  }

  void _addAppointment() {
    final newAppointment = {
      "barber": selectedBarber!,
      "date": selectedDate!,
      "time": selectedTime!,
      "status": "upcoming",
      "notes": serviceNotes ?? "",
    };

    setState(() {
      appointments.add(newAppointment);
      selectedBarber = null;
      selectedDate = null;
      selectedTime = null;
      serviceNotes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        content: Text(
          "Booked • ${newAppointment['barber']} at ${newAppointment['time']}",
          style: const TextStyle(color: Colors.amber),
        ),
      ),
    );
  }

  void _confirmCancel(Map<String, dynamic> appt) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Cancel Appointment",
              style: TextStyle(color: Colors.amber),
            ),
            content: const Text(
              "Are you sure you want to cancel this appointment?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "No",
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    appt['status'] = 'cancelled';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.black87,
                      content: Text(
                        "Appointment cancelled",
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  );
                },
                child: const Text("Yes, Cancel"),
              ),
            ],
          ),
    );
  }
}