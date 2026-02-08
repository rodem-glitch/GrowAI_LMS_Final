// polytech-lms-api/src/main/java/kr/polytech/lms/security/encryption/DatabaseEncryptionService.java
package kr.polytech.lms.security.encryption;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Database Encryption Service
 * 행정안전부 시큐어코딩 가이드라인 준수
 *
 * 암호화 방식:
 * - 양방향 암호화: AES-128-GCM (고유식별정보: 주민등록번호, 여권번호 등)
 * - 단방향 암호화: SHA-256 + Salt (비밀번호)
 *
 * 개인정보보호법 제24조, 제29조 준수
 */
@Slf4j
@Service
public class DatabaseEncryptionService {

    @Value("${encryption.aes.secret-key:polytech-lms-encryption-key-128}")
    private String aesSecretKey;

    @Value("${encryption.aes.salt:polytech-lms-salt}")
    private String aesSalt;

    // AES-GCM 설정
    private static final String AES_ALGORITHM = "AES/GCM/NoPadding";
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;
    private static final int AES_KEY_SIZE = 128;
    private static final int ITERATION_COUNT = 65536;

    // SHA-256 설정
    private static final String SHA_ALGORITHM = "SHA-256";
    private static final int SALT_LENGTH = 16;

    // ===== 양방향 암호화 (AES-128-GCM) =====

    /**
     * AES-128-GCM 암호화 (고유식별정보용)
     * - 주민등록번호
     * - 여권번호
     * - 운전면허번호
     * - 외국인등록번호
     */
    public String encryptAes(String plainText) {
        if (plainText == null || plainText.isEmpty()) {
            return null;
        }

        try {
            // 키 생성
            SecretKey secretKey = generateAesKey();

            // IV 생성 (매번 랜덤)
            byte[] iv = new byte[GCM_IV_LENGTH];
            SecureRandom random = new SecureRandom();
            random.nextBytes(iv);

            // 암호화
            Cipher cipher = Cipher.getInstance(AES_ALGORITHM);
            GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, parameterSpec);

            byte[] cipherText = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

            // IV + CipherText 결합
            byte[] combined = new byte[iv.length + cipherText.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(cipherText, 0, combined, iv.length, cipherText.length);

            String encrypted = Base64.getEncoder().encodeToString(combined);
            log.debug("AES 암호화 완료: plainLength={}, encryptedLength={}",
                plainText.length(), encrypted.length());

            return encrypted;

        } catch (Exception e) {
            log.error("AES 암호화 실패: {}", e.getMessage());
            throw new RuntimeException("암호화 실패", e);
        }
    }

    /**
     * AES-128-GCM 복호화
     */
    public String decryptAes(String encryptedText) {
        if (encryptedText == null || encryptedText.isEmpty()) {
            return null;
        }

        try {
            // Base64 디코딩
            byte[] combined = Base64.getDecoder().decode(encryptedText);

            // IV 추출
            byte[] iv = new byte[GCM_IV_LENGTH];
            System.arraycopy(combined, 0, iv, 0, iv.length);

            // CipherText 추출
            byte[] cipherText = new byte[combined.length - GCM_IV_LENGTH];
            System.arraycopy(combined, GCM_IV_LENGTH, cipherText, 0, cipherText.length);

            // 키 생성
            SecretKey secretKey = generateAesKey();

            // 복호화
            Cipher cipher = Cipher.getInstance(AES_ALGORITHM);
            GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, parameterSpec);

            byte[] plainText = cipher.doFinal(cipherText);

            String decrypted = new String(plainText, StandardCharsets.UTF_8);
            log.debug("AES 복호화 완료");

            return decrypted;

        } catch (Exception e) {
            log.error("AES 복호화 실패: {}", e.getMessage());
            throw new RuntimeException("복호화 실패", e);
        }
    }

    /**
     * AES 키 생성 (PBKDF2)
     */
    private SecretKey generateAesKey() throws Exception {
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        PBEKeySpec spec = new PBEKeySpec(
            aesSecretKey.toCharArray(),
            aesSalt.getBytes(StandardCharsets.UTF_8),
            ITERATION_COUNT,
            AES_KEY_SIZE
        );
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }

    // ===== 단방향 암호화 (SHA-256 + Salt) =====

    /**
     * SHA-256 해시 (비밀번호용)
     * Salt를 포함하여 레인보우 테이블 공격 방지
     */
    public String hashPassword(String password) {
        if (password == null || password.isEmpty()) {
            return null;
        }

        try {
            // Salt 생성
            byte[] salt = new byte[SALT_LENGTH];
            SecureRandom random = new SecureRandom();
            random.nextBytes(salt);

            // SHA-256 해시
            MessageDigest md = MessageDigest.getInstance(SHA_ALGORITHM);
            md.update(salt);
            byte[] hashedPassword = md.digest(password.getBytes(StandardCharsets.UTF_8));

            // Salt + Hash 결합
            byte[] combined = new byte[salt.length + hashedPassword.length];
            System.arraycopy(salt, 0, combined, 0, salt.length);
            System.arraycopy(hashedPassword, 0, combined, salt.length, hashedPassword.length);

            String hashed = Base64.getEncoder().encodeToString(combined);
            log.debug("SHA-256 해시 완료");

            return hashed;

        } catch (Exception e) {
            log.error("SHA-256 해시 실패: {}", e.getMessage());
            throw new RuntimeException("해시 실패", e);
        }
    }

    /**
     * 비밀번호 검증
     */
    public boolean verifyPassword(String password, String storedHash) {
        if (password == null || storedHash == null) {
            return false;
        }

        try {
            // 저장된 해시에서 Salt 추출
            byte[] combined = Base64.getDecoder().decode(storedHash);
            byte[] salt = new byte[SALT_LENGTH];
            System.arraycopy(combined, 0, salt, 0, salt.length);

            // 입력된 비밀번호 해시
            MessageDigest md = MessageDigest.getInstance(SHA_ALGORITHM);
            md.update(salt);
            byte[] hashedInput = md.digest(password.getBytes(StandardCharsets.UTF_8));

            // 저장된 해시와 비교
            byte[] storedHashBytes = new byte[combined.length - SALT_LENGTH];
            System.arraycopy(combined, SALT_LENGTH, storedHashBytes, 0, storedHashBytes.length);

            return MessageDigest.isEqual(hashedInput, storedHashBytes);

        } catch (Exception e) {
            log.error("비밀번호 검증 실패: {}", e.getMessage());
            return false;
        }
    }

    // ===== 고유식별정보 암호화 헬퍼 메서드 =====

    /**
     * 주민등록번호 암호화
     */
    public String encryptSsn(String ssn) {
        log.info("주민등록번호 암호화");
        return encryptAes(ssn);
    }

    /**
     * 주민등록번호 복호화
     */
    public String decryptSsn(String encryptedSsn) {
        log.info("주민등록번호 복호화");
        return decryptAes(encryptedSsn);
    }

    /**
     * 여권번호 암호화
     */
    public String encryptPassportNumber(String passportNumber) {
        log.info("여권번호 암호화");
        return encryptAes(passportNumber);
    }

    /**
     * 여권번호 복호화
     */
    public String decryptPassportNumber(String encryptedPassportNumber) {
        log.info("여권번호 복호화");
        return decryptAes(encryptedPassportNumber);
    }

    /**
     * 운전면허번호 암호화
     */
    public String encryptDriverLicense(String driverLicense) {
        log.info("운전면허번호 암호화");
        return encryptAes(driverLicense);
    }

    /**
     * 운전면허번호 복호화
     */
    public String decryptDriverLicense(String encryptedDriverLicense) {
        log.info("운전면허번호 복호화");
        return decryptAes(encryptedDriverLicense);
    }

    /**
     * 외국인등록번호 암호화
     */
    public String encryptForeignerId(String foreignerId) {
        log.info("외국인등록번호 암호화");
        return encryptAes(foreignerId);
    }

    /**
     * 외국인등록번호 복호화
     */
    public String decryptForeignerId(String encryptedForeignerId) {
        log.info("외국인등록번호 복호화");
        return decryptAes(encryptedForeignerId);
    }

    /**
     * 신용카드번호 암호화
     */
    public String encryptCreditCard(String creditCardNumber) {
        log.info("신용카드번호 암호화");
        return encryptAes(creditCardNumber);
    }

    /**
     * 신용카드번호 복호화
     */
    public String decryptCreditCard(String encryptedCreditCard) {
        log.info("신용카드번호 복호화");
        return decryptAes(encryptedCreditCard);
    }

    /**
     * 은행계좌번호 암호화
     */
    public String encryptBankAccount(String bankAccount) {
        log.info("은행계좌번호 암호화");
        return encryptAes(bankAccount);
    }

    /**
     * 은행계좌번호 복호화
     */
    public String decryptBankAccount(String encryptedBankAccount) {
        log.info("은행계좌번호 복호화");
        return decryptAes(encryptedBankAccount);
    }

    /**
     * 서비스 상태 조회
     */
    public java.util.Map<String, Object> getStatus() {
        return java.util.Map.of(
            "service", "DatabaseEncryptionService",
            "algorithms", java.util.Map.of(
                "symmetric", "AES-128-GCM",
                "hash", "SHA-256 + Salt"
            ),
            "keyDerivation", "PBKDF2WithHmacSHA256",
            "iterationCount", ITERATION_COUNT,
            "compliance", java.util.List.of(
                "개인정보보호법 제24조",
                "개인정보보호법 제29조",
                "행정안전부 시큐어코딩 가이드라인"
            ),
            "encryptedFields", java.util.List.of(
                "주민등록번호 (양방향)",
                "여권번호 (양방향)",
                "운전면허번호 (양방향)",
                "외국인등록번호 (양방향)",
                "신용카드번호 (양방향)",
                "은행계좌번호 (양방향)",
                "비밀번호 (단방향)"
            ),
            "status", "ACTIVE"
        );
    }
}
