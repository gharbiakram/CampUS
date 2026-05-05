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
}
// Kept the provider-driven implementation above; removed static fallback duplicate.
