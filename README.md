Extension builder to make [riverpod](https://pub.dev/packages/riverpod) providers for [floor](https://pub.dev/packages/floor) DAOs.

## Installation

Add to your `dev_dependencies` section.

Note: this assumes you are using `floor` and `riverpod_flutter`. No new dependencies are required, since you'll have them from those dependencies (ex: `build_runner`)

## Usage

1. Create a provider for your database
    ```dart
    final myDbProvider = FutureProvider<MyDatabase>((ref) async {
      final dbName = ref.read(myDatabaseProvider);
      return $FloorMyDatabase.databaseBuilder(dbName).build();
    });
    ```
1. Add a part directive to your DAO file (`part 'my_dao.g.dart';`)

1. Add a `@DaoProvider()` annotation to your Dao class (in addition to the @dao annotation), filling in the database provider and the name of the DAO on the database object.
    
    ```dart
    import 'package:floor_riverpod_generator/floor_riverpod_generator.dart';
    
    @DaoProvider(
      dbProvider: 'myDbProvider',
      daoNameOnDb: 'myDao',
    )
    @dao
    SomeDao() {
      var awesome = new Awesome();
    }
    ```
1. Run build_runner
1. Use the providers from the generated `MyDao$Providers` class

## Features and bugs

TODO
- Remove need for '@DaoProvider' unless need to override
- Generate database provider automatically
- Revisit naming
- Tests
