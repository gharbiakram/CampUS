import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/event_note.dart';
import '../services/event_notes_provider.dart';
import '../services/permission_service.dart';

class EventNotesScreen extends StatefulWidget {
  final Event event;

  const EventNotesScreen({super.key, required this.event});

  @override
  State<EventNotesScreen> createState() => _EventNotesScreenState();
}

class _EventNotesScreenState extends State<EventNotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();

  String? _selectedImageBase64;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EventNotesProvider>().loadNotes(widget.event.id);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final permission = await _permissionService.requestCameraPermission();
      if (permission != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required.')),
        );
        return;
      }
    }

    final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _addNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty && _selectedImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or a photo before saving.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final provider = context.read<EventNotesProvider>();
    final success = await provider.addNote(
      eventId: widget.event.id,
      note: noteText.isEmpty ? 'Photo note' : noteText,
      imageData: _selectedImageBase64,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _selectedImageBase64 = null;
    });
    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Event note saved.' : 'Could not save note.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} Notes'),
      ),
      body: Column(
        children: [
          _Composer(
            noteController: _noteController,
            selectedImageBase64: _selectedImageBase64,
            submitting: _submitting,
            onPickGallery: () => _pickImage(ImageSource.gallery),
            onPickCamera: () => _pickImage(ImageSource.camera),
            onSave: _addNote,
            onClearImage: () {
              setState(() {
                _selectedImageBase64 = null;
              });
            },
          ),
          Expanded(
            child: Consumer<EventNotesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.notes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.notes.isEmpty) {
                  return const Center(child: Text('No notes for this event yet.'));
                }

                return ListView.builder(
                  cacheExtent: 800,
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.notes.length,
                  itemBuilder: (context, index) {
                    final note = provider.notes[index];
                    return RepaintBoundary(
                      child: _NoteCard(note: note),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController noteController;
  final String? selectedImageBase64;
  final bool submitting;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onSave;
  final VoidCallback onClearImage;

  const _Composer({
    required this.noteController,
    required this.selectedImageBase64,
    required this.submitting,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onSave,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Event note',
                hintText: 'Write a quick note or attach a photo',
              ),
            ),
            const SizedBox(height: 8),
            if (selectedImageBase64 != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(selectedImageBase64!),
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClearImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: submitting ? null : onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final EventNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.note),
            if (note.imageData != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(note.imageData!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              note.createdAt.toLocal().toIso8601String().replaceFirst('T', ' ').split('.').first,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
