// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/strings.dart';
import '../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/usecases/update_user_password.dart';

part 'update_user_password_event.dart';
part 'update_user_password_state.dart';

class UpdateUserPasswordBloc
    extends Bloc<UpdateUserPasswordEvent, UpdateUserPasswordState> {
  UpdateUserPasswordUseCase updatePasswordUseCase;

  UpdateUserPasswordBloc({required this.updatePasswordUseCase})
      : super(UpdateUserPasswordInitial()) {
    on<UpdateUserPasswordEvent>((event, emit) {});

    on<UpdateUserPasswordEventPasswordChanging>(
        _updatePasswordEventPasswordChanging);
  }

  _updatePasswordEventPasswordChanging(
      UpdateUserPasswordEventPasswordChanging event,
      Emitter<UpdateUserPasswordState> emit) async {
    emit(UpdateUserPasswordLoading());
    final failureOrUnit = await updatePasswordUseCase(
        event.oldPassword, event.newPassword, event.newPasswordConfirm);
    failureOrUnit.fold(
      (failure) => emit(UpdateUserPasswordError(mapFailureToMessage(failure))),
      (_) => emit(UpdateUserPasswordSuccess(PasswordChangeSucessMessage)),
    );
  }
}
