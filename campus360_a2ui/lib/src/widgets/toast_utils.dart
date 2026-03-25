import 'package:fluttertoast/fluttertoast.dart';

class Utility {
  static showToast({String? msg}) {
    Fluttertoast.showToast(
        msg: msg!, toastLength: Toast.LENGTH_LONG, timeInSecForIosWeb: 3);
  }
}
