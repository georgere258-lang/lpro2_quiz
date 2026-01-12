import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class HomeProAdminScreen extends StatefulWidget {
  const HomeProAdminScreen({super.key});

  @override
  State<HomeProAdminScreen> createState() => _HomeProAdminScreenState();
}

class _HomeProAdminScreenState extends State<HomeProAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة كارت معلومة Pro"),
        backgroundColor: AppColors.primaryDeepTeal,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryOrange,
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('home_pro_items')
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
                elevation: 3,
                child: ListTile(
                  title: Text(
                    data['text'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    "أولوية: ${data['priority'] ?? 0}",
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
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
            Text(
              "معلومة Pro جديدة",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "اكتب المعلومة...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priorityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "الأولوية",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (textController.text.trim().isEmpty) return;

                  await FirebaseFirestore.instance
                      .collection('home_pro_items')
                      .add({
                    'text': textController.text.trim(),
                    'priority': int.tryParse(priorityController.text) ?? 0,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                },
                child: Text(
                  "نشر",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
