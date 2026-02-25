import 'package:albumtracker/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}