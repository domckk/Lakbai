import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';
import '../shared/stamp_reveal_sheet.dart';

class ActiveQuestScreen extends StatefulWidget {
  const ActiveQuestScreen({super.key, required this.id});
  final String id;

  @override
  State<ActiveQuestScreen> createState() => _ActiveQuestScreenState();
}

class _ActiveQuestScreenState extends State<ActiveQuestScreen> {
  final _dio = buildDio();
  Map<String, dynamic>? _quest;
  List<dynamic> _checkpoints = [];
  int _currentIdx = 0;
  Position? _pos;
  StreamSubscription<Position>? _posStream;
  bool _loading = true, _checking = false, _qrMode = false;
  double? _distanceM;

  @override
  void initState() {
    super.initState();
    _load();
    _startLocation();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _dio.get('/quests/${widget.id}');
    final quest = res.data as Map<String, dynamic>;
    setState(() {
      _quest = quest;
      _checkpoints = (quest['checkpoints'] as List?) ?? [];
      _loading = false;
    });
  }

  Future<void> _startLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      setState(() => _pos = pos);
      _updateDistance();
    });
  }

  void _updateDistance() {
    final pos = _pos;
    if (pos == null || _checkpoints.isEmpty || _currentIdx >= _checkpoints.length) return;
    final cp = _checkpoints[_currentIdx] as Map<String, dynamic>;
    final cpLat = (cp['lat'] as num?)?.toDouble() ?? 0;
    final cpLng = (cp['lng'] as num?)?.toDouble() ?? 0;
    final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, cpLat, cpLng);
    setState(() => _distanceM = d);
  }

  bool get _inRange => (_distanceM ?? 9999) <= 80 && (_pos?.accuracy ?? 999) <= 35;

  Future<void> _checkIn({String? qrToken}) async {
    final pos = _pos;
    if (pos == null) return;
    setState(() => _checking = true);
    final cp = _checkpoints[_currentIdx] as Map<String, dynamic>;
    try {
      final res = await _dio.post('/checkpoints/${cp['id']}/checkin', data: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy_m': pos.accuracy,
        if (qrToken != null) 'qr_token': qrToken,
        'client_ts': DateTime.now().millisecondsSinceEpoch,
      });
      final data = res.data as Map<String, dynamic>;
      if (data['valid'] == true) {
        HapticFeedback.heavyImpact();
        final stamp = data['stamp'];
        if (mounted && stamp != null) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => StampRevealSheet(stamp: stamp, xp: data['xp_awarded'] ?? 0),
          );
        }
        if (data['quest_complete'] == true) {
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }
        setState(() => _currentIdx++);
        _updateDistance();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${data['reason']}')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in failed — try again')));
    } finally {
      if (mounted) setState(() { _checking = false; _qrMode = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: TrailColors.background, body: Center(child: CircularProgressIndicator()));

    if (_qrMode) return _buildQrScanner();

    final cp = _checkpoints.isNotEmpty && _currentIdx < _checkpoints.length
        ? _checkpoints[_currentIdx] as Map<String, dynamic>
        : null;
    final needsQr = (cp?['validationType'] as String?)?.contains('qr') ?? false;

    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: Text(_quest?['title'] ?? 'Active Quest'),
        backgroundColor: TrailColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                children: List.generate(_checkpoints.length, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentIdx ? TrailColors.primary : TrailColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              if (cp != null) ...[
                Text('Checkpoint ${_currentIdx + 1} of ${_checkpoints.length}',
                    style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
                const SizedBox(height: 8),
                Text(cp['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(cp['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TrailColors.onSurfaceMuted, height: 1.5)),
                const Spacer(),
                // Distance indicator
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _inRange ? TrailColors.success : TrailColors.primary, width: 3),
                          color: (_inRange ? TrailColors.success : TrailColors.primary).withOpacity(0.08),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded, size: 36, color: _inRange ? TrailColors.success : TrailColors.primary),
                              const SizedBox(height: 4),
                              Text(
                                _distanceM != null ? '${_distanceM!.round()}m' : '--',
                                style: TextStyle(color: _inRange ? TrailColors.success : TrailColors.onBackground, fontSize: 28, fontWeight: FontWeight.w700),
                              ),
                              Text(_inRange ? 'You\'re here!' : 'away', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (needsQr)
                  FilledButton.icon(
                    onPressed: _inRange ? () => setState(() => _qrMode = true) : null,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan QR Code'),
                  )
                else
                  FilledButton(
                    onPressed: _inRange && !_checking ? _checkIn : null,
                    child: _checking
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_inRange ? "I'm Here!" : 'Get Closer...'),
                  ),
              ] else
                Center(child: Text('All checkpoints visited!', style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR'), backgroundColor: TrailColors.background),
      body: MobileScannerWidget(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) _checkIn(qrToken: code);
        },
      ),
    );
  }
}

class MobileScannerWidget extends StatefulWidget {
  const MobileScannerWidget({super.key, required this.onDetect});
  final void Function(BarcodeCapture) onDetect;

  @override
  State<MobileScannerWidget> createState() => _MobileScannerWidgetState();
}

class _MobileScannerWidgetState extends State<MobileScannerWidget> {
  final _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(controller: _ctrl, onDetect: widget.onDetect);
}
