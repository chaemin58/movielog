import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nicknameController = TextEditingController();
  final _nicknameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  String _password = '';
  bool _agreed = false;

  bool get _validNickname => _nicknameController.text.trim().length >= 2;
  bool get _validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_emailController.text.trim());
  bool get _validPassword => _password.length >= 8;
  bool get _canRegister =>
      _validNickname && _validEmail && _validPassword && _agreed;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nicknameAvailable = context.select<SignUpViewModel, bool>(
      (viewModel) => viewModel.nicknameCheckStatus == CheckStatus.available,
    );
    final emailAvailable = context.select<SignUpViewModel, bool>(
      (viewModel) => viewModel.emailCheckStatus == CheckStatus.available,
    );
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: context.canPop(),
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: AppColors.primary500,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.neutral800,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _checkInput(isEmail: false),
                      const SizedBox(height: 20),
                      _checkInput(isEmail: true),
                      const SizedBox(height: 20),
                      _input(
                        label: '비밀번호',
                        hint: '비밀번호를 입력해주세요',
                        value: _password,
                        valid: _validPassword,
                        error: '비밀번호는 8자 이상이어야 합니다.',
                        autofillHint: AutofillHints.newPassword,
                        obscureText: true,
                        onChanged: (value) => setState(() => _password = value),
                      ),
                      const SizedBox(height: 40),
                      const Spacer(),
                      CheckboxListTile(
                        value: _agreed,
                        onChanged: (value) =>
                            setState(() => _agreed = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary500,
                        title: const Text(
                          '필수 약관에 동의합니다',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        width: double.infinity,
                        onPressed:
                            _canRegister && nicknameAvailable && emailAvailable
                            ? () => context.go('/home')
                            : null,
                        content: const Text(
                          '가입하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '이미 계정이 있나요?',
                            style: TextStyle(color: AppColors.neutral800),
                          ),
                          TextButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(
                                  const SnackBar(
                                    content: Text('로그인 화면은 준비 중입니다.'),
                                  ),
                                ),
                            child: const Text(
                              '로그인',
                              style: TextStyle(
                                color: AppColors.primary500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkInput({required bool isEmail}) {
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        final status = isEmail
            ? viewModel.emailCheckStatus
            : viewModel.nicknameCheckStatus;
        final checking = status == CheckStatus.checking;
        final available = status == CheckStatus.available;
        final label = isEmail ? '이메일' : '닉네임';
        final controller = isEmail ? _emailController : _nicknameController;
        final fieldKey = isEmail ? _emailFieldKey : _nicknameFieldKey;
        final errorText = isEmail
            ? viewModel.emailErrorText
            : viewModel.nicknameErrorText;
        final canCheck = isEmail
            ? viewModel.canCheckEmail
            : viewModel.canCheckNickname;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: fieldKey,
                    controller: controller,
                    autofillHints: [
                      isEmail ? AutofillHints.email : AutofillHints.nickname,
                    ],
                    keyboardType: isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: isEmail ? '이메일 주소를 입력해주세요' : '닉네임을 입력해주세요',
                      hintStyle: const TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: errorText == null
                          ? AppColors.surfaceLow
                          : const Color(0xFFFFDAD6),
                      isDense: true,
                      errorText: errorText,
                      errorMaxLines: 2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: AppColors.secondary300,
                        ),
                      ),
                      suffixIcon: available
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary500,
                              size: 20,
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (isEmail) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해 주세요.';
                        }
                        if (!_validEmail) return '올바른 이메일 형식이 아닙니다.';
                        return null;
                      }
                      final nickname = value?.trim() ?? '';
                      if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
                      if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
                      return null;
                    },
                    onChanged: isEmail
                        ? viewModel.onEmailChanged
                        : viewModel.onNicknameChanged,
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  content: const Text('중복 확인'),
                  isLoading: checking,
                  onPressed: canCheck
                      ? () {
                          if (fieldKey.currentState?.validate() ?? false) {
                            if (isEmail) {
                              viewModel.checkEmail(controller.text);
                            } else {
                              viewModel.checkNickname(controller.text);
                            }
                          }
                        }
                      : null,
                ),
              ],
            ),
            if (available)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isEmail ? '사용할 수 있는 이메일입니다.' : '사용할 수 있는 닉네임입니다.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _input({
    required String label,
    required String hint,
    required String value,
    required bool valid,
    required String error,
    required String autofillHint,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    final showError = value.isNotEmpty && !valid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          keyboardType: keyboardType,
          autofillHints: [autofillHint],
          textInputAction: obscureText
              ? TextInputAction.done
              : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14),
            filled: true,
            fillColor: showError
                ? const Color(0xFFFFDAD6)
                : AppColors.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
            errorText: showError ? error : null,
            errorMaxLines: 2,
            suffixIcon: value.isEmpty
                ? null
                : Icon(
                    valid ? Icons.check_circle : Icons.error_outline,
                    color: valid
                        ? AppColors.primary500
                        : const Color(0xFFBA1A1A),
                    size: 20,
                    semanticLabel: valid ? '입력 형식 확인 완료' : error,
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.secondary300),
            ),
          ),
        ),
      ],
    );
  }
}
