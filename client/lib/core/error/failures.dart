import 'package:equatable/equatable.dart';

import '../strings.dart';

abstract class Failure extends Equatable {}

class OfflineFailure extends Failure {
  static const String message = OfflineFailureMessage;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  static const String message = ServerFailureMessage;

  @override
  List<Object?> get props => [message];
}

class EmptyCacheFailure extends Failure {
  static const String message = EmptyCacheFailureMessage;

  @override
  List<Object?> get props => [message];
}

class ServerMessageFailure extends Failure {
  static late String message;

  ServerMessageFailure();

  @override
  List<Object?> get props => [message];
}

class UnauthorizedFailure extends Failure {
  static late String message;

  UnauthorizedFailure();

  @override
  List<Object?> get props => [message];
}
