import 'dart:async';

class Either<L, R> {
  final L? l;
  final R? r;
  final bool isLeft;
  Either.left(this.l) : r = null, isLeft = true;
  Either.right(this.r) : l = null, isLeft = false;

  B fold<B>(B Function(L l) ifLeft, B Function(R r) ifRight) {
    if (isLeft) return ifLeft(l as L);
    return ifRight(r as R);
  }
}

Future<String?> doSomething() async {
  var either = Either<String, int>.right(42);
  return either.fold(
    (l) async => l,
    (r) async {
      await Future.delayed(Duration(milliseconds: 100));
      print('Inside right fold!');
      return null;
    }
  );
}

void main() async {
  var result = await doSomething();
  print('Result type: ${result.runtimeType}');
  print('Result value: $result');
}
