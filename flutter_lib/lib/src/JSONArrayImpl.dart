import '../JSONObject.dart';
import '../JSONArray.dart';
import 'JSONObjectImpl.dart';
import 'dart:convert';
class JSONArrayImpl extends JSONArray {

  List<dynamic> _data;
  List<dynamic> get data {
    return _data;
  }
  void set data(List<dynamic> m) {
    _data = m;
  }

  String toString() {
    if (_data == null) return "null";
    return jsonEncode(_data);
  }

  JSONArrayImpl() {
    _data = new List<dynamic>();
  }

  JSONArrayImpl operator << (List<dynamic> a) {
    _data = a;
    if (_data == null) _data = new List<dynamic>();
    return this;
  }
  operator [](int i) => _data[i]; // get, direct but risky
  operator []=(int i, var value) => _data[i] = value; // set, direct but risky

  JSONArrayImpl optJSONArray(int i, dynamic defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null || !(v is List<dynamic>)) return defaultValue;
    JSONArrayImpl ja = new JSONArrayImpl();
    ja << v;
    return ja;
  }
  JSONObject optJSONObject(int i, JSONObject defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null || !(v is Map<String, dynamic>)) return defaultValue;
    JSONObject jo = new JSONObjectImpl();
    jo << v;
    return jo;
  }

  // shortcuts
  dynamic v(int i) {
    return vd(i, 0);
  }
  bool b(int i) {
    return bd(i, false);
  }
  double d(int i) {
    return dd(i, 0);
  }
  int i(int i) {
    return id(i, 0);
  }
  JSONArrayImpl a(int i) {
    return optJSONArray(i, new JSONArrayImpl());
  }
  JSONObject o(int i) {
    return optJSONObject(i, new JSONObjectImpl());
  }
  BigInt l(int i) {
    return ld(i, BigInt.zero);
  }
  String s(int i) {
    return sd(i, "");
  }

  // shortcuts with default
  dynamic vd(int i, var defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
	if (v == null) return defaultValue;
    return _data[i];
  }
  bool bd(int i, bool defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is String) {
        if (v.toUpperCase() == "TRUE") return true;
        if (v.toUpperCase() == "FALSE") return false;
        if (v == "1") return true;
        if (v == "0") return false;
        if (v == "") return false;
        return true;
    }
    if (v is int && v == 0) return false;
    return true;
  }
  double dd(int i, double defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null) return defaultValue;
    if (v is double) return v;
    try {
        return double.parse(v);
    } finally {
        return 0;
    }
  }
  int id(int i, int defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null) return defaultValue;
    if (v is int) return v;
    try {
        return int.parse(v);
    } finally {
        return 0;
    }
  }
  JSONArrayImpl ad(int i, dynamic defaultValue) {
    return optJSONArray(i, defaultValue);
  }
  JSONObject od(int i, JSONObject defaultValue) {
    return optJSONObject(i, defaultValue);
  }
  BigInt ld(int i, BigInt defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null) return defaultValue;
    if (v is BigInt) return v;
    try {
        return BigInt.parse(v);
    } finally {
        return BigInt.zero;
    }
  }
  String sd(int i, String defaultValue) {
    if (i < 0 || i >= _data.length) return defaultValue;
    var v = _data[i];
    if (v == null) return defaultValue;
    if (v is String) return v;
    return v.toString();
  }

  // put values, assign, if out of range, make it append
  JSONArrayImpl p(int i, var value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl bp(int i, bool value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl dp(int i, double value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl ip(int i, int value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl ap(int i, dynamic value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl op(int i, JSONObject value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl lp(int i, BigInt value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
  JSONArrayImpl sp(int i, String value) {
    if (i < 0 || i >= _data.length) _data.add(value);
    else _data[i] = value;
    return this;
  }
}