import 'package:flutter/material.dart';
import '../../../core/services/home_pro_card_service.dart';
import 'info_card_widget.dart';

class HomeProCardContainer extends StatelessWidget {
  HomeProCardContainer({super.key});

  final HomeProCardService _service = HomeProCardService();

  static const String _fallback =
      "المعلومة قوة… وكل يوم تفهم أكتر، تقرّب خطوة من الاحتراف.";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _service.streamText(),
      builder: (context, snapshot) {
        final text = snapshot.data != null && snapshot.data!.isNotEmpty
            ? snapshot.data!
            : _fallback;

        return InfoCardWidget(text: text);
      },
    );
  }
}
