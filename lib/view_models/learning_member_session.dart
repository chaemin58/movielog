//회원가입한 사용자의 memberId를 앱에서 공유하고 값이 바뀌면 알려주는 클래스

import 'package:flutter/widgets.dart';

class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
