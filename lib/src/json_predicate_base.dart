// Copyright (c) 2016, Andreas Reiter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'predicates/predicate.dart';

/// Tests the specified parsed JSON input against the specified parsed predicate
///
bool json(input, predicate){
  var p = new Predicate.fromJson(predicate);

  return p.json(input)[0];
}