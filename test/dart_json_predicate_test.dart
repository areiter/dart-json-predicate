// Copyright (c) 2016, Andreas Reiter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_json_predicate/json_predicate.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('[${rec.loggerName}] ${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  var testDocument = {
    "level1_0" : "This 123 is a string value",
    "level1_1" : 5,
    "level1_2" : -3,
    "level1_3" : 3.2,
    "level1_4" : -2.2,
    "level1_5" : "2012-04-23T18:25:43.511Z",
    "level1_6" : ["Test 123", "abcdef"],
    "level1_7" : [5,6,7,8,9],
    "level1_8" : null,
    "level1_9" : true,

    "level1_c0" : {
      "level2c0_0" : "This is a string value",
      "level2c0_1" : 5,
      "level2c0_2" : -3,
      "level2c0_3" : 3.2,
      "level2c0_4" : -2.2,
      "level2c0_5" : "2012-04-23T18:25:43.511Z",
      "level2c0_6" : ["Test 123", "abcdef"],
      "level2c0_7" : [5,6,7,8,9],
    },

    "level1_c1" : {
      "level2c1_0" : {
        "level3c10" :{
          "level4c0_0" : "This 123 is another string value",
          "level4c0_1" : 5,
          "level4c0_2" : -3,
          "level4c0_3" : 3.2,
          "level4c0_4" : -2.2,
          "level4c0_5" : "2013-04-23T18:25:43.511Z",
          "level4c0_6" : ["Test 123", "abcdef"],
          "level4c0_7" : [5,6,7,8,9]
        }
      }
    }
  };


  group('Nested predicates evaluation tests', () {
    setUp(() {});

    test('Nested predicates success , no paths', () {
      var result = json(testDocument,{
        'op' : 'and',
        'apply' : [
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 6
          },
          {
            'op' : 'less',
            'path' : '/level1_2',
            'value' : 5
          },
          {
            'op' : 'not',
            'apply' : [
              {
                'op' : 'more',
                'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
                'value' : 6
              },
              {
                'op' : 'more',
                'path' : '/level1_c1/level2c1_0/level3c10/level4c0_4',
                'value' : 2
              },
            ]
          }
        ]
      });
      expect(result, true);
    });

    test('Nested predicates no success , no paths', () {
      var result = json(testDocument,{
        'op' : 'and',
        'apply' : [
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 6
          },
          {
            'op' : 'less',
            'path' : '/level1_2',
            'value' : 5
          },
          {
            'op' : 'not',
            'apply' : [
              {
                'op' : 'more',
                'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
                'value' : 6
              },
              {
                'op' : 'more',
                'path' : '/level1_c1/level2c1_0/level3c10/level4c0_4',
                'value' : -4
              },
            ]
          }
        ]
      }, debug: true);
      expect(result, false);
    });

    test('Nested predicates success , nested paths', () {
      var result = json(testDocument,{
        'op' : 'and',
        'apply' : [
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 6
          },
          {
            'op' : 'less',
            'path' : '/level1_2',
            'value' : 5
          },
          {
            'op' : 'not',
            'path' : '/level1_c1/level2c1_0/level3c10',
            'apply' : [
              {
                'op' : 'more',
                'path' : '/level4c0_1',
                'value' : 6
              },
              {
                'op' : 'more',
                'path' : '/level4c0_4',
                'value' : 2
              },
            ]
          }
        ]
      }, debug: true);
      expect(result, true);
    });

    test('Nested predicates no success , nested paths', () {
      var result = json(testDocument,{
        'op' : 'and',
        'apply' : [
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 6
          },
          {
            'op' : 'less',
            'path' : '/level1_2',
            'value' : 5
          },
          {
            'op' : 'not',
            'path' : '/level1_c1/level2c1_0/level3c10',
            'apply' : [
              {
                'op' : 'more',
                'path' : '/level4c0_1',
                'value' : 6
              },
              {
                'op' : 'more',
                'path' : '/level4c0_4',
                'value' : -3
              },
            ]
          }
        ]
      }, debug: true);
      expect(result, false);
    });
  });


  group('AndPredicate evaluation tests', () {
    setUp(() {});

    test('And success', () {
      var result = json(testDocument, {
        'op' : 'and',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 10
          }
        ]
      }, debug: true);
      expect(result, true);
    });

    test('And no success', () {
      var result = json(testDocument, {
        'op' : 'and',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 3
          }
        ]
      }, debug: true);
      expect(result, false);
    });
  });

  group('NotPredicate evaluation tests', () {
    setUp(() {});

    test('Not success', () {
      var result = json(testDocument, {
        'op' : 'not',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string no matching'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 3
          }
        ]
      }, debug: true);
      expect(result, true);
    });

    test('Not no success', () {
      var result = json(testDocument, {
        'op' : 'and',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 3
          }
        ]
      }, debug: true);
      expect(result, false);
    });
  });

  group('OrPredicate evaluation tests', () {
    setUp(() {});

    test('Or success', () {
      var result = json(testDocument, {
        'op' : 'or',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 3
          }
        ]
      }, debug: true);
      expect(result, true);
    });

    test('Or no success', () {
      var result = json(testDocument, {
        'op' : 'or',
        'apply' : [
          {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string no matching'
          },
          {
            'op' : 'less',
            'path' : '/level1_1',
            'value' : 3
          }
        ]
      }, debug: true);
      expect(result, false);
    });
  });


  group('ContainsPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
            'op' : 'contains',
            'path' : '/level1_0',
            'value' : 'a string'
          }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'contains',
        'path' : '/level1_0_undefined',
        'value' : 'a string'
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'contains',
        'path' : '/level1_0',
        'value' : 'a not matching string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'contains',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another string'
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'contains',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'contains',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });
  });

  group('MatchesPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_0',
        'value' : '[\\w\\s]*'
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_0_undefined',
        'value' : '^[\\w\\s]*\$'
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_0',
        'value' : '^[\\s[A-Z][a-z]]*\$'
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : '^[\\w\\s]*\$'
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : '^[0-9]*\$'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'matches',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : '[\\w\\s]*'
      }, debug: true);
      expect(result, false);
    });
  });

  group('EndsPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_0',
        'value' : 'a string value'
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_0_undefined',
        'value' : 'a string value'
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_0',
        'value' : 'a not matching string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another string value'
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });
  });

  group('TestPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
        'op' : 'test',
        'path' : '/level1_0',
        'value' : 'This 123 is a string value'
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'test',
        'path' : '/level1_0_undefined',
        'value' : 'a string value'
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'test',
        'path' : '/level1_0',
        'value' : 'a not matching string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'test',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'This 123 is another string value'
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'ends',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });
  });

  group('TypePredicate evaluation tests', () {
    setUp(() {});

    test('Root string', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_0',
        'value' : 'string'
      }, debug: true);
      expect(result, true);
    });

    test('Root num', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_1',
        'value' : 'number'
      }, debug: true);
      expect(result, true);
    });

    test('Root num 2', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_3',
        'value' : 'number'
      }, debug: true);
      expect(result, true);
    });

    test('Root null', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_8',
        'value' : 'null'
      }, debug: true);
      expect(result, true);
    });

    test('Root boolean', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_9',
        'value' : 'boolean'
      }, debug: true);
      expect(result, true);
    });

    test('Root array', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_6',
        'value' : 'array'
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'type',
        'path' : '/level1_0_undefined',
        'value' : 'string'
      }, debug: true);
      expect(result, false);
    });
  });

  group('StartsPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_0',
        'value' : 'This 123 is'
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_0_undefined',
        'value' : 'a string value'
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_0',
        'value' : 'a not matching string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'This 123 is another'
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'starts',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 'another unmatched string'
      }, debug: true);
      expect(result, false);
    });
  });

  group('DefinedPredicate evaluation tests', () {
    setUp(() {});

    test('Root node defined', () {
      var result = json(testDocument, {
        'op' : 'defined',
        'path' : '/level1_0'
      }, debug: true);
      expect(result, true);
    });

    test('Root node imdefined', () {
      var result = json(testDocument, {
        'op' : 'defined',
        'path' : '/level1_undefined_0'
      }, debug: true);
      expect(result, false);
    });

    test('Deep node defined', () {
      var result = json(testDocument, {
        'op' : 'defined',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
      }, debug: true);
      expect(result, true);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'defined',
        'path' : '/level1_c1/level2c1_0/level3_undefined_c10/level4c0_0'
      }, debug: true);
      expect(result, false);
    });
  });

  group('UndefinedPredicate evaluation tests', () {
    setUp(() {});

    test('Root node defined', () {
      var result = json(testDocument, {
        'op' : 'undefined',
        'path' : '/level1_0'
      }, debug: true);
      expect(result, false);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'undefined',
        'path' : '/level1_undefined_0'
      }, debug: true);
      expect(result, true);
    });

    test('Deep node defined', () {
      var result = json(testDocument, {
        'op' : 'undefined',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_0',
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'undefined',
        'path' : '/level1_c1/level2c1_0/level3_undefined_c10/level4c0_0'
      }, debug: true);
      expect(result, true);
    });

    test('Null node defined', () {
      var result = json(testDocument, {
        'op' : 'undefined',
        'path' : '/level1_c8'
      }, debug: true);
      expect(result, true);
    });
  });


  group('InPredicate evaluation tests', () {
    setUp(() {});

    test('Root match', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_0',
        'value' : [1, 2, 3, 1.1, 'string value', 'This 123 is a string value']
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_0_undefined',
        'value' : [1, 2, 3, 1.1, 'string value', 'This is a string value']
      }, debug: true);
      expect(result, false);
    });

    test('Root no match', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_0',
        'value' : [1, 2, 3, 'a not matching string']
      }, debug: true);
      expect(result, false);
    });

    test('Deep match', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : [1, 2, 3, 'a not matching string', 5, 4]
      }, debug: true);
      expect(result, true);
    });

    test('Deep no match', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : [1, 2, 3, 'a not matching string', 4]
      }, debug: true);
      expect(result, false);
    });

    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'in',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : [1, 2, 3, 'a not matching string', 4]
      }, debug: true);
      expect(result, false);
    });
  });

  group('LessPredicate evaluation tests', () {
    setUp(() {});

    test('Root positive true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_1',
        'value' : 10
      }, debug: true);
      expect(result, true);
    });

    test('Root positive false', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_1',
        'value' : 4
      }, debug: true);
      expect(result, false);
    });

    test('Root negative true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_2',
        'value' : -2
      }, debug: true);
      expect(result, true);
    });

    test('Root negative false', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_2',
        'value' : -4
      }, debug: true);
      expect(result, false);
    });

    test('Root compare num to float true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_3',
        'value' : 4
      }, debug: true);
      expect(result, true);
    });

    test('Root compare num to float false', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_3',
        'value' : 3
      }, debug: true);
      expect(result, false);
    });

    test('Root compare float to num true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_1',
        'value' : 5.1
      }, debug: true);
      expect(result, true);
    });

    test('Root compare float to num true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_1',
        'value' : 4.9
      }, debug: true);
      expect(result, false);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_0_undefined',
        'value' : 10
      }, debug: true);
      expect(result, false);
    });

    test('Deep positive true', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : 6
      }, debug: true);
      expect(result, true);
    });

    test('Deep positive false', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : 4
      }, debug: true);
      expect(result, false);
    });


    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 10
      }, debug: true);
      expect(result, false);
    });
  });

  group('MorePredicate evaluation tests', () {
    setUp(() {});

    test('Root positive false', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_1',
        'value' : 10
      }, debug: true);
      expect(result, false);
    });

    test('Root positive true', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_1',
        'value' : 4
      }, debug: true);
      expect(result, true);
    });

    test('Root negative false', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_2',
        'value' : -2
      }, debug: true);
      expect(result, false);
    });

    test('Root negative true', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_2',
        'value' : -4
      }, debug: true);
      expect(result, true);
    });

    test('Root compare num to float false', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_3',
        'value' : 4
      }, debug: true);
      expect(result, false);
    });

    test('Root compare num to float true', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_3',
        'value' : 3
      }, debug: true);
      expect(result, true);
    });

    test('Root compare float to num false', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_1',
        'value' : 5.1
      }, debug: true);
      expect(result, false);
    });

    test('Root compare float to num true', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_1',
        'value' : 4.9
      }, debug: true);
      expect(result, true);
    });

    test('Root node undefined', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_0_undefined',
        'value' : 10
      }, debug: true);
      expect(result, false);
    });

    test('Deep positive false', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : 6
      }, debug: true);
      expect(result, false);
    });

    test('Deep positive true', () {
      var result = json(testDocument, {
        'op' : 'more',
        'path' : '/level1_c1/level2c1_0/level3c10/level4c0_1',
        'value' : 4
      }, debug: true);
      expect(result, true);
    });


    test('Deep node undefined', () {
      var result = json(testDocument, {
        'op' : 'less',
        'path' : '/level1_c1/level2c1_0/level3c_undefined_10/level4c0_0',
        'value' : 10
      }, debug: true);
      expect(result, false);
    });
  });

  group('Creation tests', () {
    setUp(() {
    });

    test('Single ContainsPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'contains',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, ContainsPredicate);
    });

    test('Single ContainsPredicate with invalid value', () {
      expect(() => new Predicate.fromJson(
          {
            'op' : 'contains',
            'path' : '/test',
            'value' : 123
          }
      ), throwsA(new isInstanceOf<ArgumentError>()));
    });

    test('Single DefinedPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'defined',
            'path' : '/test'
          }
      );
      expect(predicate.runtimeType, DefinedPredicate);
    });

    test('Single EndsPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'ends',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, EndsPredicate);
    });

    test('Single EndsPredicate with invalid value', () {
      expect(() => new Predicate.fromJson(
          {
            'op' : 'ends',
            'path' : '/test',
            'value' : 123
          }
      ), throwsA(new isInstanceOf<ArgumentError>()));
    });

    test('Single InPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'in',
            'path' : '/test',
            'value' : ['test']
          }
      );
      expect(predicate.runtimeType, InPredicate);
    });

    test('Single InPredicate with invalid value', () {
      expect(() => new Predicate.fromJson(
          {
            'op' : 'ends',
            'path' : '/test',
            'value' : 123
          }
      ), throwsA(new isInstanceOf<ArgumentError>()));
    });

    test('Single MatchesPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'matches',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, MatchesPredicate);
    });

    test('Single MatchesPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'matches',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, MatchesPredicate);
    });

    test('Single MorePredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'more',
            'path' : '/test',
            'value' : 2
          }
      );
      expect(predicate.runtimeType, MorePredicate);
    });

    test('Single StartsPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'starts',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, StartsPredicate);
    });

    test('Single TestPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'test',
            'path' : '/test',
            'value' : 'test'
          }
      );
      expect(predicate.runtimeType, TestPredicate);
    });

    test('Single TypePredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'type',
            'path' : '/test',
            'value' : 'string'
          }
      );
      expect(predicate.runtimeType, TypePredicate);
    });

    test('Single UndefinedPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'undefined',
            'path' : '/test'
          }
      );
      expect(predicate.runtimeType, UndefinedPredicate);
    });

    test('Second order AndPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'and',
            'apply' : [
              {
                'op' : 'test',
                'path' : '/test',
                'value' : 'test'
              }
            ]
          }
      );
      expect(predicate.runtimeType, AndPredicate);
      expect(predicate.predicates[0].runtimeType, TestPredicate);
    });

    test('Second order NotPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'not',
            'apply' : [
              {
                'op' : 'test',
                'path' : '/test',
                'value' : 'test'
              }
            ]
          }
      );
      expect(predicate.runtimeType, NotPredicate);
      expect(predicate.predicates[0].runtimeType, TestPredicate);
    });

    test('Second order OrPredicate', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'or',
            'apply' : [
              {
                'op' : 'test',
                'path' : '/test',
                'value' : 'test'
              }
            ]
          }
      );
      expect(predicate.runtimeType, OrPredicate);
      expect(predicate.predicates[0].runtimeType, TestPredicate);
    });

    test('Complex nested', () {
      var predicate = new Predicate.fromJson(
          {
            'op' : 'or',
            'path' : '/test1',
            'apply' : [
              {
                'op' : 'test',
                'path' : '/test2',
                'value' : 'test'
              },
              {
                'op' : 'not',
                'path' : '/test3',
                'apply' : [
                  {
                    'op' : 'and',
                    'path' : '/test4',
                    'apply' : [
                      {
                        'op' : 'starts',
                        'path' : '/test',
                        'value' : 'test'
                      },
                      {
                        'op' : 'ends',
                        'path' : '/test',
                        'value' : 'test'
                      },
                      {
                        'op' : 'contains',
                        'path' : '/test',
                        'value' : 'test'
                      }
                    ]
                  }
                ]
              }
            ]
          }
      );
      expect(predicate.runtimeType, OrPredicate);
      expect(predicate.predicates[0].runtimeType, TestPredicate);
      expect(predicate.predicates[1].runtimeType, NotPredicate);
      expect(predicate.predicates[1].predicates[0].runtimeType, AndPredicate);
      expect(predicate.predicates[1].predicates[0].predicates[0].runtimeType, StartsPredicate);
      expect(predicate.predicates[1].predicates[0].predicates[1].runtimeType, EndsPredicate);
      expect(predicate.predicates[1].predicates[0].predicates[2].runtimeType, ContainsPredicate);
    });
  });
}
