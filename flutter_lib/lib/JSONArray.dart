import 'JSONObject.dart';
import 'src/JSONArrayImpl.dart';
import 'dart:convert';
/// safe JSON array read/write
abstract class JSONArray {

  /// getter/setter of member List data
  List<dynamic> get data;
  void set data(List<dynamic> m);

  /// parse JSON string to JSONArray
  static JSONArray parse(String json) {
    JSONArrayImpl ja = new JSONArrayImpl();
    ja.data = jsonDecode(json);
    if (ja.data == null) ja.data = new List<dynamic>();
    return ja;
  }

  /// create a new instance
  static JSONArray ja() {
    return new JSONArrayImpl();
  }

  /// operators, to convert List to JSONArray
  JSONArray operator << (List<dynamic> a);
  
  /// get/set, direct but risky
  operator [](int i);
  operator []=(int i, var value); 

  /// to get/coerce value of field
  JSONArray optJSONArray(int i, JSONArray defaultValue);
  JSONObject optJSONObject(int i, JSONObject defaultValue);

  /// shortcuts, to get/coerce value of field
  dynamic v(int i);
  bool b(int i);
  double d(int i);
  int i(int i);
  JSONArray a(int i);
  JSONObject o(int i);
  BigInt l(int i);
  String s(int i);

  /// shortcuts with default value supplied
  dynamic vd(int i, var defaultValue);
  bool bd(int i, bool defaultValue);
  double dd(int i, double defaultValue);
  int id(int i, int defaultValue);
  JSONArray ad(int i, JSONArray defaultValue);
  JSONObject od(int i, JSONObject defaultValue);
  BigInt ld(int i, BigInt defaultValue);
  String sd(int i, String defaultValue);

  /// put values, assign, if out of range, make it append
  JSONArray p(int i, var value);
  JSONArray bp(int i, bool value);
  JSONArray dp(int i, double value);
  JSONArray ip(int i, int value);
  JSONArray ap(int i, JSONArray value);
  JSONArray op(int i, JSONObject value);
  JSONArray lp(int i, BigInt value);
  JSONArray sp(int i, String value);
}