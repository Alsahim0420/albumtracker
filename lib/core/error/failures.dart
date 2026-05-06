abstract class Failure {}

class DatabaseFailure extends Failure {}

class FileSystemFailure extends Failure {}

class CsvImportFailure extends Failure {
  CsvImportFailure([this.message]);
  final String? message;
}

class RemoteAnalysisFailure extends Failure {
  RemoteAnalysisFailure([this.message]);
  final String? message;
}
