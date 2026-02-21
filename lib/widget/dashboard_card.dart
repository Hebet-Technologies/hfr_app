import 'package:flutter/material.dart';
import 'package:shaky_animated_listview/animators/grid_animator.dart';
import '../utils/text_styles.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.count, required this.title, required this.onPressed});

  final int count;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GridAnimatorWidget(
      child: GestureDetector(
          onTap: ()=>onPressed,
          child: Card(
              elevation: 10,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Text(title, style: cardTextStyle,textAlign: TextAlign.center),
                  const SizedBox(height: 5,),
                  Text(count.toString(), style: cardCountStyle,textAlign: TextAlign.center),
                ],
            ),
          )),
    );
  }
}
