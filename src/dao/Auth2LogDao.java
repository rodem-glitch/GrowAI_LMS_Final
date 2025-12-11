package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

import java.math.BigInteger;
import java.util.Random;
import java.util.Arrays;
import java.util.Date;
import java.io.Writer;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.security.SecureRandom;
import java.security.GeneralSecurityException;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.jsp.JspWriter;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.binary.Base32;
import org.json.JSONObject;

public class Auth2LogDao extends DataObject {

    private static final String BASE_URL = "https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=";

    private int siteId = 0;
    private String sessionType = "user";
    private int currTime = 0;
    private DataSet info = null;

    public Auth2LogDao(int siteId, String seesionType) {
        this.table = "TB_AUTH2_LOG";
        this.siteId = siteId;
        this.sessionType = seesionType;
    }

    public Auth2LogDao() {
        this.table = "TB_AUTH2_LOG";
    }

    public void setSiteId(int siteId) {
        this.siteId = siteId;
    }

    public void setSessionType(String sessionType) {
        this.sessionType = sessionType;
    }

    public void setCurrTime(int currTime) {
        this.currTime = currTime;
    }

    public int add(int userId) {
        if(this.info == null || userId == 0) return 0;
        this.item("auth2_type", this.info.s("auth2_type"));
        this.item("session_type", this.sessionType);
        this.item("user_id", userId);
        this.item("input_no", this.info.s("input_no"));
        this.item("auth2_no", this.info.s("auth2_no"));
        this.item("auth2_date", this.info.s("auth2_date"));
        this.item("success_yn", this.info.s("success_yn"));
        this.item("reg_date", Malgn.time());
        this.item("site_id", this.siteId);
        this.item("status", 1);
        return this.insert(true);
    }

    public void setInfo(String auth2Type, String inputNo, String auth2No, String auth2Date, String successYn) {
        this.info = new DataSet();
        this.info.addRow();
        this.info.put("auth2_type", auth2Type);
        this.info.put("input_no", inputNo);
        this.info.put("auth2_no", auth2No);
        this.info.put("auth2_date", auth2Date);
        this.info.put("success_yn", successYn);
    }

    public JSONObject generateBarcode(String user, String siteNm) {
        JSONObject map = null;
        try {
            map = new JSONObject();
            byte[] buffer = new byte[5 + 5 * 5];
            new SecureRandom().nextBytes(buffer);

            Base32 codec = new Base32();
            byte[] secretKey = Arrays.copyOf(buffer, 10);
            byte[] bEncodedKey = codec.encode(secretKey);
            String encodedKey = new String(bEncodedKey);

            map.put("encoded_key", encodedKey);
            map.put("site_nm", siteNm);
            map.put("login_id", user);
            map.put("barcode_url", getGoogleOTPBarCode(encodedKey, user, siteNm));

        } catch (RuntimeException re) {
            Malgn.errorLog("RuntimeException " + re.getMessage(), re);
        } catch (Exception e) {
            Malgn.errorLog("Exception " + e.getMessage(), e);
        }
        return map;
    }

    private String getGoogleOTPBarCode(String key, String user, String siteNm) {
        String ret = "";
        try {
            ret = BASE_URL + "otpauth://totp/"
                    + URLEncoder.encode(siteNm + "-" + user, "UTF-8").replace("+", "%20")
                    + "?secret=" + URLEncoder.encode(key, "UTF-8").replace("+", "%20")
                    + "&issuer=" + URLEncoder.encode(siteNm, "UTF-8").replace("+", "%20");
        } catch (UnsupportedEncodingException uee) {
            Malgn.errorLog("UnsupportedEncodingException " + uee.getMessage(), uee);
        }

        return ret;
    }

    public boolean verifyAuthNo(int authNo, String key) {

        return (getHash(key, authNo) == authNo);
    }

    public int getHash(String key, int authNo) {
        long wave = new Date().getTime() / 30000;
        byte[] decodedKey = new Base32().decode(key);
        int window = 3;
        int hash = 0;
        for (int i = -window; i <= window; ++i) {
            hash = getVerifyAuthNo(decodedKey, wave + i);
            if(hash == authNo) break;
        }

        return hash;
    }

    private int getVerifyAuthNo(byte[] key, long t) {
        byte[] data = new byte[8];
        long value = t;
        for (int i = 8; i-- > 0; value >>>= 8) {
            data[i] = (byte) value;
        }

        byte[] hash = hmacSHA1(key, data);
        int offset = hash[20 - 1] & 0xF;

        long truncatedHash = 0;
        for (int i = 0; i < 4; ++i) {
            truncatedHash <<= 8;

            truncatedHash |= (hash[offset + i] & 0xFF);
        }
        truncatedHash &= 0x7FFFFFFF;
        truncatedHash %= 1000000;

        return (int) truncatedHash;
    }

    private byte[] hmacSHA1(final byte[] keyBytes, final byte[] text) {
        byte[] ret = null;
        try {
            final Mac hmac = Mac.getInstance("HmacSHA1");
            final SecretKeySpec macKey = new SecretKeySpec(keyBytes, "RAW");
            hmac.init(macKey);
            ret = hmac.doFinal(text);
        } catch (GeneralSecurityException gse) {
            Malgn.errorLog("GeneralSecurityException " + gse.getMessage(), gse);
        }
        return ret;
    }

    public void writeMessage(String msg, String status, Object out) {
        try {
            JSONObject obj = new JSONObject();
            JspWriter jout = (JspWriter) out;
            obj.put("message", msg);
            obj.put("status", status);
            if(!"".equals(this.currTime)) obj.put("curr_time", this.currTime);
            jout.write(obj.toString());
        } catch(RuntimeException re) {
            Malgn.errorLog("RuntimeException " + re.getMessage(), re);
        } catch(Exception e) {
            Malgn.errorLog("Exception " + e.getMessage(), e);
        }
    }

    public String getTimeString(int seconds) {
        return (seconds / 60) + "분 " + (seconds % 60)+ "초";
    }

}