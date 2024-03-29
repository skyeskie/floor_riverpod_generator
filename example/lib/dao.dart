import 'package:example/db.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

@dao
abstract class FooDao {
  late sqflite.DatabaseExecutor rawDb;

  ///Example for Future with no parameters
  @Query('SELECT * FROM Shape')
  Future<List<Shape>> getAllShapes();

  ///Example for Future with parameter
  @Query('SELECT * FROM Shape WHERE name = :name')
  Future<Shape?> getShape(String name);

  ///Insert example - Future<void> should mean ignored
  @Insert()
  Future<void> putShape(Shape s);

  ///Example for Stream with parameter
  @Query('SELECT * FROM Shape WHERE name = :name')
  Stream<Shape?> watchShape(String name);

  ///Example for Stream without parameters
  @Query('SELECT * FROM Shape')
  Stream<List<Shape>> watchAllShapes();
}
