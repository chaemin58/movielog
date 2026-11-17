import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/service/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

const request = CreateMemberRequest(
  email: 'test@example.com',
  nickname: '테스트',
  password: 'Password123!',
);

Future<SignUpViewModel> ready(int status, String message) async {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'GET') {
          handler.resolve(
            Response(requestOptions: options, data: {'available': true}),
          );
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: status,
                data: {
                  'isSuccess': false,
                  'code': 'COMMON$status',
                  'message': message,
                  'result': null,
                },
              ),
            ),
          );
        }
      },
    ),
  );
  final vm = SignUpViewModel(SignUpService(dio));
  vm.onNicknameChanged(request.nickname);
  vm.onEmailChanged(request.email);
  await vm.checkNickname(request.nickname);
  await vm.checkEmail(request.email);
  return vm;
}

void main() {
  for (final entry in [
    (400, '비밀번호 형식이 올바르지 않습니다.', true),
    (400, '이메일 형식이 올바르지 않습니다.', false),
    (409, '이미 사용 중인 이메일입니다.', false),
  ]) {
    test('signup ${entry.$1} routes ${entry.$2}', () async {
      final vm = await ready(entry.$1, entry.$2);
      addTearDown(vm.dispose);
      await vm.submit(request);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(vm.passwordErrorText, entry.$3 ? entry.$2 : null);
      expect(vm.snackbarMessage, entry.$3 ? null : entry.$2);
      vm.onNicknameChanged('새닉네임');
      expect(vm.nicknameCheckStatus, CheckStatus.idle);
      expect(vm.passwordErrorText, isNull);
      expect(vm.snackbarMessage, isNull);
      expect(vm.submitStatus, SubmitStatus.idle);
      vm.onEmailChanged('new@example.com');
      expect(vm.emailCheckStatus, CheckStatus.idle);
    });
  }

  testWidgets(
    'password local validator and server error both work and clear on edit',
    (tester) async {
      final vm = await ready(400, '비밀번호 형식이 올바르지 않습니다.');
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      final password = find.byType(TextFormField).last;
      await tester.enterText(password, 'short');
      await tester.pump();
      expect(find.textContaining('8자 이상'), findsOneWidget);
      await tester.enterText(password, request.password);
      await tester.pump();
      expect(find.textContaining('8자 이상'), findsNothing);
      await vm.submit(request);
      await tester.pump();
      expect(find.text('비밀번호 형식이 올바르지 않습니다.'), findsOneWidget);
      await tester.enterText(password, 'Another123!');
      await tester.pump();
      expect(find.text('비밀번호 형식이 올바르지 않습니다.'), findsNothing);
    },
  );
}
