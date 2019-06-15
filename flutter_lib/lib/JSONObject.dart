import 'JSONArray.dart';
import 'src/JSONObjectImpl.dart';
import 'dart:convert';
/// safe JSON object read/write
abstract class JSONObject {

  /// getter/setter of member Map data
  Map<String, dynamic> get data;
  void set data(Map<String, dynamic> m);

  /// parse JSON string to JSONObject
  static JSONObject parse(String json) {
    JSONObject jo = new JSONObjectImpl();
    jo["data"] = jsonDecode(json);
    if (jo["data"] == null) jo["data"] = new Map<String, dynamic>();
    return jo;
  }

  /// create a new instance
  static JSONObject jo() {
    return new JSONObjectImpl();
  }

  /// operators, to convert List to JSONArray
  JSONObject operator <<(Map<String, dynamic> o);

  /// get/set, direct but risky
  operator [](String name);
  operator []=(String name, var value);

  /// to get/coerce value of field
  JSONArray optJSONArray(String name, JSONArray defaultValue);
  JSONObject optJSONObject(String name, JSONObject defaultValue);

  /// shortcuts, to get/coerce value of field
  dynamic v(String name);
  bool b(String name);
  double d(String name);
  int i(String name);
  JSONArray a(String name);
  JSONObject o(String name);
  BigInt l(String name);
  String s(String name);

  /// shortcuts with default value supplied
  dynamic vd(String name, var defaultValue);
  bool bd(String name, bool defaultValue);
  double dd(String name, double defaultValue);
  int id(String name, int defaultValue);
  JSONArray ad(String name, JSONArray defaultValue);
  JSONObject od(String name, JSONObject defaultValue);
  BigInt ld(String name, BigInt defaultValue);
  String sd(String name, String defaultValue);

  /// put values, assign
  JSONObject p(String name, var value);
  JSONObject bp(String name, bool value);
  JSONObject dp(String name, double value);
  JSONObject ip(String name, int value);
  JSONObject ap(String name, JSONArray value);
  JSONObject op(String name, JSONObject value);
  JSONObject lp(String name, BigInt value);
  JSONObject sp(String name, String value);
}