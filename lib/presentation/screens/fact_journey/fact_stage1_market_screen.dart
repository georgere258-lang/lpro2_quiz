import 'package:flutter/material.dart';

class FactStage1MarketScreen extends StatelessWidget {
  const FactStage1MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroResetCard(),
              const SizedBox(height: 32),
              _RealityBlock(
                title: "السوق مش وحدة واحدة",
                content:
                    "في سوق بيع\nفي سوق استثمار\nفي سوق مضاربة\nفي سوق سكن",
                lock: "اللي ينجح في سوق\nممكن يفشل في التاني",
              ),
              _RealityBlock(
                title: "ليه في ناس بتكسب؟",
                content:
                    "مش أذكى\nولا أجرأ\nولا ألسن\n\nفاهم هو بيبيع لمين\nوبيبيع إيه\nوإمتى",
              ),
              _RealityBlock(
                title: "ليه ناس بتكره العقارات؟",
                content: "مش بسبب العقارات\nبسبب ناس دخلت السوق\nمن غير فهم",
              ),
              _RealityBlock(
                title: "إنت مش لوحدك",
                content: "كل ناجح كان تايه في الأول\nالفرق؟\nكمل واتعلم",
              ),
              const SizedBox(height: 24),
              _MentalLockCard(
                text: "السوق مش ضدك\nالسوق محايد\nإنت اللي لازم تفهمه",
              ),
              const SizedBox(height: 32),
              _JourneyButton(
                text: "جاهز نفهم الشركات العقارية",
                onTap: () {
                  // Stage 2 لاحقًا
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
