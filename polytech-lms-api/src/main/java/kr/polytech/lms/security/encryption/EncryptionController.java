// polytech-lms-api/src/main/java/kr/polytech/lms/security/encryption/EncryptionController.java
package kr.polytech.lms.security.encryption;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Encryption REST Controller
 * DB 암호화 API
 */
@Slf4j
@RestController
@RequestMapping("/api/security/encryption")
@RequiredArgsConstructor
public class EncryptionController {

    private final DatabaseEncryptionService encryptionService;

    /**
     * 양방향 암호화 (AES-128-GCM)
     */
    @PostMapping("/encrypt")
    public ResponseEntity<?> encrypt(@RequestBody Map<String, String> request) {
        String plainText = request.get("data");
        String type = request.getOrDefault("type", "general");

        String encrypted = switch (type.toLowerCase()) {
            case "ssn" -> encryptionService.encryptSsn(plainText);
            case "passport" -> encryptionService.encryptPassportNumber(plainText);
            case "driver_license" -> encryptionService.encryptDriverLicense(plainText);
            case "foreigner_id" -> encryptionService.encryptForeignerId(plainText);
            case "credit_card" -> encryptionService.encryptCreditCard(plainText);
            case "bank_account" -> encryptionService.encryptBankAccount(plainText);
            default -> encryptionService.encryptAes(plainText);
        };

        return ResponseEntity.ok(Map.of(
            "success", true,
            "encrypted", encrypted,
            "algorithm", "AES-128-GCM",
            "type", type
        ));
    }

    /**
     * 양방향 복호화 (AES-128-GCM)
     */
    @PostMapping("/decrypt")
    public ResponseEntity<?> decrypt(@RequestBody Map<String, String> request) {
        String encryptedText = request.get("data");
        String type = request.getOrDefault("type", "general");

        String decrypted = switch (type.toLowerCase()) {
            case "ssn" -> encryptionService.decryptSsn(encryptedText);
            case "passport" -> encryptionService.decryptPassportNumber(encryptedText);
            case "driver_license" -> encryptionService.decryptDriverLicense(encryptedText);
            case "foreigner_id" -> encryptionService.decryptForeignerId(encryptedText);
            case "credit_card" -> encryptionService.decryptCreditCard(encryptedText);
            case "bank_account" -> encryptionService.decryptBankAccount(encryptedText);
            default -> encryptionService.decryptAes(encryptedText);
        };

        return ResponseEntity.ok(Map.of(
            "success", true,
            "decrypted", decrypted,
            "algorithm", "AES-128-GCM",
            "type", type
        ));
    }

    /**
     * 단방향 해시 (SHA-256 + Salt) - 비밀번호
     */
    @PostMapping("/hash-password")
    public ResponseEntity<?> hashPassword(@RequestBody Map<String, String> request) {
        String password = request.get("password");

        String hashed = encryptionService.hashPassword(password);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "hashed", hashed,
            "algorithm", "SHA-256 + Salt",
            "note", "단방향 해시, 복호화 불가"
        ));
    }

    /**
     * 비밀번호 검증
     */
    @PostMapping("/verify-password")
    public ResponseEntity<?> verifyPassword(@RequestBody Map<String, String> request) {
        String password = request.get("password");
        String storedHash = request.get("storedHash");

        boolean valid = encryptionService.verifyPassword(password, storedHash);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "valid", valid,
            "message", valid ? "비밀번호가 일치합니다." : "비밀번호가 일치하지 않습니다."
        ));
    }

    /**
     * 암호화 서비스 상태
     */
    @GetMapping("/status")
    public ResponseEntity<?> getStatus() {
        return ResponseEntity.ok(encryptionService.getStatus());
    }
}
