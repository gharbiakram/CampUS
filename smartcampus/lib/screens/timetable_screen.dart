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
}
