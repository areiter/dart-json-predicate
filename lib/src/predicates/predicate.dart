library json_predicate.predicates;

import 'package:logging/logging.dart';

Logger log = new Logger("json-predicate");


abstract class Predicate{

  /// Mapping of opcodes to Predicate implementations as specified in
  /// https://tools.ietf.org/id/draft-snell-json-test-01.html
  ///
  static final PREDICATES = {
    'and' : (j, d) => new AndPredicate(j, d: d),
    'or' : (j, d) => new OrPredicate(j, d: d),
    'not' : (j, d) => new NotPredicate(j, d: d),

    'contains' : (j, d) => new ContainsPredicate(j, d: d),
    'defined' : (j, d) => new DefinedPredicate(j, d: d),
    'ends' : (j, d) => new EndsPredicate(j, d: d),
    'in' : (j, d) => new InPredicate(j, d: d),
    'less' : (j, d) => new LessPredicate(j, d: d),
    'matches' : (j, d) => new MatchesPredicate(j, d: d),
    'more' : (j, d) => new MorePredicate(j, d: d),
    'starts' : (j, d) => new StartsPredicate(j, d: d),
    'test' : (j, d) => new TestPredicate(j, d: d),
    'type' : (j, d) => new TypePredicate(j, d: d),
    'undefined' : (j, d) => new UndefinedPredicate(j, d: d)
  };

  /// Instantiate Predicate for the given predicate specification in the form
  /// {
  /// "op": "and",
  /// "apply" : [
  ///   {
  ///   "op": "defined",
  ///   "path": "/a/b"
  ///   },
  ///   {
  ///   "op": "less",
  ///   "path": "/a/c/d",
  ///   "value": 15
  ///   }
  ///   ]
  /// }
  factory Predicate.fromJson(predicate, {debug: false}){
    if(!predicate.containsKey("op"))
      throw new ArgumentError("Invalid predicate: $predicate");

    var type = predicate['op'];

    if(!PREDICATES.containsKey(type))
      throw new ArgumentError("Invalid predicate type: $type");

    return PREDICATES[type](predicate, debug);
  }

  var _jsonPredicate;
  var debug;

  String get op;

  String get myPath{
    return _jsonPredicate['path'];
  }

  List<String> get requiredKeys;
  Predicate(this._jsonPredicate, {this.debug: false});



  List<bool> json(input, {fullPath: null});

  _validatePredicate(){
    if(_jsonPredicate['op'] != op) {
      if (debug)
        log.severe("Invalid 'op': '${_jsonPredicate['op']}' expected '$op'");

      throw new ArgumentError("Invalid op: $op");
    }

    for(var k in requiredKeys){
      if(!_jsonPredicate.containsKey(k)){
        if (debug)
          log.severe("Mssing parameter: '$k");

        throw new ArgumentError("Missing parameter: $k");
      }
    }
  }

  _getJSONValueByPath(input, String path){
    List sPath = path.split('/');

    var currentRoot = input;
    for(var p in sPath){
      if(p == null || p == "")
        continue;

      if(!(currentRoot is Map))
        return new JSONValue(isDefined: false);

      if(!currentRoot.containsKey(p))
        return new JSONValue(isDefined: false);

      currentRoot = currentRoot[p];
    }

    return new JSONValue(isDefined: true, value: currentRoot);
  }
}

abstract class SecondOrderPredicate extends Predicate{

  List<String> get requiredKeys => ['apply'];

  List<Predicate> predicates = [];

  SecondOrderPredicate(var jsonPredicate, {debug: false}) : super(jsonPredicate, debug: debug){
    _validatePredicate();

    for(var subJsonPredicate in jsonPredicate['apply']){
      predicates.add(new Predicate.fromJson(subJsonPredicate, debug: debug));
    }
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = [];

    String currentPath = null;
    if(_jsonPredicate.containsKey("path"))
      currentPath = _jsonPredicate["path"];

    if(fullPath == null && currentPath != null)
      fullPath = currentPath;
    else if(fullPath != null && currentPath != null)
      fullPath += currentPath;

    for(Predicate p in predicates){
      result.addAll(p.json(input, fullPath: fullPath));
    }

    return result;
  }
}

class AndPredicate extends SecondOrderPredicate{

  @override
  String get op => "and";


  AndPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

    if (debug)
      log.finest("[and] Received results $result: $_jsonPredicate");

    for(bool r in result){
      if(!r) {
        return [false];
      }
    }

    return [true];
  }
}

class OrPredicate extends SecondOrderPredicate{

  @override
  String get op => "or";


  OrPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

    if (debug)
      log.finest("[or] Received results $result: $_jsonPredicate");

    for(bool r in result){
      if(r) {
        return [true];
      }
    }

    return [false];
  }
}

class NotPredicate extends SecondOrderPredicate{

  @override
  String get op => "not";


  NotPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

    if (debug)
      log.finest("[not] Received results $result: $_jsonPredicate");

    for(bool r in result){
      if(r) {
        return [false];
      }
    }

    return [true];
  }
}

class ContainsPredicate extends Predicate{

  String get op => "contains";
  List<String> get requiredKeys => ['path', 'value'];

  ContainsPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is Pattern))
      throw new ArgumentError("Invalid value, Pattern (String) requested");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined) {
      if (debug)
        log.finest("[contains] node '${(fullPath == null?"":fullPath) + myPath}' undefined in input");
      return [false];
    }

    var result = [v.value.toString().contains(_jsonPredicate['value'])];

    if (debug)
      log.finest("[contains] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class DefinedPredicate extends Predicate{

  String get op => "defined";
  List<String> get requiredKeys => ['path'];

  DefinedPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    var result = [v.isDefined];

    if (debug)
      log.finest("[defined] result '$result' for $_jsonPredicate");

    return result;
  }
}

class EndsPredicate extends Predicate{

  String get op => "ends";
  List<String> get requiredKeys => ['path', 'value'];

  EndsPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is Pattern))
      throw new ArgumentError("Invalid value, Pattern (String) requested");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.value.toString().endsWith(_jsonPredicate['value'])];

    if (debug)
      log.finest("[ends] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class InPredicate extends Predicate{

  String get op => "in";
  List<String> get requiredKeys => ['path', 'value'];

  InPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is List))
      throw new ArgumentError('Invalue value, expected array');
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    List jsonValue = _jsonPredicate['value'];
    var result = [jsonValue.contains(v.value)];

    if (debug)
      log.finest("[in] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class LessPredicate extends Predicate{

  String get op => "less";
  List<String> get requiredKeys => ['path', 'value'];

  LessPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is num))
      throw new ArgumentError("LessPredicate expects value of number type");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.value < _jsonPredicate['value']];

    if (debug)
      log.finest("[less] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class MatchesPredicate extends Predicate{

  String get op => "matches";
  List<String> get requiredKeys => ['path', 'value'];
  var regex;

  MatchesPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    regex = new RegExp(_jsonPredicate['value'].toString());
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [regex.allMatches(v.value.toString()).length > 0];

    if (debug)
      log.finest("[matches] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class MorePredicate extends Predicate{

  String get op => "more";
  List<String> get requiredKeys => ['path', 'value'];

  MorePredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is num))
      throw new ArgumentError("LessPredicate expects value of number type");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.value > _jsonPredicate['value']];

    if (debug)
      log.finest("[more] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class StartsPredicate extends Predicate{

  String get op => "starts";
  List<String> get requiredKeys => ['path', 'value'];

  StartsPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.value.toString().startsWith(_jsonPredicate['value'])];

    if (debug)
      log.finest("[starts] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class TestPredicate extends Predicate{

  String get op => "test";
  List<String> get requiredKeys => ['path', 'value'];

  TestPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.value == _jsonPredicate['value']];

    if (debug)
      log.finest("[test] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class TypePredicate extends Predicate{

  String get op => "type";
  List<String> get requiredKeys => ['path', 'value'];

  TypePredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    var result = [v.type == _jsonPredicate['value']];

    if (debug)
      log.finest("[type] result '$result' on value ${v} for $_jsonPredicate");

    return result;
  }
}

class UndefinedPredicate extends Predicate{

  String get op => "undefined";
  List<String> get requiredKeys => ['path'];

  UndefinedPredicate(var jsonPredicate, {d: false}) : super(jsonPredicate, debug: d){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    var result = [!v.isDefined];

    if (debug)
      log.finest("[undefined] result '$result' for $_jsonPredicate");

    return result;
  }
}

class JSONValue {
  bool isDefined;
  var value;

  JSONValue({this.isDefined: true, this.value: null});

  String get type {
    // No mapping for 'date', 'time', 'lang', 'lang-range', 'iri', 'absolute-iri'
    if(!isDefined){
      return "undefined";
    } else if(value == null) {
      return "null";
    } else if(value is String){
      return "string";
    } else if(value is num){
      return "number";
    } else if(value is bool){
      return "boolean";
    } else if(value is Map){
      return "object";
    } else if(value is List){
      return "array";
    } else if(value is DateTime){
      return "date-time";
    } else {
      return "object";
    }

  }

  String toString() => "[$type - $value]";
}