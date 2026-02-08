# CLAUDE.md - GrowAILMS 프로젝트 설정

> 이 파일은 Claude Code가 프로젝트를 이해하는 데 사용됩니다.

## 프로젝트 개요

**GrowAILMS**는 한국폴리텍대학 학습관리시스템(LMS) 고도화 프로젝트입니다.
MalgnLMS 레거시 시스템을 현대적인 기술 스택으로 마이그레이션합니다.

## 기술 스택

### Target Stack (GrowAILMS)
- **Backend**: Java 17 + Spring Boot 3.2 + eGovFrame 4.2
- **ORM**: MyBatis 3.5
- **인증**: JWT + Keycloak
- **캐시**: Redis
- **Frontend**: React 18 + TypeScript + Vite + Tailwind CSS
- **컨테이너**: Docker Compose
- **웹서버**: Nginx

### Source Stack (MalgnLMS)
- **Backend**: Java 8 + Malgnsoft DataObject Framework
- **ORM**: Custom DAO Pattern
- **Frontend**: JSP + jQuery
- **위치**: D:\WorkSpace\MalgnLMS-main_new\MalgnLMS-main

## 디렉토리 구조

```
src/main/java/kr/ac/kopo/growai/lms/
├── config/          # Spring 설정
├── controller/      # REST API 컨트롤러
├── service/         # 비즈니스 로직 (@Service)
├── mapper/          # MyBatis Mapper 인터페이스
├── domain/          # Entity/DTO
└── common/
    ├── constants/   # Enum 상수
    ├── security/    # JWT 필터
    └── exception/   # 예외 처리

src/main/resources/
├── mapper/          # MyBatis XML
├── application.yml
└── application-dev.yml

src/main/frontend/   # React 프론트엔드
├── src/
│   ├── pages/
│   ├── components/
│   ├── services/
│   └── stores/
└── package.json
```

## 변환 규칙

### 1. DAO → Service 변환

**Source (MalgnLMS)**:
```java
public class CourseDao extends DataObject {
    public CourseDao() {
        this.table = "LM_COURSE";
        this.pkey = "id";
    }
    
    public DataSet find(int id) {
        return query("SELECT * FROM " + table + " WHERE id = ?", id);
    }
}
```

**Target (GrowAILMS)**:
```java
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CourseService {
    
    private final CourseMapper courseMapper;
    
    @Cacheable(value = "course", key = "#id")
    public Optional<Course> findById(Long id, Long siteId) {
        return Optional.ofNullable(courseMapper.selectById(id, siteId));
    }
}
```

### 2. 코드 배열 → Enum 변환

**Source**:
```java
String[] statusList = {"1=>정상", "0=>중지"};
```

**Target**:
```java
@Getter
@RequiredArgsConstructor
public enum Status implements CodeEnum {
    ACTIVE("1", "정상"),
    INACTIVE("0", "중지");
    
    private final String code;
    private final String label;
}
```

### 3. JSP → React 변환

**Source (JSP)**:
```jsp
<table>
    <c:forEach var="item" items="${list}">
        <tr><td>${item.courseNm}</td></tr>
    </c:forEach>
</table>
```

**Target (React + TypeScript)**:
```tsx
const CourseList: React.FC = () => {
    const { data: courses } = useCourses();
    
    return (
        <table className="min-w-full">
            {courses?.map(item => (
                <tr key={item.id}>
                    <td>{item.courseNm}</td>
                </tr>
            ))}
        </table>
    );
};
```

## 시큐어코딩 규칙

1. **SQL Injection 방지**: MyBatis `#{}` 바인딩만 사용 (`${}` 금지)
2. **XSS 방지**: 입력값 검증, HTML 이스케이프
3. **로깅**: 민감정보(비밀번호, 주민번호) 로그 출력 금지
4. **인증**: 모든 API에 JWT 토큰 검증

## 명령어

```bash
# 컴파일
mvn compile

# 테스트
mvn test

# 실행
mvn spring-boot:run

# Docker 빌드
docker-compose up -d

# 프론트엔드 개발
cd src/main/frontend && npm run dev
```

## 변환 우선순위

1. **Priority 1 (Core)**: CourseDao, CourseUserDao, LessonDao, UserDao
2. **Priority 2 (Auth)**: UserLoginDao, AuthDao, TokenDao
3. **Priority 3 (Business)**: OrderDao, PaymentDao, BoardDao
4. **Priority 4 (Others)**: 나머지 DAO

## 주의사항

- 모든 코드는 **한국어 주석** 포함
- 파일 상단에 **경로 주석** 필수
- 행안부 **시큐어코딩 가이드** 준수
- **멀티테넌시**: 모든 쿼리에 `site_id` 조건 포함
