import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/news_ticker_config_service.dart';
import '../../../core/constants/app_colors.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NewsTickerConfigService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة التحكم"),
        backgroundColor: AppColors.primaryDeepTeal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<bool>(
          stream: service.streamEmbeddedEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? true;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: SwitchListTile(
                value: enabled,
                onChanged: (v) => service.setEmbeddedEnabled(v),
                title: Text(
                  "تفعيل الجمل المدمجة في التطبيق",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF003D3D),
                  ),
                ),
                subtitle: Text(
                  "إيقافها يعني الاعتماد فقط على الأخبار من لوحة التحكم",
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                activeThumbColor: AppColors.secondaryOrange,
              ),
            );
          },
        ),
      ),
    );
  }
}
