package dao;

import java.io.*;
import java.util.*;
import java.net.*;
import malgnsoft.db.DataSet;
import malgnsoft.util.Malgn;
import malgnsoft.util.Config;
import malgnsoft.util.Json;
import malgnsoft.util.Http;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class SnsLogin {

    public String errMsg = null;
    private Writer out = null;
    private boolean debug = false;

    private HttpServletRequest request;
    private HttpServletResponse response;
    private HttpSession session;

    private String webUrl = "";
    private String vendor = "";
    private String clientId = "";
    private String clientSecret = "";
    private String callbackUrl = "";

    private static final Map<String, String> api = new HashMap<String, String>();

    public SnsLogin(HttpServletRequest req, HttpSession sess) {
        this.request = req;
        this.session = sess;
        this.webUrl = req.getScheme() + "://" + req.getServerName();
    }

    public void setDebug(Writer out) {
        this.out = out;
        this.debug = true;
    }

    public void setDebug() {
        this.out = null;
        this.debug = true;
    }

    private void setError(String msg) {
        this.errMsg = msg;
        if(debug == true) {
            try {
                if(null != out) out.write("<hr>" + msg + "<hr>\n");
                else Malgn.errorLog(msg);
            } catch(NullPointerException npe) {
                Malgn.errorLog("NullPointerException : " + npe.getMessage(), npe);
            } catch(Exception e) {
                Malgn.errorLog("Exception : " + e.getMessage(), e);
            }
        }
    }

    public void setClient(String ven, String id, String secret) {;
        setClient(ven, id, secret, null);
    }

    public void setClient(String ven, String id, String secret, String callback) {
        this.vendor = ven;
        this.clientId = id;
        this.clientSecret = secret;
        this.callbackUrl = callback != null ? callback : webUrl + "/member/login_" + vendor + ".jsp";
        getVendorApi(ven);
    }

    public void setClientId(String id) {
        this.clientId = id;
    }

    public Map<String, String> getVendorApi(String ven) {
        if(!api.containsKey(ven + "_authorize")) {
            DataSet rs = Config.getDataSet("//config/oauth2/vendor");
            while(rs.next()) {
                if(rs.s("vendorName").equals(ven)) {
                    api.put(ven + "_authorize", rs.s("authorize"));
                    api.put(ven + "_token", rs.s("token"));
                    api.put(ven + "_profile", rs.s("profile"));
                    api.put(ven + "_scope", rs.s("scope"));
                }
            }
        }
        return api;
    }

    public void remove(String ven) {
        if(ven != null) {
            api.remove(ven + "_authorize");
            api.remove(ven + "_token");
            api.remove(ven + "_profile");
            api.remove(ven + "_scope");
        } else {
            api.clear();
        }
    }

    public String getUniqState() {
        String state = (String)session.getAttribute("OAUTH_STATE");
        if(state == null) {
            state = Malgn.getUniqId();
            session.setAttribute("OAUTH_STATE", state);
        }
        return state;
    }

    public boolean isValidState(String s) {
        return getUniqState().equals(s);
    }

    public String getAuthUrl() {
        return getAuthUrl(null);
    }

    public String getAuthUrl(String ven) {
        if(ven != null) this.vendor = ven;
        String url = api.get(this.vendor + "_authorize");
        String scope = api.get(this.vendor + "_scope");
        if(url == null) {
            setError("Auth URL of " + this.vendor + " is not exists");
            return "";
        }
        url += "?response_type=code&client_id=" + this.clientId + "&redirect_uri=" + this.callbackUrl + "&state=" + getUniqState() + (!"".equals(scope) ? "&scope=" + scope : "");
        return url;
    }

    public String getAccessToken(String code) {
        String url = api.get(vendor + "_token");
        try {
            Http http = new Http(url);
            if(debug) http.setDebug(out);
            http.setParam("grant_type", "authorization_code");
            http.setParam("client_id", this.clientId);
            http.setParam("client_secret", this.clientSecret);
            http.setParam("redirect_uri", this.callbackUrl);
            http.setParam("code", code);
            http.setParam("state", getUniqState());
            String body = http.send("POST");

            DataSet ret = Json.decode(body);
            setError(ret.toString());
            ret.next();

            return ret.s("access_token");
        } catch(RuntimeException re) {
            Malgn.errorLog("RuntimeException " + re.getMessage(), re);
            return "";
        } catch(Exception e) {
            Malgn.errorLog("{SnsLogin.getAccessToken} " + e.getMessage(), e);
            return "";
        }
    }

    public HashMap<String, Object> getProfile(String code) {

        String token = getAccessToken(code);
        if("".equals(token)) {
            setError("Token is null");
            return null;
        }

        String url = api.get(vendor + "_profile");
        try {
            Http http = new Http(url);
            if(debug) http.setDebug(out);
            http.setHeader("Authorization", "Bearer " + token);
            if("facebook".equals(vendor)) http.setParam("fields", "email,name,gender");

            HashMap<String, Object> ret = Json.toMap(http.send("GET"));
            setError(ret.toString());

            if(!"naver".equals(vendor)) return ret;

            if("00".equals((String)ret.get("resultcode")) && ret.get("response") instanceof HashMap) {
                HashMap<?, ?> map = (HashMap<?, ?>)ret.get("response");
                for(Object key : map.keySet()) ret.put((String)key, map.get(key));
                return ret;
            } else {
                setError((String)ret.get("message"));
                return null;
            }
        } catch(RuntimeException re) {
            Malgn.errorLog("RuntimeException " + re.getMessage(), re);
            return null;
        } catch(Exception e) {
            Malgn.errorLog("Exception " + e.getMessage(), e);
            return null;
        }
    }

}