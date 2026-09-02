import 'dart:async';

class Left {
  final Object value;
  Left(this.value);
}
class Right {
  final Object value;
  Right(this.value);
}
class Either {
  final Object? _left;
  final Object? _right;
  final bool isLeft;
  Either.left(this._left) : _right = null, isLeft = true;
  Either.right(this._right) : _left = null, isLeft = false;
  
  B fold<B>(B Function(Object l) ifLeft, B Function(Object r) ifRight) {
    if (isLeft) return ifLeft(_left!);
    return ifRight(_right!);
  }
}

Future<void> main() async {
  print('Start');
  final result = await testFunc();
  print('Result type: ${result.runtimeType}, Result: $result');
}

Future<Either> testFunc() async {
  final e1 = Either.right('acc');
  return e1.fold(
    (l) async => Either.left('err'),
    (r) async {
      print('Inside outer fold');
      final updateResult = Either.right('upd');
      return updateResult.fold(
        (l) => Either.left('err2'),
        (_) async {
          print('Inside inner fold');
          await Future.delayed(Duration(seconds: 1));
          print('Finished inner delay');
          return Either.right('success');
        }
      );
    }
  );
}
