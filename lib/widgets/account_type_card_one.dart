import 'package:flutter/material.dart';

class AccountTypeCardOne extends StatelessWidget {
  final String headTe;
  final String subText;
  final Color textColor;
  final Color textColor2;
  final Color containerColor;
  final Color iconColor;
  final Color shadowColor;
  final Color smallConColor;
  final Icon icon;
  final double? height;
  final VoidCallback onClick;

  const AccountTypeCardOne({
    super.key,
    required this.headTe,
    required this.subText,
    required this.textColor,
    required this.textColor2,
    required this.containerColor,
    required this.iconColor,
    required this.shadowColor,
    required this.smallConColor,
    required this.icon,
    required this.height,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        color: containerColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: MaterialButton(
        onPressed: onClick,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: smallConColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: icon),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headTe,
                            style: TextStyle(
                              color: textColor2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            subText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    //SizedBox(width: 40,),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 15, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
