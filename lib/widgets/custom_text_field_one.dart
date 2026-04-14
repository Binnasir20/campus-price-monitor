import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';



class CustomTextFieldOne extends StatelessWidget {
  final String? labelText;
  final String hintText;
  final Icon? icon;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final bool isContainer;

  const CustomTextFieldOne({
    super.key,
    this.labelText,
    required this.hintText,
    this.icon,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines,
    this.prefixIcon,
    this.isContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null && labelText!.isNotEmpty) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  minLines: 1,
                  maxLines: maxLines ?? 1,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: icon,
                    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: Colors.grey, size: 20),
                    hintText: hintText,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: isContainer == false ? BorderRadius.circular(10) : BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10)
                      ),
                      borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.10), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: isContainer == false ? BorderRadius.circular(10) : BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10)
                      ),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.10), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: isContainer == false ? BorderRadius.circular(10) : BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10)
                      )
    ,
                      borderSide: BorderSide(
                          color: isContainer == false ? Colors.red : Colors.grey.withOpacity(0.10), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            if(isContainer)
            Container(
              height: 47,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  topRight: Radius.circular(10)
                ),
              ),
              child: Center(
                child: IconButton(onPressed: (){},
                    icon: Icon(
                    IconlyBold.filter_2,color: Colors.white,size: 18,)),
              ),
            )
          ],
        )

      ],
    );
  }
}