import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme.dart';

class PickedLocation {
  final LatLng point;
  final String address;
  const PickedLocation(this.point, this.address);
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Nominatim requires an identifying User-Agent
  static const _headers = {'User-Agent': 'quick_delivery_app/1.0'};

  final _map = MapController();
  final _searchCtrl = TextEditingController();
  LatLng _point = const LatLng(36.8065, 10.1815); // Tunis
  String _address = 'Tap the map to choose a location';
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _setPoint(LatLng p) async {
    setState(() {
      _point = p;
      _busy = true;
    });
    String address =
        '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    try {
      final res = await http
          .get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 10));
      final name = jsonDecode(res.body)['display_name'] as String?;
      if (name != null) address = name;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _address = address;
      _busy = false;
    });
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await http
          .get(
        Uri.https('nominatim.openstreetmap.org', '/search',
            {'format': 'jsonv2', 'q': q, 'limit': '1'}),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 10));
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) {
        _snack('No result found');
        if (mounted) setState(() => _busy = false);
        return;
      }
      final p = LatLng(
        double.parse(list[0]['lat']),
        double.parse(list[0]['lon']),
      );
      _map.move(p, 16);
      await _setPoint(p);
    } catch (_) {
      _snack('Search failed. Check your connection.');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useMyLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _snack('Location permission denied');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, 16);
      await _setPoint(p);
    } catch (_) {
      _snack('Could not get your location');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose delivery location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 13,
              onTap: (_, p) => _setPoint(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.quick_delivery',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_pin,
                      size: 48, color: AppTheme.primary),
                ),
              ]),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search an address',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _useMyLocation,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_address, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pop(
                          context, PickedLocation(_point, _address)),
                      child: _busy
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Confirm location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}