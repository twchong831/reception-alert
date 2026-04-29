import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmOverlay extends StatefulWidget {
  final String title;
  final String visitorName;
  final String visitorCompany;
  final String purpose;
  final VoidCallback onConfirm;
  final String alarmSound;

  const AlarmOverlay({
    super.key,
    required this.title,
    required this.visitorName,
    required this.visitorCompany,
    required this.purpose,
    required this.onConfirm,
    this.alarmSound = 'alarm.wav',
  });

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _playAlarm();
  }

  Future<void> _playAlarm() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/${widget.alarmSound}'));
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active,
                    size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _infoRow('방문자', widget.visitorName),
                const SizedBox(height: 12),
                _infoRow('소속', widget.visitorCompany),
                const SizedBox(height: 12),
                _infoRow('목적', widget.purpose),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _player.stop();
                      widget.onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        const Text('확인', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 22)),
      ],
    );
  }
}
