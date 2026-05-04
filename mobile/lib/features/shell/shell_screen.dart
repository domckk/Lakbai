import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/destination_provider.dart';
import '../../core/theme/colors.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  static const _tabs = [
    ('/home',     Icons.home_rounded,        'Home'),
    ('/quests',   Icons.flag_rounded,         'Quests'),
    ('/passport', Icons.auto_stories_rounded, 'Passport'),
    ('/profile',  Icons.person_rounded,       'Profile'),
  ];

  bool _isOffline = false;
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  int _indexOf(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  void _onTabTap(String path) {
    if (path == '/quests') {
      final dest = ref.read(activeDestinationProvider);
      if (dest != null) {
        context.go('/quests?destination=${dest.slug}&destinationName=${Uri.encodeComponent(dest.name)}');
        return;
      }
    }
    context.go(path);
  }

  void _openQrScanner() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QrScanSheet(),
    );
  }

  void _onConnectivityChange(AsyncValue<bool>? prev, AsyncValue<bool> next) {
    final isOnline = next.valueOrNull ?? true;
    if (!isOnline) {
      _restoredTimer?.cancel();
      if (!_isOffline) setState(() { _isOffline = true; _showRestored = false; });
    } else if (_isOffline) {
      _restoredTimer?.cancel();
      setState(() { _isOffline = false; _showRestored = true; });
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showRestored = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, _onConnectivityChange);

    final showBanner = _isOffline || _showRestored;

    return Scaffold(
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: showBanner ? _ConnectivityBanner(isOffline: _isOffline) : const SizedBox.shrink(),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TrailColors.surface,
          border: const Border(top: BorderSide(color: TrailColors.peach)),
          boxShadow: const [
            BoxShadow(color: TrailColors.peach50, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // Left two tabs
                ..._tabs.take(2).toList().asMap().entries.map((e) =>
                  _NavItem(tab: e.value, selected: _indexOf(context) == e.key, onTap: () => _onTabTap(e.value.$1)),
                ),

                // Center QR button
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _openQrScanner,
                      child: Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(
                          color: TrailColors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: TrailColors.orangeShadow, blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ),

                // Right two tabs
                ..._tabs.skip(2).toList().asMap().entries.map((e) =>
                  _NavItem(tab: e.value, selected: _indexOf(context) == e.key + 2, onTap: () => _onTabTap(e.value.$1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.isOffline});
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(isOffline),
        width: double.infinity,
        color: isOffline ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
        padding: EdgeInsets.only(top: topPad + 6, bottom: 10, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOffline ? 'No internet connection' : 'Connection restored',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.onTap});
  final (String, IconData, String) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.$2, color: selected ? TrailColors.orange : TrailColors.onSurfaceMuted, size: 24),
            const SizedBox(height: 3),
            Text(tab.$3, style: TextStyle(color: selected ? TrailColors.orange : TrailColors.onSurfaceMuted, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _QrScanSheet extends StatefulWidget {
  const _QrScanSheet();

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  final _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _processing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    setState(() => _processing = true);
    HapticFeedback.heavyImpact();
    try {
      // Try checkpoint QR check-in
      final pos = await _tryGetPosition();
      if (pos != null) {
        // Extract checkpoint ID from QR if possible, otherwise show raw
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR scanned: $code')),
        );
      }
    } finally {
      if (mounted) { setState(() => _processing = false); Navigator.pop(context); }
    }
  }

  Future<Map<String, double>?> _tryGetPosition() async => null; // location handled in active quest

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: TrailColors.brown,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(color: TrailColors.peach.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: TrailColors.orange, size: 22),
                const SizedBox(width: 10),
                const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Point at a checkpoint QR to check in', style: TextStyle(color: TrailColors.peach.withOpacity(0.8), fontSize: 13)),
          ),
          const SizedBox(height: 16),
          // Scanner
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    MobileScanner(controller: _ctrl, onDetect: _onDetect),
                    // Scan overlay frame
                    Center(
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: TrailColors.orange, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (_processing)
                      Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator(color: TrailColors.orange)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
