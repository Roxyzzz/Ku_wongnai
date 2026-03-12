import 'package:flutter/material.dart';

/// Widget แสดง icon + ชื่อหมวดหมู่ (ทั้งหมด / ร้านอาหาร / คาเฟ่ / เครื่องดื่ม)
class CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.orange[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
