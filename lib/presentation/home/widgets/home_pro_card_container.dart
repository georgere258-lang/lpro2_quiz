// PATH: lib/.../home_pro_card_container.dart

import 'package:flutter/material.dart';
import '../../../core/services/home_pro_card_service.dart';
import '../../../features/pro_card/models/pro_card_banner.dart';
import 'info_card_widget.dart';

class HomeProCardContainer extends StatefulWidget {
  const HomeProCardContainer({super.key});

  @override
  State<HomeProCardContainer> createState() => _HomeProCardContainerState();
}

class _HomeProCardContainerState extends State<HomeProCardContainer> {
  late final HomeProCardService _service;
  late Stream<ProCardBanner?> _bannerStream;

  @override
  void initState() {
    super.initState();
    _service = HomeProCardService();
    // استدعاء الـ Stream المطور (اللي بيعمل قراءة واحدة فقط)
    _bannerStream = _service.streamBanner();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProCardBanner?>(
      stream: _bannerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final banner = snapshot.data;
        if (banner == null) return const SizedBox.shrink();

        // ✅ تم إرجاع الـ onRead لـ null لضمان عدم ظهور أي زرار إضافي
        return InfoCardWidget(
          banner: banner,
          onRead: null,
        );
      },
    );
  }
}
