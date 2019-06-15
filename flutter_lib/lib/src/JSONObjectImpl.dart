import '../JSONArray.dart';
import '../JSONObject.dart';
import 'JSONArrayImpl.dart';
import 'dart:convert';

class JSONObjectImpl extends JSONObject {

  Map<String, dynamic> _data;
  Map<String, dynamic> get data {
    return _data;
  }
  void set data(Map<String, dynamic> m) {
    _data = m;
  }

  String toString() {
    if (_data == null) return "null";
    return jsonEncode(_data);
  }

  JSONObjectImpl() {
    _data = new Map<String, dynamic>();
  }

  JSONObjectImpl operator <<(Map<String, dynamic> o) {
    _data = o;
    if (_data == null) _data = new Map<String, dynamic>();
    return this;
  }
  operator [](String name) => _data[name]; // get, direct but risky 
  operator []=(String name, var value) => _data[name] = value; // set, direct but risky

  JSONArray optJSONArray(String name, JSONArray defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null || !(v is List<dynamic>)) return defaultValue;
    JSONArray ja = new JSONArrayImpl();
    ja << v;
    return ja;
  }

  JSONObjectImpl optJSONObject(String name, dynamic defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null || !(v is Map<String, dynamic>)) return defaultValue;
    JSONObjectImpl jo = new JSONObjectImpl();
    jo << v;
    return jo;
  }

  // shortcuts
  dynamic v(String name) {
    return vd(name, 0);
  }
  bool b(String name) {
    return bd(name, false);
  }
  double d(String name) {
    return dd(name, 0);
  }
  int i(String name) {
    return id(name, 0);
  }
  JSONArray a(String name) {
    return optJSONArray(name, new JSONArrayImpl());
  }
  JSONObjectImpl o(String name) {
    return optJSONObject(name, new JSONObjectImpl());
  }
  BigInt l(String name) {
    return ld(name, BigInt.zero);
  }
  String s(String name) {
    return sd(name, "");
  }

  // shortcuts with default
  dynamic vd(String name, var defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null) return defaultValue;
    return v;
  }
  bool bd(String name, bool defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
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
  double dd(String name, double defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null) return defaultValue;
	if (v is double) return v;
	try {
		return double.parse(v);
	} finally {
		return 0;
	}
  }
  int id(String name, int defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null) return defaultValue;
	if (v is int) return v;
    try {
        return int.parse(v);
    } finally {
        return 0;
    }
  }
  JSONArray ad(String name, JSONArray defaultValue) {
    return optJSONArray(name, defaultValue);
  }
  JSONObjectImpl od(String name, dynamic defaultValue) {
    return optJSONObject(name, defaultValue);
  }
  BigInt ld(String name, BigInt defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null) return defaultValue;
	if (v is BigInt) return v;
    try {
        return BigInt.parse(v);
    } finally {
        return BigInt.zero;
    }
  }
  String sd(String name, String defaultValue) {
    if (name == null || name == "") return defaultValue;
    var v = _data[name];
    if (v == null) return defaultValue;
	if (v is String) return v;
    return v.toString();
  }

  // put values, assign
  JSONObjectImpl p(String name, var value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl bp(String name, bool value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl dp(String name, double value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl ip(String name, int value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl ap(String name, JSONArray value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl op(String name, dynamic value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl lp(String name, BigInt value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
  JSONObjectImpl sp(String name, String value) {
    if (name == null || name == "") name = "undefined";
    _data[name] = value;
    return this;
  }
}