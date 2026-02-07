import 'package:flutter/material.dart';
import '../../../core/services/home_pro_card_service.dart';
import '../../../features/pro_card/models/pro_card_banner.dart';
import 'info_card_widget.dart';

class HomeProCardContainer extends StatelessWidget {
  HomeProCardContainer({super.key});

  final HomeProCardService _service = HomeProCardService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProCardBanner?>(
      stream: _service.streamBanner(),
      builder: (context, snapshot) {
        final banner = snapshot.data;
        if (banner == null) return const SizedBox.shrink();

        // لو النوع Text وهو فاضي -> اخفاء
        if (banner.isText && banner.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        // لو النوع Image وهو فاضي -> اخفاء
        if (banner.isImage && banner.imageUrl.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return InfoCardWidget(banner: banner);
      },
    );
  }
}
