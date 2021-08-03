library flutter_riverpod_generator.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/floor_database_riverpod_generator.dart';

/// Entry point for build_runner
///
/// See build_runner docs for usage
Builder floorRiverpodProviderBuilder(BuilderOptions options) =>
    SharedPartBuilder(
      [
        FloorDatabaseRiverpodGenerator(),
      ],
      'floorRiverpod',
    );
