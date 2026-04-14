import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class CustomButtonOne extends StatelessWidget {
  final String title;
  final Color? bg;
  final VoidCallback onClick;
  final bool? hasIcon;
  final bool isLoading;
  final bool? isOutlined;
  final Color? textColor;

  const CustomButtonOne({super.key, required this.title, this.bg, required this.onClick, this.hasIcon, required this.isLoading, this.textColor, this.isOutlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: MediaQuery.of(context).size.width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isOutlined == true ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(10),
        border: isOutlined == true ? Border.all(width: 1.5, color: Colors.grey.withOpacity(0.3)) : null
      ),
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: onClick,
        child: isLoading ? CupertinoActivityIndicator(
          color: Colors.white,
        ) : hasIcon == true ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.white
          ),),
          const SizedBox(width: 5,),
          Icon(Icons.arrow_right_alt_rounded, color: textColor ?? Colors.white,)
        ],
      ) : Center(
        child: Text(title, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.white
        ),),
      ),),
    );
  }
}
