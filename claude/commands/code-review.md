# /code-review (셀프 리뷰)

코드 작성 직후, 커밋 전에 아래를 빠르게 확인합니다.

- [ ] 보안: 하드코딩 비밀값/권한/입력값 검증 누락 없음
- [ ] DB: `site_id`, `status` 조건 누락 없음
- [ ] 레거시: JSP→템플릿 변수(setVar/setLoop) 누락 없음
- [ ] UI: null/빈값/배열/단건 케이스 방어됨
- [ ] 빌드: `project/` 수정 시 `npm run build` 완료

