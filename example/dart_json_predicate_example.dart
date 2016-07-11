// Copyright (c) 2016, Andreas Reiter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_json_predicate/json_predicate.dart' as jpredicate;

var testDocument = {
  "level1_0" : "This is a string value",
  "level1_1" : 5,
  "level1_2" : -3,
  "level1_3" : 3.2,
  "level1_4" : -2.2,
  "level1_5" : "2012-04-23T18:25:43.511Z",
  "level1_6" : ["Test 123", "abcdef"],
  "level1_7" : [5,6,7,8,9],

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
        "level2c0_0" : "This is another string value",
        "level2c0_1" : 5,
        "level2c0_2" : -3,
        "level2c0_3" : 3.2,
        "level2c0_4" : -2.2,
        "level2c0_5" : "2013-04-23T18:25:43.511Z",
        "level2c0_6" : ["Test 123", "abcdef"],
        "level2c0_7" : [5,6,7,8,9]
      }
    }
  }
};

main() {
  var result = jpredicate.json(testDocument, {
    'op' : 'matches',
    'path' : '/level1_0',
    'value' : '[\\w\\s]*'
  });

  print(result);
}
