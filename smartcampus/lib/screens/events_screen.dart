import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/event_provider.dart';
import '../models/event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshEvents,
        child: Builder(builder: (context) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && !provider.hasData) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(provider.error ?? 'Error loading events'),
                )
              ],
            );
          }

          if (provider.events.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No upcoming events.'),
                )
              ],
            );
          }

          return ListView.builder(
            itemCount: provider.events.length,
            itemBuilder: (context, index) {
              final Event event = provider.events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text('${event.date.toLocal().toIso8601String().split('T').first} • ${event.startTime} - ${event.endTime}'),
                trailing: Text(event.location),
              );
            },
          );
        }),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final startTimeController = TextEditingController(text: '09:00');
    final endTimeController = TextEditingController(text: '10:00');
    DateTime selectedDate = DateTime.now();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 4,
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Date: ${selectedDate.toIso8601String().split('T').first}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: selectedDate,
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          (dialogContext as Element).markNeedsBuild();
                        }
                      },
                      child: const Text('Pick date'),
                    ),
                  ],
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
                if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty || locationController.text.trim().isEmpty) {
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

    if (shouldCreate != true || !context.mounted) return;

    final provider = context.read<EventProvider>();
    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      date: selectedDate,
      startTime: startTimeController.text.trim(),
      endTime: endTimeController.text.trim(),
      location: locationController.text.trim(),
    );

    final success = await provider.addEvent(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Event added.' : 'Could not add event.')),
    );
  }
}
// Kept the provider-driven implementation above; removed static fallback duplicate.
