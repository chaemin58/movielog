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

  late final AuthViewModel _auth;

  //로그인 화면에서 세션 만료 여부를 감지하고 만료되었다면 사용자에게 안내하기 위한 코드
  //로그인 화면이 만들어지면서 initState를 실행한다. 부모 클래스의 초기화 작업을 수행하고
  //AuthViewModel의 context를 읽어온다. 그리고 앞으로 발생할 인증상태에 대해서 감시하기 시작한다.
  //--> 상태가 변경되면 _showSessionExpired 실행
  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showSessionExpired(),
    ); //로그인 화면이 처음 화면에 그려질 때까지 기다렸다가....
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); //세션 만료 상태 소비
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar() //기존 스낵바 제거
      ..showSnackBar(
        const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
      ); //새로운 스낵바
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _auth.removeListener(_showSessionExpired);
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
