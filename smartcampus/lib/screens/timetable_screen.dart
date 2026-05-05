import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/timetable_provider.dart';
import '../models/timetable_item.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimetableProvider>(context, listen: false).loadTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimetableProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: Builder(builder: (context) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && !provider.hasData) {
            return ListView(children: [Padding(padding: const EdgeInsets.all(16.0), child: Text(provider.error!))]);
          }

          if (provider.items.isEmpty) {
            return ListView(children: const [Padding(padding: EdgeInsets.all(16.0), child: Text('No timetable entries.'))]);
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final TimetableItem item = provider.items[index];
              return ListTile(
                title: Text(item.subject),
                subtitle: Text('${item.day} • ${item.startTime} - ${item.endTime}'),
                trailing: Text(item.room),
              );
            },
          );
        }),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final subjectController = TextEditingController();
    final instructorController = TextEditingController();
    final roomController = TextEditingController();
    final startTimeController = TextEditingController(text: '09:00');
    final endTimeController = TextEditingController(text: '10:00');
    String day = 'Monday';

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New timetable entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(labelText: 'Instructor'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: day,
                      items: const [
                        DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                        DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                        DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                        DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                        DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                        DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                        DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            day = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(labelText: 'Room'),
                    ),
                    TextField(
                      controller: startTimeController,
                      decoration: const InputDecoration(labelText: 'Start time (HH:mm)'),
                    ),
                    TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(labelText: 'End time (HH:mm)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (subjectController.text.trim().isEmpty || instructorController.text.trim().isEmpty || roomController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true || !context.mounted) return;

    final provider = context.read<TimetableProvider>();
    final item = TimetableItem(
      id: DateTime.now().millisecondsSinceEpoch,
      subject: subjectController.text.trim(),
      instructor: instructorController.text.trim(),
      day: day,
      startTime: startTimeController.text.trim(),
      endTime: endTimeController.text.trim(),
      room: roomController.text.trim(),
    );

    final success = await provider.addItem(item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Timetable entry added.' : 'Could not add timetable entry.')),
    );
  }
}
