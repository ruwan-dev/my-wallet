import 'package:dartz/dartz.dart';

void main() async {
  Either<String, int> res = Right(5);
  
  var x = res.fold(
    (l) => Left(l),
    (r) async {
      await Future.delayed(Duration(seconds: 1));
      return Right(r * 2);
    }
  );
  
  print('Type of x: ${x.runtimeType}');
  
  if (x is Future) {
    var finalResult = await x;
    print('Awaited result type: ${finalResult.runtimeType}');
    print('Awaited result: $finalResult');
  }
}
