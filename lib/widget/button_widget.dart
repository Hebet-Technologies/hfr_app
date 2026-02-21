import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
   ButtonWidget(
      {
        Key? key,
        required this.title,
        required this.color,
        required this.textColor,
        required this.onPressed,
        this.isLoading = false
      }
      ):super(key: key);
  
  final String? title;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final VoidCallback onPressed;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15.0), // Add border radius here
        ),
        child: Center(
          child: isLoading? CircularProgressIndicator(color:textColor,)
              :Text(
                title.toString(),
                style: TextStyle(fontSize: 20, color: textColor),
              ),
        ),
      ),
    );
  }
}
