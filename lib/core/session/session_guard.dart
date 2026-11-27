class SessionGuard {
  int _generation = 0;
   String? _accountId;

  //외부에서 내부 변수의 값을 읽을 수 있게 해주는 getter
   int get generation => _generation;
   String? get accountId => _accountId;

   //인증 호스트가 검증한 새 세션을 시작할 때만 호출
  int startSession(String accountId){
    //세션이 시작하면 accoundId를 받아서 저장. 
    _accountId = accountId;
    return ++_generation; //세대 카운트
  }

  void invalidate(){
    _accountId = null;
    _generation++;
  }

  bool isCurrent (int generation, String accountId) => _generation == generation && _accountId == accountId; 
}
