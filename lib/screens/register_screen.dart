import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _background = Color(0xFFFFFDFA);
  static const _ink = Color(0xFF302D34);
  static const _labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _ink,
  );
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;

  bool get _passwordValid =>
      _password.text.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(_password.text) &&
      RegExp(r'[0-9]').hasMatch(_password.text);

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String hint, {
    String? error,
    bool checked = false,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF99929F), fontSize: 16),
    filled: true,
    fillColor: _background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDED6E7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
    ),
    errorText: error,
    errorMaxLines: 3,
    suffixIcon: checked
        ? const Icon(Icons.check_circle, color: AppColors.primary500, size: 26)
        : null,
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final canSubmit = vm.checksPassed && _passwordValid && _agreed;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primary500,
          ),
        ),
        leading: BackButton(
          color: _ink,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my');
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: math.min(64, constraints.maxHeight * .08),
                          ),
                          const Text(
                            '환영합니다!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '간단한 정보만 입력하고 시작해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: _ink),
                          ),
                          const SizedBox(height: 32),
                          _checkField(
                            label: '닉네임',
                            hint: '닉네임을 입력해 주세요',
                            controller: _nickname,
                            status: vm.nicknameCheckStatus,
                            error: vm.nicknameErrorText,
                            validator: SignUpViewModel.validateNickname,
                            onChanged: vm.onNicknameChanged,
                            onCheck: vm.canCheckNickname
                                ? () => vm.checkNickname(_nickname.text)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _checkField(
                            label: '이메일',
                            hint: 'movie@umc.com',
                            controller: _email,
                            status: vm.emailCheckStatus,
                            error: vm.emailErrorText,
                            validator: SignUpViewModel.validateEmail,
                            onChanged: vm.onEmailChanged,
                            onCheck: vm.canCheckEmail
                                ? () => vm.checkEmail(_email.text)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          const Text('비밀번호', style: _labelStyle),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: _decoration('영문·숫자 포함 8자 이상'),
                            validator: (_) => _passwordValid
                                ? null
                                : '영문·숫자 포함 8자 이상 입력해 주세요.',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 48),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _agreed = !_agreed),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 32,
                                    child: Checkbox(
                                      value: _agreed,
                                      activeColor: AppColors.primary500,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _agreed = value ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Flexible(
                                    child: Text(
                                      '필수 약관에 동의합니다',
                                      style: _labelStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          MovieLogButton(
                            label: '가입하기',
                            width: double.infinity,
                            height: 56,
                            borderRadius: 6,
                            disabledBackgroundColor: const Color(0xFFD4C5E3),
                            onPressed: canSubmit
                                ? () {
                                    if (_formKey.currentState!.validate() &&
                                        vm.checksPassed &&
                                        _agreed) {
                                      context.go('/home');
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 48),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              const Text(
                                '이미 계정이 있나요?',
                                style: TextStyle(fontSize: 16, color: _ink),
                              ),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('로그인 기능은 아직 준비 중입니다.'),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _checkField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required CheckStatus status,
    required String? error,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
    required VoidCallback? onCheck,
  }) {
    final checking = status == CheckStatus.checking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: label == '이메일'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                autocorrect: false,
                decoration: _decoration(
                  hint,
                  error: error,
                  checked: status == CheckStatus.available,
                ),
                validator: validator,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            MovieLogButton(
              label: '중복 확인',
              height: 56,
              isLoading: checking,
              disabledBackgroundColor: const Color(0xFF807C84),
              onPressed: onCheck,
            ),
          ],
        ),
        if (checking || status == CheckStatus.available)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              checking ? '$label 사용 가능 여부를 확인 중입니다.' : '사용 가능한 $label입니다.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: checking
                    ? const Color(0xFF2473C6)
                    : const Color(0xFF34853A),
              ),
            ),
          ),
      ],
    );
  }
}
