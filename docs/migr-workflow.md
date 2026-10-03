# 1.5.1 마이그레이션 작업 절차

`master`는 포크에 남은 upstream 브랜치다. 작업과 병합은 `main`만 사용한다.

1. `main`에서 `feat/v1.5.1-migr-N`을 만든다. N은 1부터 증가한다.
2. 그 브랜치에서만 패치한다.
3. Keyboard 빌드를 만든다. `LastEpochPath`는 저장소에 커밋하지 않는다. 이 PC에서는 gitignore된 `Directory.Build.props`에 둔다.
4. `Latest`에 키보드 패키지를 만든다. WinRAR이 있으면 `LastEpoch_Hud(Keyboard).rar`, 없으면 7-Zip으로 `LastEpoch_Hud(Keyboard).zip`이다.
5. 빌드된 `LastEpoch_Hud.dll`을 `E:\SteamLibrary\steamapps\common\Last Epoch\Mods\LastEpoch_Hud.dll`에 복사한다. 게임 폴더 파일은 git에 넣지 않는다.
6. 작업이 끝나면 `docs/v1.5.1-migr-N.md`에 리포트를 쓴다. 이 파일을 커밋에 포함한다. 코드가 안 바뀌어 빌드와 복사를 건너뛰면 그 사실을 리포트에 적는다.
7. `feat/v1.5.1-migr-N`을 `main`에 병합한다.
8. 병합한 브랜치는 지운다.
9. `main`에서 다음 브랜치 `feat/v1.5.1-migr-(N+1)`을 만들어 둔다.

리포트에 적을 항목:

- 브랜치, 커밋, `main` 병합 결과
- Keyboard 패키지 경로, DLL 복사 경로, 크기, SHA256
- 맞춘 API와 이 빌드에서 아직 동작하지 않는 기능
- 게임을 실행했으면 그 결과. 실행하지 않았으면 그 사실
- 다음 순번으로 넘기는 일
