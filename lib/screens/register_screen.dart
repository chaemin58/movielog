import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/view_models/learning_member_session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _nicknameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  String _password = '';
  bool _agreed = false;

  bool get _validNickname =>
      _nicknameController.text.trim().length >= 2 &&
      _nicknameController.text.trim().length <= 12;
  bool get _validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_emailController.text.trim());
  bool get _validPassword =>
      _password.length >= 8 &&
      RegExp(r'[a-z]').hasMatch(_password) &&
      RegExp(r'[A-Z]').hasMatch(_password) &&
      RegExp(r'[0-9]').hasMatch(_password) &&
      RegExp(r'[!@#$%^&*]').hasMatch(_password);
  bool get _canRegister =>
      _validNickname && _validEmail && _validPassword && _agreed;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> onSubmitPressed(BuildContext context) async {
    final viewModel = context.read<SignUpViewModel>();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_canRegister ||
        viewModel.nicknameCheckStatus != CheckStatus.available ||
        viewModel.emailCheckStatus != CheckStatus.available ||
        viewModel.submitStatus == SubmitStatus.submitting) {
      return;
    }
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _password,
        nickname: _nicknameController.text,
      ),
    );
    if (!context.mounted) return;
    final memberId = viewModel.createMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      context.go('/movies');
      return;
    }
    final failureMessage =
        viewModel.snackbarMessage ??
        (viewModel.passwordErrorText != null ? '비밀번호 입력 내용을 확인해 주세요.' : null);
    if (failureMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<SignUpViewModel, bool>(
      (viewModel) => viewModel.submitStatus == SubmitStatus.submitting,
    );
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
                child: Form(
                  key: _formKey,
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
                        Consumer<SignUpViewModel>(
                          builder: (context, viewModel, child) => _input(
                            label: '비밀번호',
                            hint: '비밀번호를 입력해주세요',
                            value: _password,
                            valid: _validPassword,
                            error:
                                r'8자 이상, 대문자·소문자·숫자·특수문자(!@#$%^&*)를 포함해 주세요.',
                            enabled: !isSubmitting,
                            serverError: viewModel.passwordErrorText,
                            autofillHint: AutofillHints.newPassword,
                            obscureText: true,
                            onChanged: (value) {
                              setState(() => _password = value);
                              viewModel.onPasswordChanged();
                            },
                          ),
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
                          isLoading: isSubmitting,
                          onPressed:
                              _canRegister &&
                                  nicknameAvailable &&
                                  emailAvailable &&
                                  !isSubmitting
                              ? () => onSubmitPressed(context)
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
        final submitting = viewModel.submitStatus == SubmitStatus.submitting;
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
                    enabled: !submitting,
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
                      hintText: isEmail ? 'movie@umc.com' : '닉네임을 입력해주세요',
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
                      if (nickname.length > 12) return '닉네임은 12자 이하로 입력해 주세요.';
                      return null;
                    },
                    onChanged: isEmail
                        ? viewModel.onEmailChanged
                        : viewModel.onNicknameChanged,
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  width: 102,
                  content: const Text('중복 확인'),
                  isLoading: checking,
                  onPressed: canCheck && !submitting
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
    String? serverError,
    required String autofillHint,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
  }) {
    final showError = (value.isNotEmpty && !valid) || serverError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (input) {
            if (input == null || input.isEmpty) return '$label를 입력해 주세요.';
            return valid ? null : error;
          },
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
            // 로컬 validator가 통과한 경우에도 서버 오류를 표시합니다.
            errorText: serverError,
            errorMaxLines: 2,
            suffixIcon: value.isEmpty
                ? null
                : Icon(
                    showError ? Icons.error_outline : Icons.check_circle,
                    color: !showError
                        ? AppColors.primary500
                        : const Color(0xFFBA1A1A),
                    size: 20,
                    semanticLabel: showError
                        ? (serverError ?? error)
                        : '입력 형식 확인 완료',
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
