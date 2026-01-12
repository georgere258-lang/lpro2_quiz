import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/pro_insight_service.dart';
import '../../core/data/models/pro_insight_model.dart';

class ProInsightScreen extends StatelessWidget {
  ProInsightScreen({super.key});

  final ProInsightService _service = ProInsightService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المعلومة بتفرق"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ProInsightModel>>(
        stream: _service.streamActiveInsights(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text("لا توجد معلومات حالياً"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _InsightCard(item: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final ProInsightModel item;
  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(item.hook, 18, FontWeight.w900),
          _sp(),
          _block(item.mindReset, 15, FontWeight.w600),
          _sp(),
          _highlight(item.coreInsight),
          if (item.realityExample != null &&
              item.realityExample!.isNotEmpty) ...[
            _sp(),
            _block(item.realityExample!, 14, FontWeight.w500),
          ],
          _sp(),
          _lock(item.mentalLock),
        ],
      ),
    );
  }

  Widget _block(String text, double size, FontWeight weight) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        height: 1.8,
        color: const Color(0xFF2D3142),
      ),
    );
  }

  Widget _highlight(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _block(text, 15, FontWeight.w800),
    );
  }

  Widget _lock(String text) {
    return Row(
      children: [
        const Icon(Icons.lock_rounded, size: 18),
        const SizedBox(width: 8),
        Expanded(child: _block(text, 13, FontWeight.w700)),
      ],
    );
  }

  Widget _sp() => const SizedBox(height: 16);
}
