import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class DaoProvider {
  final String dbProvider; //TODO: Generate this (from @Database)
  final String daoNameOnDb; //TODO: We should be able to grab this
  const DaoProvider({
    required this.dbProvider,
    required this.daoNameOnDb,
  });
}

Builder floorRiverpodProviderBuilder(BuilderOptions options) =>
    SharedPartBuilder([FloorProviderBuilder()], 'floorRiverpod');

class FloorProviderBuilder extends GeneratorForAnnotation<DaoProvider> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    final T = element.name;
    final dbProvider = annotation.read('dbProvider').stringValue;
    final daoNameOnDb = annotation.read('daoNameOnDb').stringValue;

    final daoProviderName = '_provider\$$T';

    final out = [
      '''
/// Private base provider for the DAO
final $daoProviderName = FutureProvider<$T>((ref) async {
  final db = await ref.read($dbProvider.future);
  return db.$daoNameOnDb;
});

/// Static class with providers for $T
class $T\$Providers {
  static FutureProvider<$T> get dao => $daoProviderName;
'''
    ];

    //We should put a provider iff
    // - it is a Future, but not Future<void> //TODO: Add Stream
    // - it has 0 or 1 parameters
    bool _shouldAddField(MethodElement method) =>
        method.returnType.isDartAsyncFuture &&
        method.parameters.length < 2 &&
        method.returnType.toString() != 'Future<void>';

    for (final method in element.methods.where(_shouldAddField)) {
      final returnType = method.returnType;
      final methodName = method.name;
      out.add('');
      if (method.parameters.isEmpty) {
        out.addAll([
          '  // => ${method.toString()}',
          'static final AutoDisposeFutureProvider<$returnType> $methodName =',
          '    FutureProvider.autoDispose((ref) async {',
          '  final dao = await ref.read($daoProviderName.future);',
          '  return dao.$methodName();',
          '});',
        ]);
      } else {
        final paramType = method.parameters.first.type;
        final end = returnType.toString().length;
        final convertType = returnType.toString().substring(7, end - 1);
        out.addAll([
          ' // => ${method.toString()}',
          'static final AutoDisposeFutureProviderFamily<$convertType, $paramType> $methodName =',
          'FutureProvider.autoDispose.family<$convertType, $paramType>((ref, key) async {',
          'final dao = await ref.read($daoProviderName.future);',
        ]);
        //isNullable?
        if (convertType.endsWith('?')) {
          out.addAll([
            'final res = await dao.$methodName(key);',
            "if(res == null) throw Exception('Could not find key \$key');",
            'return res;',
          ]);
        } else {
          out.add('return dao.$methodName(key);');
        }
        out.add('});');
      }
    }
    out.add('}');
    return out.join('\n');
  }
}
