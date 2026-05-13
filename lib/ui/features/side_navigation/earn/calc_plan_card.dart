import 'package:flutter/material.dart';
import 'earn_controller.dart';

class CalcPlanCard extends StatelessWidget {
  final EarnProduct? plan;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const CalcPlanCard({
    super.key,
    required this.plan,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (plan == null) return const Expanded(child: SizedBox.shrink());
    final isSel = selectedId == plan!.id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(plan!.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? const Color(0xFFB8E600) : const Color(0xFF2E2E2E),
              width: 1.5,
            ),
            color: const Color(0xFF1E1E1E),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Easy Earn",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${plan!.apr.toStringAsFixed(2)}%",
                    style: const TextStyle(
                      color: Color(0xFF00D68F),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "APR",
                    style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Easy Earn | ${plan!.lockDays == 0 ? "Flexible" : "Fixed"}",
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
