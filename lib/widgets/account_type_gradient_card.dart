import 'package:flutter/material.dart';

class AccountTypeGradientCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onClick;

  const AccountTypeGradientCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onClick,
    this.gradientStartColor = const Color(0xFF477DF6),
    this.gradientEndColor = const Color(0xFFA855F7),
    this.iconBackgroundColor = Colors.white,
    this.iconColor = const Color(0xFF477DF6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          colors: [gradientStartColor, gradientEndColor],
          tileMode: TileMode.clamp,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      width: MediaQuery.of(context).size.width,
      child: MaterialButton(
        onPressed: onClick,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: iconBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Icon(icon, color: iconColor)),
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}