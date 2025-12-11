1. 배치 방법은 eXSignOn Token 매뉴얼 참고

2. 샘플의 기본적인 배치 위치는 /lib를 제외한 common, include, sample, sso 디렉토리가 DocumentRoot/exsignon 바로 아래 있는것으로 가정.
   /lib/json-simple-1.1.1.jar는 WEB-INF/lib 위치에 복사한다.
   배치 위치를 수정 할 경우 jsp 파일 내부의 요청 URL 수정이 필요하다.
   
3. 아래와 같은 SSLHandshakeException은 정식 SSL 인증서가 아닌 경우 발생 할 수 있으며 해결을 위해서는
   /lib/exsignon-ssl-trust-listener를 /WEB-INF/lib에 복사한 뒤 web.xml에 listener를 등록한다.
   exsignon-ssl-trust-listener-4.jar는 jdk1.5 이하 exsignon-ssl-trust-listener-6.jar는 jdk1.6 이상에서 호환 되므로
   사용중인 시스템에 맞춰 사용 한다.
   
   <listener>
     <listener-class>com.tomato.ssl.SSLTrustedListener</listener-class>
   </listener>
   
   javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
   