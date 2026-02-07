package kr.polytech.lms.user.service;

import malgnsoft.db.DataSet;
import malgnsoft.util.Aes256;
import dao.UserDao;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional; // For transactional operations
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserDao userDao; // Assuming UserDao can be instantiated or managed
    private final Aes256 aes256;

    // Spring will auto-wire Aes256 bean and try to instantiate UserDao
    // If UserDao needs custom instantiation, a @Bean for UserDao should be provided in PolytechLmsApiApplication
    public UserService(Aes256 aes256) {
        this.aes256 = Objects.requireNonNull(aes256, "Aes256 cannot be null");
        this.userDao = new UserDao(); // Assuming default constructor works
    }

    public DataSet getUserById(int userId) throws Exception {
        DataSet user = userDao.find("id = ?", userId);
        if (user.next()) {
            decryptSensitiveInfo(user);
        }
        return user;
    }

    public DataSet getUserByLoginId(String loginId) throws Exception {
        DataSet user = userDao.find("login_id = ?", loginId);
        if (user.next()) {
            decryptSensitiveInfo(user);
        }
        return user;
    }

    @Transactional
    public boolean updateMobile(int userId, String newMobile) throws Exception {
        if (newMobile == null || newMobile.trim().isEmpty()) {
            userDao.item("mobile", ""); // Store empty string if mobile is null/empty
        } else {
            String encryptedMobile = aes256.encrypt(newMobile.trim());
            userDao.item("mobile", encryptedMobile);
        }
        return userDao.update("id = ?", userId);
    }

    @Transactional
    public boolean createUser(Map<String, String> userData) throws Exception {
        if (userData.containsKey("mobile")) {
            String mobile = userData.get("mobile");
            if (mobile != null && !mobile.trim().isEmpty()) {
                userData.put("mobile", aes256.encrypt(mobile.trim()));
            } else {
                userData.put("mobile", "");
            }
        }
        // Assuming userData contains other fields for creation
        // This part needs more context on how malgnsoft.db.DataObject handles inserts
        // For now, let's assume item() is used for all fields.
        for (Map.Entry<String, String> entry : userData.entrySet()) {
            userDao.item(entry.getKey(), entry.getValue());
        }
        return userDao.insert();
    }


    private void decryptSensitiveInfo(DataSet user) throws Exception {
        // Decrypt MOBILE field if it exists and looks encrypted
        String mobile = user.s("mobile");
        if (mobile != null && !mobile.trim().isEmpty() && Aes256.isBase64(mobile)) {
            try {
                user.put("mobile", aes256.decrypt(mobile));
            } catch (Exception e) {
                log.warn("Failed to decrypt mobile for user ID {}: {}", user.i("id"), e.getMessage());
                // Keep original encrypted value or clear it if decryption fails
                user.put("mobile", "");
            }
        }
        // TODO: Other sensitive fields like DUPINFO might need similar decryption
    }

    private void encryptSensitiveInfo(Map<String, String> userData) throws Exception {
        // Encrypt MOBILE field if it exists
        if (userData.containsKey("mobile")) {
            String mobile = userData.get("mobile");
            if (mobile != null && !mobile.trim().isEmpty() && !Aes256.isBase64(mobile)) { // Don't re-encrypt if already encrypted
                userData.put("mobile", aes256.encrypt(mobile.trim()));
            }
        }
        // TODO: Other sensitive fields like DUPINFO might need similar encryption
    }
}
