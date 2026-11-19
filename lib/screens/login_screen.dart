import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/common/custom_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthViewModel>().login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isLoading = auth.status == AuthStatus.authenticating;
    final canSubmit = !isLoading && !auth.storageCleanupInProgress;
    final message = auth.message;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          enabled: canSubmit,
                          decoration: const InputDecoration(labelText: '이메일'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? '이메일을 입력해 주세요.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          enabled: canSubmit,
                          decoration: const InputDecoration(labelText: '비밀번호'),
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) => (value?.isEmpty ?? true)
                              ? '비밀번호를 입력해 주세요.'
                              : null,
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButton(
                          onPressed: canSubmit ? _submit : null,
                          content: Text(isLoading ? '로그인 중…' : '로그인'),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: canSubmit ? () => context.push('/register') : null,
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
