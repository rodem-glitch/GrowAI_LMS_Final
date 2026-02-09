package kr.polytech.lms.security.error;

/**
 * 외부 서비스 연결 실패 예외
 * vLLM, Vertex AI, BigBlueButton, Open edX, Qdrant 등
 */
public class ExternalServiceException extends RuntimeException {

    private final String serviceName;
    private final String errorCode;
    private final String userMessage;

    public ExternalServiceException(String serviceName, String errorCode, String userMessage) {
        super(serviceName + " 서비스 오류: " + userMessage);
        this.serviceName = serviceName;
        this.errorCode = errorCode;
        this.userMessage = userMessage;
    }

    public ExternalServiceException(String serviceName, String errorCode, String userMessage, Throwable cause) {
        super(serviceName + " 서비스 오류: " + userMessage, cause);
        this.serviceName = serviceName;
        this.errorCode = errorCode;
        this.userMessage = userMessage;
    }

    public String getServiceName() { return serviceName; }
    public String getErrorCode() { return errorCode; }
    public String getUserMessage() { return userMessage; }
}
