import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final BuildContext buildContext;
  const CustomBackButton({super.key, required this.buildContext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 30,
        width: 30,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: Offset(2, 2),
              blurRadius: 5,
              spreadRadius: 1
            )
          ]
        ),
        child: MaterialButton(
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(Icons.arrow_back, color: Colors.grey, size: 18,),
          ),
        ),
      ),
    );
  }
}
