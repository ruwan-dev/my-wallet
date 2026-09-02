import 'package:dartz/dartz.dart';

Future<Either<String, void>> call() async {
  Either<String, int> updateResult = Left("error");
  
  return updateResult.fold(
    (failure) => Left(failure),
    (_) async {
      await Future.delayed(Duration(seconds: 1));
      return Right(null);
    }
  );
}

void main() async {
  var x = await call();
  print('Result type: ${x.runtimeType}');
  print('Result: $x');
}
