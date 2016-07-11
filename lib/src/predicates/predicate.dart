library json_predicate.predicates;


abstract class Predicate{

  /// Mapping of opcodes to Predicate implementations as specified in
  /// https://tools.ietf.org/id/draft-snell-json-test-01.html
  ///
  static final PREDICATES = {
    'and' : (j) => new AndPredicate(j),
    'or' : (j) => new OrPredicate(j),
    'not' : (j) => new NotPredicate(j),

    'contains' : (j) => new ContainsPredicate(j),
    'defined' : (j) => new DefinedPredicate(j),
    'ends' : (j) => new EndsPredicate(j),
    'in' : (j) => new InPredicate(j),
    'less' : (j) => new LessPredicate(j),
    'matches' : (j) => new MatchesPredicate(j),
    'more' : (j) => new MorePredicate(j),
    'starts' : (j) => new StartsPredicate(j),
    'test' : (j) => new TestPredicate(j),
    'type' : (j) => new TypePredicate(j),
    'undefined' : (j) => new UndefinedPredicate(j)
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
  factory Predicate.fromJson(predicate){
    if(!predicate.containsKey("op"))
      throw new ArgumentError("Invalid predicate: $predicate");

    var type = predicate['op'];

    if(!PREDICATES.containsKey(type))
      throw new ArgumentError("Invalid predicate type: $type");

    return PREDICATES[type](predicate);
  }

  var _jsonPredicate;

  String get op;

  String get myPath{
    return _jsonPredicate['path'];
  }

  List<String> get requiredKeys;
  Predicate(this._jsonPredicate);



  List<bool> json(input, {fullPath: null});

  _validatePredicate(){
    if(_jsonPredicate['op'] != op)
      throw new ArgumentError("Invalid op: $op");

    for(var k in requiredKeys){
      if(!_jsonPredicate.containsKey(k)){
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

  SecondOrderPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    for(var subJsonPredicate in jsonPredicate['apply']){
      predicates.add(new Predicate.fromJson(subJsonPredicate));
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


  AndPredicate(var jsonPredicate) : super(jsonPredicate);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

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


  OrPredicate(var jsonPredicate) : super(jsonPredicate);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

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


  NotPredicate(var jsonPredicate) : super(jsonPredicate);

  @override
  List<bool> json(input, {fullPath: null}) {
    List<bool> result = super.json(input, fullPath: fullPath);

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

  ContainsPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is Pattern))
      throw new ArgumentError("Invalid value, Pattern (String) requested");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value.toString().contains(_jsonPredicate['value'])];
  }
}

class DefinedPredicate extends Predicate{

  String get op => "defined";
  List<String> get requiredKeys => ['path'];

  DefinedPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    return [v.isDefined];
  }
}

class EndsPredicate extends Predicate{

  String get op => "ends";
  List<String> get requiredKeys => ['path', 'value'];

  EndsPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is Pattern))
      throw new ArgumentError("Invalid value, Pattern (String) requested");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value.toString().endsWith(_jsonPredicate['value'])];
  }
}

class InPredicate extends Predicate{

  String get op => "in";
  List<String> get requiredKeys => ['path', 'value'];

  InPredicate(var jsonPredicate) : super(jsonPredicate){
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
    return [jsonValue.contains(v.value)];
  }
}

class LessPredicate extends Predicate{

  String get op => "less";
  List<String> get requiredKeys => ['path', 'value'];

  LessPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is num))
      throw new ArgumentError("LessPredicate expects value of number type");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value < _jsonPredicate['value']];
  }
}

class MatchesPredicate extends Predicate{

  String get op => "matches";
  List<String> get requiredKeys => ['path', 'value'];
  var regex;

  MatchesPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    regex = new RegExp(_jsonPredicate['value'].toString());
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [regex.allMatches(v.value.toString()).length > 0];
  }
}

class MorePredicate extends Predicate{

  String get op => "more";
  List<String> get requiredKeys => ['path', 'value'];

  MorePredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();

    if(!(_jsonPredicate['value'] is num))
      throw new ArgumentError("LessPredicate expects value of number type");
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value > _jsonPredicate['value']];
  }
}

class StartsPredicate extends Predicate{

  String get op => "starts";
  List<String> get requiredKeys => ['path', 'value'];

  StartsPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value.toString().startsWith(_jsonPredicate['value'])];
  }
}

class TestPredicate extends Predicate{

  String get op => "test";
  List<String> get requiredKeys => ['path', 'value'];

  TestPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.value == _jsonPredicate['value']];
  }
}

class TypePredicate extends Predicate{

  String get op => "type";
  List<String> get requiredKeys => ['path', 'value'];

  TypePredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    if(!v.isDefined)
      return [false];

    return [v.type == _jsonPredicate['value']];
  }
}

class UndefinedPredicate extends Predicate{

  String get op => "undefined";
  List<String> get requiredKeys => ['path'];

  UndefinedPredicate(var jsonPredicate) : super(jsonPredicate){
    _validatePredicate();
  }

  @override
  List<bool> json(input, {fullPath: null}) {
    JSONValue v = _getJSONValueByPath(input, (fullPath == null?"":fullPath) + myPath);

    return [!v.isDefined];
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
}