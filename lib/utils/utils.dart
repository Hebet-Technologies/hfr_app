import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class Utils{

  static void flushBar(String message, BuildContext context, String type){
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          message: message,
          duration: const Duration(seconds: 4),
          flushbarPosition: FlushbarPosition.TOP,
          backgroundColor:
          type == "success"?green:
          type == "warning"?orangeAccent:red,
          icon: type == "success"? Icon(Icons.done, color: white):
                type == "warning"? Icon(Icons.info, color: white):
                Icon(Icons.close, color: white)
        )..show(context)
    );
  }

  static void bottomSheet(BuildContext context, String title, dynamic data){
     showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        builder: (context) {
          return Wrap(
                children: [
                  Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 10, bottom: 14),
                        height: 5.0,
                        width: 50.0,
                        decoration: BoxDecoration(
                          color: grey,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(2.5),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const Divider(
                        thickness: 1,
                      )
                    ],
                  ),
                  data,
                  const SizedBox(height: 70,)
                ],
              );
        });
  }

  static Future<void> showAlertDialog({
    required BuildContext context,
    required VoidCallback onApprove,
    VoidCallback? onCancel,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String confirmButtonName,
    String? cancelButtonName
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child:Text(title)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                CircleAvatar(
                  backgroundColor: color,
                  radius: 22,
                  child: CircleAvatar(
                    backgroundColor: white,
                    radius: 20,
                    child: Icon(icon, color: color,),
                  ),
                ),
                const SizedBox(height: 15,),
                Text(message),
              ],
            ),
          ),
          actions:[
            TextButton(
              child: Text(confirmButtonName),
              onPressed: () {
                Navigator.of(context).pop();
                onApprove();
              },
            ),
            if(cancelButtonName != null || onCancel != null)
            TextButton(
              child: Text(cancelButtonName!),
              onPressed: () {
                Navigator.of(context).pop();
                onCancel!();
              },
            ),
          ],
        );
      },
    );
  }

  static InputDecoration getDecoration(
      {
        required String hintText,
        required String labelText,
        required Color decorationColor,
        IconData? prefixIcon,
        IconData? suffixIcon,
        VoidCallback? onPrefixClicked,
        VoidCallback? onSuffixClicked
      }
      ) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      labelStyle: TextStyle(color: decorationColor),
      hintStyle: TextStyle(color: decorationColor),
      prefixIcon: prefixIcon==null?null:GestureDetector(
        onTap: onPrefixClicked,
        child: Icon(prefixIcon, color: decorationColor)
      ),
      suffixIcon: suffixIcon==null?null: GestureDetector(
        onTap: onSuffixClicked,
        child: Icon(suffixIcon, color: decorationColor)
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: blue, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: blue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: red, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: red, width: 2.0),
      ),
    );
  }

  static void fieldFocusScope(BuildContext context, FocusNode currentFocus, FocusNode nextFocus){
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
}