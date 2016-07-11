# dart_json_predicate

A library for Dart which implements the JSON Predicate proposal: https://tools.ietf.org/id/draft-snell-json-test-01.html
## Usage

A simple usage example:

    import 'package:dart_json_predicate/json_predicate.dart' as jpredicate;

    var testDocument = {
      "level1_0" : "This is a string value",
      "level1_1" : 5,
      "level1_2" : -3,
      "level1_3" : 3.2,
      "level1_4" : -2.2,
      "level1_5" : "2012-04-23T18:25:43.511Z",
      "level1_6" : ["Test 123", "abcdef"],
      "level1_7" : [5,6,7,8,9]
    };

    main() {
      var result = jpredicate.json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_0',
        'value' : '[\\w\\s]*'
      });
    
      print(result);
    }

Take a look at the test cases for more examples.

## Features
All operators as specified in the proposal are available.
Currently there is only support for the datatypes: string, number, boolean, array and undefined.

