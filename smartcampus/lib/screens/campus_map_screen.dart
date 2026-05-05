import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  String? _statusText;
  bool _isTracking = false;

  static const LatLng _defaultCenter = LatLng(33.8938, 35.5018);

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    await _positionSubscription?.cancel();

    setState(() {
      _isTracking = true;
      _statusText = 'Starting live location tracking...';
    });

    try {
      _positionSubscription = _locationService.watchPosition().listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
            _statusText = 'Live location active.';
          });
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            17,
          );
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isTracking = false;
            _statusText = error.toString();
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isTracking = false;
        _statusText = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPosition;
    final center = current == null
        ? _defaultCenter
        : LatLng(current.latitude, current.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Campus Map'),
        actions: [
          IconButton(
            tooltip: 'Refresh tracking',
            onPressed: _startTracking,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                onMapReady: () {
                  if (_currentPosition != null) {
                    _mapController.move(center, 17);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smartcampus',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 44,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isTracking ? 'Tracking is running' : 'Tracking is paused',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  current == null
                      ? 'Waiting for your current location.'
                      : 'Lat: ${current.latitude.toStringAsFixed(5)}, Lon: ${current.longitude.toStringAsFixed(5)}',
                ),
                if (_statusText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startTracking,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start live tracking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: current == null
                            ? null
                            : () {
                                _mapController.move(center, 17);
                              },
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Center map'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}