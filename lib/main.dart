import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const SmartTimerApp());
}

class SmartTimerApp extends StatelessWidget {
  const SmartTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isRunning) {
        _onTimerFinished();
      }
    });
  bool _isRunning = false;

  // Input controller
  final TextEditingController _minCtrl = TextEditingController(text: '0');
  final TextEditingController _secCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  // Fungsi saat waktu habis
  void _onTimerFinished() {
    setState(() => _isRunning = false);
    _setAndroidAlarm(); // Panggil fungsi alarm sistem
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Waktu Habis!'),
        content: const Text('Alarm sistem Android telah dipicu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  // LOGIKA UTAMA: Memanggil fitur Alarm Android
  void _setAndroidAlarm() {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: {
          'android.intent.extra.alarm.MESSAGE': 'Timer Flutter Selesai!',
          'android.intent.extra.alarm.LENGTH': _controller.duration!.inSeconds,
          'android.intent.extra.alarm.SKIP_UI': false,
        },
      );
      intent.launch();
    }
  }

  void _applyNewDuration() {
    final m = int.tryParse(_minCtrl.text) ?? 0;
    final s = int.tryParse(_secCtrl.text) ?? 0;
    final total = (m * 60) + s;

    if (total > 0) {
      setState(() {
        _controller.duration = Duration(seconds: total);
        _controller.reset();
        _controller.value = 1.0; // Set lingkaran penuh
        _isRunning = false;
      });
    }
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _controller.stop();
      } else {
        // reverse berjalan dari 1.0 ke 0.0
        _controller.reverse(from: _controller.value == 0 ? 1.0 : _controller.value);
      }
      _isRunning = !_isRunning;
    });
  }

  String get _timerDisplay {
    Duration duration = _controller.duration! * _controller.value;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F8),
      appBar: AppBar(
        title: const Text('SMART TIMER', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Progress Lingkaran
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white,
                          color: Colors.blueAccent,
                        );
                      },
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Text(
                        _timerDisplay,
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'monospace', // Agar angka tidak goyang
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Input Durasi
              Row(
                children: [
                  _buildInputField(_minCtrl, 'Menit'),
                  const SizedBox(width: 15),
                  _buildInputField(_secCtrl, 'Detik'),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: _applyNewDuration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SET'),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Tombol Kontrol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBtn(Icons.refresh, () {
                    _controller.reset();
                    setState(() => _isRunning = false);
                  }),
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  _buildActionBtn(Icons.alarm, _setAndroidAlarm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 30, color: Colors.blueGrey),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}