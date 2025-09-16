import 'package:flutter/material.dart';
import 'client_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  final List<Map<String, String>> barbers;
  const AdminDashboard({
    super.key,
    this.barbers = const [], // ✅ default empty list
  });



  @override
  State<AdminDashboard> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboard> {
  String? selectedBarberFilter;
  String? selectedStatusFilter; // "upcoming", "completed", "cancelled"
  DateTime? selectedDateFilter;

  // Simulated shared appointments list
  List<Map<String, dynamic>> appointments = [
    {
      "barber": "Marcus Bailey",
      "date": DateTime.now(),
      "time": "10:00 AM",
      "status": "upcoming",
      "notes": "Low fade",
      "payment": "Cash",
      "client": "John Smith"
    },
    {
      "barber": "Shane Morgan",
      "date": DateTime.now().subtract(const Duration(days: 2)),
      "time": "1:00 PM",
      "status": "completed",
      "notes": "Beard trim",
      "payment": "Card",
      "client": "Alex Brown"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = appointments.where((appt) {
      bool matches = true;
      if (selectedBarberFilter != null &&
          appt['barber'] != selectedBarberFilter) {
        matches = false;
      }
      if (selectedStatusFilter != null &&
          appt['status'] != selectedStatusFilter) {
        matches = false;
      }
      if (selectedDateFilter != null) {
        matches = matches &&
            appt['date'].year == selectedDateFilter!.year &&
            appt['date'].month == selectedDateFilter!.month &&
            appt['date'].day == selectedDateFilter!.day;
      }
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account, color: Colors.amber),
            tooltip: "Go to Client Dashboard",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientDashboard(),
                ),
              );

            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: filteredAppointments.isEmpty
                  ? const Center(
                child: Text("No appointments found",
                    style: TextStyle(color: Colors.white70)),
              )
                  : ListView.builder(
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appt = filteredAppointments[index];
                  return _buildAppointmentCard(appt);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8, // space between items horizontally
      runSpacing: 8, // space between rows when wrapping
      children: [
        // Barber Filter
        SizedBox(
          width: 250, // fixed width; adjust or make dynamic if needed
          child: DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1C1C1C),
            decoration: _filterDecoration("Barber"),
            initialValue: selectedBarberFilter,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text("All", style: TextStyle(color: Colors.white)),
              ),
              ...widget.barbers.map((b) => DropdownMenuItem(
                value: b["name"],
                child: Text(
                  b["name"]!,
                  style: const TextStyle(color: Colors.white),
                ),
              )),
            ],
            onChanged: (val) => setState(() => selectedBarberFilter = val),
          ),
        ),

        // Status Filter
        SizedBox(
          width: 250,
          child: DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1C1C1C),
            decoration: _filterDecoration("Status"),
            initialValue: selectedStatusFilter,
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text("All", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: "upcoming",
                child: Text("Upcoming", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: "completed",
                child: Text("Completed", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: "cancelled",
                child: Text("Cancelled", style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (val) => setState(() => selectedStatusFilter = val),
          ),
        ),

        // Date Picker Button
        IconButton(
          icon: const Icon(Icons.date_range, color: Colors.amber),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => selectedDateFilter = picked);
            }
          },
        ),

        // Clear Date Button
        if (selectedDateFilter != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent),
            onPressed: () => setState(() => selectedDateFilter = null),
          ),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.amber),
      filled: true,
      fillColor: Colors.black.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final dateStr =
        "${appt['date'].day}/${appt['date'].month}/${appt['date'].year}";
    final statusColor = appt['status'] == 'completed'
        ? Colors.green
        : appt['status'] == 'cancelled'
        ? Colors.redAccent
        : Colors.amber;

    return Card(
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(appt['barber'][0],
              style: const TextStyle(color: Colors.black)),
        ),
        title: Text("${appt['barber']} • ${appt['time']}",
            style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$dateStr • ${appt['status']}",
                style: const TextStyle(color: Colors.white70)),
            Text("Client: ${appt['client']}",
                style: const TextStyle(color: Colors.white54)),
            if ((appt['notes'] ?? "").isNotEmpty)
              Text("Notes: ${appt['notes']}",
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
            Text("Payment: ${appt['payment']}",
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                setState(() => appt['status'] = 'cancelled');
                break;
              case 'complete':
                setState(() => appt['status'] = 'completed');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text("Edit notes", style: TextStyle(color: Colors.white)),
            ),
            if (appt['status'] == 'upcoming') ...[
              const PopupMenuItem(
                value: 'complete',
                child:
                Text("Mark completed", style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child:
                Text("Cancel appointment", style: TextStyle(color: Colors.white)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _editNotes(Map<String, dynamic> appt) {
    final controller = TextEditingController(text: appt['notes'] ?? "");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Edit Notes", style: TextStyle(color: Colors.amber)),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() => appt['notes'] = controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.black87,
                  content: Text(
                    "Notes updated",
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              );
            },
            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  }