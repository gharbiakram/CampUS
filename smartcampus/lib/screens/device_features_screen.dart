import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/location_service.dart';
import '../services/permission_service.dart';

class DeviceFeaturesScreen extends StatefulWidget {
  const DeviceFeaturesScreen({super.key});

  @override
  State<DeviceFeaturesScreen> createState() => _DeviceFeaturesScreenState();
}

class _DeviceFeaturesScreenState extends State<DeviceFeaturesScreen> {
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _locationText;
  String? _statusText;
  bool _loadingLocation = false;

  Future<void> _pickImage(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? await _permissionService.requestCameraPermission()
        : PermissionStatus.granted;

    if (!permission.isGranted) {
      setState(() {
        _statusText = 'Camera permission is required for this action.';
      });
      return;
    }

    final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (!mounted) return;
    if (image == null) {
      setState(() {
        _selectedImageBytes = null;
        _statusText = 'No image selected.';
      });
      return;
    }

    try {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _statusText = 'Image selected successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Failed to read image.';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _statusText = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _locationText = 'Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}';
        _statusText = 'Location acquired.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationText = null;
        _statusText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Camera / Gallery',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick from gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take photo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No image selected yet.'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadingLocation ? null : _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: Text(_loadingLocation ? 'Getting location...' : 'Get current location'),
                  ),
                  const SizedBox(height: 12),
                  Text(_locationText ?? 'Location not fetched yet.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_statusText != null)
            Text(
              _statusText!,
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
