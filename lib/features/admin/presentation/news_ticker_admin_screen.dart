import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class NewsTickerAdminScreen extends StatefulWidget {
  const NewsTickerAdminScreen({super.key});

  @override
  State<NewsTickerAdminScreen> createState() => _NewsTickerAdminScreenState();
}

class _NewsTickerAdminScreenState extends State<NewsTickerAdminScreen> {
  bool notifyUsers = false;
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة شريط الأخبار"),
        backgroundColor: AppColors.primaryDeepTeal,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryOrange,
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news_ticker_items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['text_ar'] ?? ""),
                  leading: Switch(
                    value: data['isActive'] ?? false,
                    onChanged: (v) {
                      doc.reference.update({'isActive': v});
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => doc.reference.delete(),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context) {
    final textController = TextEditingController();
    final priorityController = TextEditingController(text: "0");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("خبر جديد",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            TextField(controller: textController, maxLines: 3),
            TextField(
                controller: priorityController,
                keyboardType: TextInputType.number),
            SwitchListTile(
              title: const Text("إرسال إشعار"),
              value: notifyUsers,
              onChanged: (v) => setState(() => notifyUsers = v),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('news_ticker_items')
                    .add({
                  'text_ar': textController.text,
                  'priority': int.tryParse(priorityController.text) ?? 0,
                  'notify': notifyUsers,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                  'startDate': startDate,
                  'endDate': endDate,
                });
                Navigator.pop(context);
              },
              child: const Text("نشر"),
            ),
          ],
        ),
      ),
    );
  }
}
