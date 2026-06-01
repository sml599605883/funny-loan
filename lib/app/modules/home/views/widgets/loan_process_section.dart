import 'package:flutter/material.dart';

import '../../../../theme/screen_adapter.dart';
import 'section_title.dart';

class LoanProcessSection extends StatelessWidget {
  const LoanProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Loan Process'),
        Image.asset(
          'assets/home/home_loan_process_bg.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/home/home_bottom_bg.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }
}
