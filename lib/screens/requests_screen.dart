import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إرسال طلب جديد")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "اسم العميل")),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: "رقم هاتف العميل")),
            const SizedBox(height: 15),
            const TextField(maxLines: 3, decoration: InputDecoration(labelText: "ملاحظات إضافية")),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(onPressed: () {}, child: const Text("إرسال البيانات")),
            ),
          ],
        ),
      ),
    );
  }
}