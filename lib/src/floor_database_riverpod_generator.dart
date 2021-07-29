import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:floor_annotation/floor_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';
import 'cfg.dart';

class FloorDatabaseRiverpodGenerator extends GeneratorForAnnotation<Database> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    final T = element.name;

    const dbProvider = DEFAULT_DB_PROVIDER_NAME;
    final dbName = T.replaceAll('Database', '_database').toLowerCase();

    final daos = element.fields.where((field) => _isDao(field.type.element));

    final out = [
      'final $dbProvider = FutureProvider<$T>((ref) async {',
      "  final db = await \$Floor$T.databaseBuilder('$dbName').build();",
      '  //Some DAOs need direct access to the database',
    ];

    for (final daoElement in daos) {
      //Call other generator?

      final dao = daoElement.type.element as ClassElement;
      final daoFieldName = daoElement.name;
      final dbPtr = dao.fields.where((field) =>
              field.isLate //&& _dbExecType.isAssignableFromType(field.type)
          );
      if (dbPtr.isNotEmpty) {
        final targetName = dbPtr.first.name;
        out.add('db.$daoFieldName.$targetName = db.database;');
      }
    }

    out.addAll([
      '  return db;',
      '});',
    ]);

    return out.join('\n');
  }

  final _daoType = const TypeChecker.fromRuntime(DaoProvider);
  // final _dbExecType = const TypeChecker.fromRuntime(sqflite.DatabaseExecutor);

  bool _isDao(final Element? e) {
    return e is ClassElement &&
        e.isAbstract &&
        _daoType.hasAnnotationOfExact(e);
  }
}
