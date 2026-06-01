import 'package:flutter/material.dart';

import '../../models/app_home_model.dart';
import 'section_title.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key, required this.productList});

  final List<HomeProductModel> productList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Recommendation'),
        for (var index = 0; index < productList.length; index++) ...[
          _RecommendationCard(product: productList[index]),
          if (index != productList.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.product});

  final HomeProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFECEFFF), Color(0xFFCADFFD)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A57B0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.productLogo.isEmpty
                      ? const Icon(
                          Icons.apps_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : Image.network(
                          product.productLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) {
                            return const Icon(
                              Icons.apps_rounded,
                              size: 12,
                              color: Colors.white,
                            );
                          },
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A57B0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 9,
                  ),
                  child: Text(
                    product.buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.maxAmount,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.maxAmountDesc,
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (product.loanRateValue.isNotEmpty)
                      _InfoTag(
                        label: '${product.rateDesc}：${product.loanRateValue}',
                      ),
                    if (product.loanRateValue.isNotEmpty &&
                        product.termInfo.isNotEmpty)
                      const SizedBox(height: 5),
                    if (product.termInfo.isNotEmpty)
                      _InfoTag(
                        label: '${product.loanTermText}：${product.termInfo}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFC6A86E), fontSize: 12),
      ),
    );
  }
}
