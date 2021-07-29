import 'dart:async';

import 'package:floor/floor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao.dart';

part 'db.g.dart';

@Database(
  version: 1,
  entities: [Shape],
)
abstract class ExampleDatabase extends FloorDatabase {
  FooDao get fooDao;
}

@Entity()
class Shape {
  @PrimaryKey()
  String name;

  int sides;

  String areaFormula;

  Shape({
    required this.name,
    required this.sides,
    required this.areaFormula,
  });
}
