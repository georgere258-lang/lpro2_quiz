import 'package:flutter/material.dart';
import '../../../core/services/home_pro_card_service.dart';
import 'info_card_widget.dart';

class HomeProCardContainer extends StatelessWidget {
  HomeProCardContainer({super.key});

  final HomeProCardService _service = HomeProCardService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _service.streamText(),
      builder: (context, snapshot) {
        final text = snapshot.data;
        if (text == null || text.isEmpty) return const SizedBox.shrink();
        return InfoCardWidget(text: text);
      },
    );
  }
}
