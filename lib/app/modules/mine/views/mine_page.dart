import 'package:flutter/material.dart';

import '../../home/views/widgets/section_title.dart';
import '../../../theme/screen_adapter.dart';
import 'widgets/mine_profile_card.dart';
import 'widgets/mine_service_card.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: ScreenAdapter.edgeInsetsOnly(
            left: 20,
            top: 0,
            right: 20,
            bottom: 24,
          ),
          child: Column(
            children: [
              SizedBox(height: 41.h),
              const MineProfileCard(),
              SizedBox(height: 20.h),
              SectionTitle(title: 'Our Service'),
              MineServiceCard(),
            ],
          ),
        ),
      ),
    );
  }
}
