package malgnsoft.util;

import java.util.Base64;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class Aes256 {
    public static String alg = "AES/CBC/PKCS5Padding";
    private final String key;
    private final String iv;

    public Aes256(String key, String iv) {
        if (key == null || key.length() != 32) {
            throw new IllegalArgumentException("AES Key must be 32 bytes (256 bits).");
        }
        if (iv == null || iv.length() != 16) {
            throw new IllegalArgumentException("AES IV must be 16 bytes (128 bits).");
        }
        this.key = key;
        this.iv = iv;
    }

    public String encrypt(String text) throws Exception {
        Cipher cipher = Cipher.getInstance(alg);
        SecretKeySpec keySpec = new SecretKeySpec(key.getBytes(), "AES");
        IvParameterSpec ivParamSpec = new IvParameterSpec(iv.getBytes());
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivParamSpec);

        byte[] encrypted = cipher.doFinal(text.getBytes("UTF-8"));
        return Base64.getEncoder().encodeToString(encrypted);
    }

    public String decrypt(String cipherText) throws Exception {
        Cipher cipher = Cipher.getInstance(alg);
        SecretKeySpec keySpec = new SecretKeySpec(key.getBytes(), "AES");
        IvParameterSpec ivParamSpec = new IvParameterSpec(iv.getBytes());
        cipher.init(Cipher.DECRYPT_MODE, keySpec, ivParamSpec);

        String decodeString = "";
        try {
            byte[] decodedBytes = Base64.getDecoder().decode(cipherText);
            byte[] decrypted = cipher.doFinal(decodedBytes);
            decodeString = new String(decrypted, "UTF-8");
        } catch (IllegalBlockSizeException e) {
            decodeString = cipherText;
        } catch (BadPaddingException e) {
            decodeString = cipherText;
        }
        return decodeString;
    }

    public static boolean isBase64(String str) {
        try {
            Base64.getDecoder().decode(str);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
