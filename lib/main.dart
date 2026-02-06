import 'package:flutter/material.dart';

void main() {
  // التأكد من تهيئة الروابط قبل بدء أي شيء
  WidgetsFlutterBinding.ensureInitialized();

  // طباعة سجل للتأكد من أن كود دارت بدأ العمل فعلياً
  print("🟢 [DART MAIN] Flutter execution started");

  runApp(const _ProbeApp());
}

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white, // ضمان وجود خلفية بيضاء بدلاً من السوداء
        body: Center(
          child: Text(
            'PROBE UI OK\nBuild #20',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
