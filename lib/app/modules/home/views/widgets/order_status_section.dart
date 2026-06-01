import 'package:flutter/material.dart';

import '../../models/app_home_model.dart';
import 'section_title.dart';

class OrderStatusSection extends StatelessWidget {
  const OrderStatusSection({super.key, required this.processList});

  final List<HomeProcessModel> processList;

  @override
  Widget build(BuildContext context) {
    final process = processList.first;
    final actionText = process.buttons.isNotEmpty
        ? process.buttons.first.text
        : process.orderStatusText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Order Status'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFAABAB), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFC4C4)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(13, 6, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      process.orderStatusText,
                      style: const TextStyle(
                        color: Color(0xFFD05353),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      process.title,
                      style: const TextStyle(
                        color: Color(0xFFE87C7C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _OrderMetric(
                        value: process.displayAmount.isNotEmpty
                            ? process.displayAmount
                            : process.amount,
                        label: process.amountDesc,
                        emphasize: false,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 34,
                      color: const Color(0xFFFFEEEE),
                    ),
                    const SizedBox(width: 26),
                    Expanded(
                      child: _OrderMetric(
                        value: process.date,
                        label: process.dateDesc,
                        emphasize: true,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 2,
                margin: const EdgeInsets.only(top: 15),
                color: const Color(0xFFFAABAB),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Color(0xFFD05353),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({
    required this.value,
    required this.label,
    required this.emphasize,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: emphasize ? const Color(0xFFD05353) : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
      ],
    );
  }
}
