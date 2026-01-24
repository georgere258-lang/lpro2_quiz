// PATH: lib/presentation/screens/admin/widgets/admin_shared_widgets.dart
// Shared widgets for admin panel tabs

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

const double kAdminBtnW = 200;
const double kAdminBtnH = 42;

Widget adminBtnText(String text, {Color color = Colors.white, double size = 13}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: size, color: color)),
  );
}

Widget adminTextField(TextEditingController c, String hint, {int maxLines = 1}) {
  return TextField(
    controller: c,
    maxLines: maxLines,
    textAlign: TextAlign.right,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}

Widget adminCenterBtn({required VoidCallback? onPressed, required Widget child, Color? bg}) {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: kAdminBtnW,
      height: kAdminBtnH,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: child,
      ),
    ),
  );
}

Widget adminStatusBadge(bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
    child: Text(isActive ? 'ظاهر' : 'مخفي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11, color: isActive ? Colors.green[800] : Colors.red[800])),
  );
}

Widget adminSmallBtn(String text, IconData icon, VoidCallback onPressed) {
  return SizedBox(
    width: 100,
    height: 36,
    child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: adminBtnText(text, size: 11)),
  );
}

Widget adminTinyBtn(String text, VoidCallback onPressed) {
  return SizedBox(
    height: 32,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: AppColors.primaryDeepTeal.withValues(alpha: 0.9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(text, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );
}

InputDecoration adminDropDecor() {
  return InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10));
}

Future<bool> adminConfirmDialog(BuildContext context, String title, String content) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(content, style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.red))),
          ],
        ),
      ) ??
      false;
}

class AdminTabLabel extends StatelessWidget {
  final String text;
  const AdminTabLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Tab(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1)))));
  }
}
