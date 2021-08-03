import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'cfg.dart';

typedef VoidFuture = Future<void>;

class FloorDaoRiverpodGenerator {
  final $Future = const TypeChecker.fromRuntime(Future);
  final $Stream = const TypeChecker.fromRuntime(Stream);
  final $FutureOrStream = const TypeChecker.any([
    TypeChecker.fromRuntime(Future),
    TypeChecker.fromRuntime(Stream),
  ]);

  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    final db = annotation.read('databaseType').typeValue.element;
    const dbProvider = DEFAULT_DB_PROVIDER_NAME;

    if (db is! ClassElement) {
      throw ArgumentError.value(
        db,
        'Database type not a class',
        'The parameter must reference a ClassElement',
      );
    }

    return directGenerateForDao(element, db, dbProvider);
  }

  FutureOr<String> directGenerateForDao(
    ClassElement element,
    ClassElement db,
    String dbProviderName,
  ) {
    final T = element.name;

    final matchThis = TypeChecker.fromStatic(element.thisType);

    final daoOnDb = db.fields.singleWhere(
        (e) => matchThis.isExactlyType(e.type),
        orElse: () => throw ArgumentError.value('Could not match ' +
            element.thisType.toString() +
            ' among ' +
            db.fields.map((e) => e.type.toString()).join(',')));
    final daoNameOnDb = daoOnDb.name;

    final daoProviderName = '_provider\$$T';

    final out = [
      '/// Private base provider for the DAO',
      'final $daoProviderName = FutureProvider<$T>((ref) async {',
      '  final db = await ref.read($dbProviderName.future);',
      '  return db.$daoNameOnDb;',
      '});',
      '',
      '/// Static class with providers for $T',
      'class $T\$Providers {',
      '  static FutureProvider<$T> get dao => $daoProviderName;',
    ];

    //We should put a provider iff
    // - it is a Future<T> or Stream<T>, where T is not void
    // - it has 0 or 1 parameters
    bool _shouldAddField(MethodElement method) =>
        method.parameters.length < 2 &&
        $FutureOrStream.isExactlyType(method.returnType) &&
        _isNonVoidParameterized(method.returnType);

    for (final method in element.methods.where(_shouldAddField)) {
      final returnType = method.returnType as ParameterizedType;
      final methodName = method.name;
      final innerType = returnType.typeArguments.single;
      out.add('');
      //future or string - abbreviated for interpolation
      final useFuture = returnType.isDartAsyncFuture;
      final fos = useFuture ? 'Future' : 'Stream';
      final asyncTxt = useFuture ? 'async' : 'async*';
      if (method.parameters.isEmpty) {
        out.addAll([
          '  // => ${method.toString()}',
          'static final AutoDispose${fos}Provider<$innerType> $methodName =',
          '    ${fos}Provider.autoDispose((ref) $asyncTxt {',
          '  final dao = await ref.read($daoProviderName.future);',
        ]);
        if (useFuture) {
          out.add('  return dao.$methodName();');
        } else {
          out.addAll([
            '  final stream = dao.$methodName();',
            '  await for (final value in stream) {',
            '    yield value;',
            '  }',
          ]);
        }
        out.add('});');
      } else {
        // method.parameters.isNotEmpty
        final paramType = method.parameters.first.type;
        out.addAll([
          ' // => ${method.toString()}',
          'static final AutoDispose${fos}ProviderFamily<$innerType, $paramType>'
              ' $methodName =',
          '${fos}Provider.autoDispose.family<$innerType, $paramType>((ref, key)'
              ' $asyncTxt {',
          'final dao = await ref.read($daoProviderName.future);',
        ]);
        if (useFuture) {
          //Stream

          //isNullable?
          if (innerType.nullabilitySuffix == NullabilitySuffix.question) {
            out.addAll([
              'final res = await dao.$methodName(key);',
              "if(res == null) throw Exception('Could not find key \$key');",
              'return res;',
            ]);
          } else {
            out.add('return dao.$methodName(key);');
          }
        } else {
          out.addAll([
            'final stream = dao.$methodName(key);',
            'await for (final value in stream) {',
            '  yield value;',
            '}',
          ]);
        }
        out.add('});');
      }
    }
    out.add('}');

    // Code here was for diagnostic of why element not included
    // Might want to go ahead and output something similar
    // for (final method in element.methods.where((m) => !_shouldAddField(m))) {
    //   final returnType = method.returnType;
    //   // method.parameters.length < 2 &&
    //   //     $FutureOrStream.isExactlyType(method.returnType) &&
    //   //     _isNonVoidParameterized(method.returnType);
    //   final params =
    //       (returnType is ParameterizedType) ? returnType.typeArguments : [];
    //
    //   out.add('// ${method.name} (${returnType.toString()}) ? '
    //       'Param<2: ${method.parameters.length} '
    //       'FoS: ${$FutureOrStream.isExactlyType(returnType)} '
    //       'nonVoid: ('
    //       ' ${method.returnType is ParameterizedType}'
    //       ' ${params.length}'
    //       ' ${params.length == 1 ? !params.first.isVoid : 'not 1'} )');
    // }
    return out.join('\n');
  }

  bool _isNonVoidParameterized(DartType t) {
    if (t is! ParameterizedType) return false;
    final params = t.typeArguments;
    if (params.length != 1) return false; //We want a single parameter
    return !params.first.isVoid;
  }
}
