import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';
import '../shared/stamp_reveal_sheet.dart';

const _dwellRequired = 60; // seconds on-site before auto check-in

class ActiveQuestScreen extends StatefulWidget {
  const ActiveQuestScreen({super.key, required this.id});
  final String id;

  @override
  State<ActiveQuestScreen> createState() => _ActiveQuestScreenState();
}

class _ActiveQuestScreenState extends State<ActiveQuestScreen>
    with TickerProviderStateMixin {
  final _dio    = buildDio();
  final _mapCtrl = MapController();

  Map<String, dynamic>? _quest;
  List<dynamic>         _checkpoints = [];
  int                   _currentIdx  = 0;
  Position?             _pos;
  StreamSubscription<Position>? _posStream;
  bool  _loading  = true;
  bool  _checking = false;
  bool  _qrMode   = false;
  double? _distanceM;

  // Dwell state
  int   _dwellSeconds = 0;
  Timer? _dwellTimer;
  bool  _wasInRange   = false;

  // Radar pulse animation
  late final AnimationController _radarCtrl;

  // ── lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _load();
    _startLocation();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _posStream?.cancel();
    _dwellTimer?.cancel();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────

  Future<void> _load() async {
    try {
      final res   = await _dio.get('/quests/${widget.id}');
      final quest = res.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _quest       = quest;
        _checkpoints = (quest['checkpoints'] as List?) ?? [];
        _loading     = false;
      });
      _moveCameraToCheckpoint();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _moveCameraToCheckpoint() {
    final cp  = _currentCp;
    final lat = (cp?['lat'] as num?)?.toDouble();
    final lng = (cp?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapCtrl.move(LatLng(lat, lng), 16);
    });
  }

  // ── location ───────────────────────────────────────────────

  Future<void> _startLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (!mounted) return;
    setState(() => _pos = pos);
    _updateDistance();
  }

  void _updateDistance() {
    final pos = _pos;
    final cp  = _currentCp;
    if (pos == null || cp == null) return;
    final cpLat = (cp['lat'] as num?)?.toDouble() ?? 0;
    final cpLng = (cp['lng'] as num?)?.toDouble() ?? 0;
    final d = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, cpLat, cpLng);
    setState(() => _distanceM = d);

    final nowInRange = _inRange;
    if (nowInRange && !_wasInRange) {
      _startDwell();
    } else if (!nowInRange && _wasInRange) {
      _cancelDwell();
    }
    _wasInRange = nowInRange;
  }

  // ── dwell timer ────────────────────────────────────────────

  void _startDwell() {
    _dwellTimer?.cancel();
    if (mounted) setState(() => _dwellSeconds = 0);
    _dwellTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _dwellTimer?.cancel(); return; }
      if (!_inRange) { _cancelDwell(); return; }
      setState(() => _dwellSeconds++);
      if (_dwellSeconds >= _dwellRequired) {
        _cancelDwell();
        _checkIn();
      }
    });
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    if (mounted) setState(() => _dwellSeconds = 0);
  }

  // ── helpers ────────────────────────────────────────────────

  Map<String, dynamic>? get _currentCp =>
      (_checkpoints.isNotEmpty && _currentIdx < _checkpoints.length)
          ? _checkpoints[_currentIdx] as Map<String, dynamic>
          : null;

  int  get _cpRadiusM => (_currentCp?['geoRadiusM'] as int?) ?? 80;
  bool get _inRange   =>
      (_distanceM ?? 9999) <= _cpRadiusM && (_pos?.accuracy ?? 999) <= 50;

  // ── check-in ───────────────────────────────────────────────

  Future<void> _checkIn({String? qrToken}) async {
    final pos = _pos;
    final cp  = _currentCp;
    if (pos == null || cp == null || _checking) return;
    setState(() => _checking = true);
    try {
      final res = await _dio.post('/checkpoints/${cp['id']}/checkin', data: {
        'lat':       pos.latitude,
        'lng':       pos.longitude,
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
            builder: (_) =>
                StampRevealSheet(stamp: stamp, xp: data['xp_awarded'] ?? 0),
          );
        }
        if (data['quest_complete'] == true) {
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }
        setState(() {
          _currentIdx++;
          _distanceM  = null;
          _wasInRange = false;
        });
        _updateDistance();
        _moveCameraToCheckpoint();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['reason']}')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in failed — try again')));
      }
    } finally {
      if (mounted) setState(() { _checking = false; _qrMode = false; });
    }
  }

  // ── map helpers ────────────────────────────────────────────

  void _centerOnUser() {
    final pos = _pos;
    if (pos == null) return;
    _mapCtrl.move(LatLng(pos.latitude, pos.longitude), _mapCtrl.camera.zoom);
  }

  void _centerOnTarget() => _moveCameraToCheckpoint();

  // ── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: TrailColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_qrMode) return _buildQrScanner();

    final cp      = _currentCp;
    final cpLat   = (cp?['lat'] as num?)?.toDouble();
    final cpLng   = (cp?['lng'] as num?)?.toDouble();
    final cpPoint = (cpLat != null && cpLng != null)
        ? LatLng(cpLat, cpLng)
        : null;
    final userPoint = _pos != null
        ? LatLng(_pos!.latitude, _pos!.longitude)
        : null;
    final needsQr = (cp?['validationType'] as String?)?.contains('qr') ?? false;
    final radiusM = _cpRadiusM.toDouble();
    final dwellPct = _dwellSeconds / _dwellRequired;
    final zoneColor = _inRange ? TrailColors.success : TrailColors.primary;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: cpPoint ?? const LatLng(18.0558, 120.5663),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lakbai',
              ),

              // Radar circles (animated)
              if (cpPoint != null)
                AnimatedBuilder(
                  animation: _radarCtrl,
                  builder: (_, __) {
                    final t      = _radarCtrl.value;
                    final eased  = math.sin(t * math.pi / 2); // ease-out
                    return CircleLayer(
                      circles: [
                        // Static detection zone fill
                        CircleMarker(
                          point: cpPoint,
                          radius: radiusM,
                          useRadiusInMeter: true,
                          color: zoneColor.withOpacity(0.10),
                          borderColor: zoneColor.withOpacity(0.40),
                          borderStrokeWidth: 1.5,
                        ),
                        // Pulsing sonar ring
                        CircleMarker(
                          point: cpPoint,
                          radius: radiusM * eased,
                          useRadiusInMeter: true,
                          color: Colors.transparent,
                          borderColor:
                              zoneColor.withOpacity((1.0 - t) * 0.55),
                          borderStrokeWidth: 2.5,
                        ),
                      ],
                    );
                  },
                ),

              // Target checkpoint pin
              if (cpPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: cpPoint,
                      width: 44,
                      height: 52,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: zoneColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: Icon(
                              _inRange ? Icons.check_rounded : Icons.flag_rounded,
                              color: Colors.white, size: 18,
                            ),
                          ),
                          Container(width: 2, height: 8, color: zoneColor),
                        ],
                      ),
                    ),
                  ],
                ),

              // User location blue dot
              if (userPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userPoint,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top bar (back + title + map controls) ──────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _MapIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      _quest?['title'] ?? 'Active Quest',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: TrailColors.onBackground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MapIconButton(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnUser),
                const SizedBox(width: 6),
                _MapIconButton(
                    icon: Icons.flag_rounded,
                    onTap: _centerOnTarget),
              ],
            ),
          ),

          // ── Bottom info card ────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20,
                  MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: TrailColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: cp != null
                  ? _buildInfoCard(cp, needsQr, dwellPct)
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('All checkpoints visited! 🎉',
                            style: TextStyle(
                                color: TrailColors.onBackground,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      Map<String, dynamic> cp, bool needsQr, double dwellPct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress segments
        Row(
          children: List.generate(
            _checkpoints.length,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _currentIdx
                      ? TrailColors.primary
                      : TrailColors.peach,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Checkpoint ${_currentIdx + 1} of ${_checkpoints.length}',
          style: const TextStyle(
              color: TrailColors.onSurfaceMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          cp['title'] ?? '',
          style: const TextStyle(
              color: TrailColors.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        if ((cp['description'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            cp['description'] ?? '',
            style: const TextStyle(
                color: TrailColors.onSurfaceMuted,
                fontSize: 13,
                height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),

        // Status area
        if (_pos == null)
          const Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Acquiring GPS…',
                style: TextStyle(color: TrailColors.onSurfaceMuted)),
          ])
        else if (_inRange)
          _buildDwellRow(needsQr, dwellPct)
        else
          _buildOutOfRangeRow(),
      ],
    );
  }

  Widget _buildOutOfRangeRow() {
    return Row(
      children: [
        const Icon(Icons.directions_walk_rounded,
            color: TrailColors.onSurfaceMuted, size: 18),
        const SizedBox(width: 8),
        Text(
          _distanceM != null
              ? '${_distanceM!.round()} m away'
              : 'Calculating…',
          style: const TextStyle(
              color: TrailColors.onSurfaceMuted, fontSize: 14),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: TrailColors.peach30,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Enter ${_cpRadiusM}m zone',
            style: const TextStyle(
                color: TrailColors.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDwellRow(bool needsQr, double dwellPct) {
    if (needsQr) {
      return FilledButton.icon(
        onPressed: () => setState(() => _qrMode = true),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan QR Code'),
        style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48)),
      );
    }
    final remaining = _dwellRequired - _dwellSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 52, height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: dwellPct,
                    strokeWidth: 4,
                    backgroundColor: TrailColors.peach,
                    valueColor: const AlwaysStoppedAnimation(
                        TrailColors.success),
                  ),
                  _checking
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TrailColors.success))
                      : Text(
                          '$remaining',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: TrailColors.success),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're here!",
                    style: TextStyle(
                        color: TrailColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stay for 1 minute to claim your reward',
                    style: TextStyle(
                        color: TrailColors.onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: dwellPct,
            minHeight: 6,
            backgroundColor: TrailColors.peach,
            valueColor:
                const AlwaysStoppedAnimation(TrailColors.success),
          ),
        ),
      ],
    );
  }

  // ── QR scanner fallback ────────────────────────────────────

  Widget _buildQrScanner() {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Scan QR'),
          backgroundColor: TrailColors.background),
      body: MobileScannerWidget(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) _checkIn(qrToken: code);
        },
      ),
    );
  }
}

// ── Shared small icon button for the map overlay ───────────────

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Icon(icon, color: TrailColors.onBackground, size: 20),
      ),
    );
  }
}

// ── QR scanner widget ──────────────────────────────────────────

class MobileScannerWidget extends StatefulWidget {
  const MobileScannerWidget({super.key, required this.onDetect});
  final void Function(BarcodeCapture) onDetect;

  @override
  State<MobileScannerWidget> createState() => _MobileScannerWidgetState();
}

class _MobileScannerWidgetState extends State<MobileScannerWidget> {
  final _ctrl =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MobileScanner(controller: _ctrl, onDetect: widget.onDetect);
}
