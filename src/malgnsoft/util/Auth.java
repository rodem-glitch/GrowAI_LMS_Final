package malgnsoft.util;

import java.util.*;
import java.text.SimpleDateFormat;
import java.net.URLEncoder;
import java.net.URLDecoder;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class Auth {

	private final HttpServletRequest request;
	private final HttpServletResponse response;
	private HttpSession session;
	private static final String encoding = Config.getEncoding();
	private static final String secretId = Config.getSecretId();
	private final Hashtable<String, String> data;

	public String keyName = "AUTHID";
	public String loginURL = "../member/login.jsp";
	public String domain = null;
	public int validTime = -1;
	public int maxAge = -1;
	private boolean secure = false;
	private boolean httpOnly = false;
	private String sameSite = null;
	private String path = "/";

	public Auth(HttpServletRequest request, HttpServletResponse response) {
		this.request = request;
		this.response = response;
		this.data = new Hashtable<String, String>();
	}

	public Auth(HttpServletRequest request, HttpServletResponse response, HttpSession session) {
		this.request = request;
		this.response = response;
		this.session = session;
		this.data = new Hashtable<String, String>();
	}

	public void setLoginURL(String url) {
		this.loginURL = url;
	}

	public void setKeyName(String key) {
		this.keyName = key;
	}

	public void setPath(String p) {
		this.path = p;
	}

	public void setDomain(String dom) {
		this.domain = dom;
	}

	public void setSecure(boolean sc) {
		this.secure = sc;
	}

	public void setSecureCookie(boolean sc) {
		this.secure = sc;
	}

	public void setSameSite(String ss) {
		this.sameSite = ss;
	}

	public void setHttpOnly(boolean ho) {
		this.httpOnly = ho;
	}

	public void setValidTime(int second) {
		this.validTime = second;
	}

	public void setMaxAge(int second) {
		this.maxAge = second;
	}

	public void loginForm() {
		this.loginForm(this.loginURL);
	}

	public void loginForm(String url) {
		int port = request.getServerPort();
		String query = request.getQueryString();

		String uri = request.getRequestURI();
		if(query != null) uri += "?" +query;

		try {
			response.sendRedirect(url + (!url.contains("?") ? "?" : "&") + "returl=" + uri);
		} catch(Exception e) {
			Malgn.errorLog("{Auth.loginForm}" + e.getMessage(), e);
		}
	}

	public boolean isValid() {
		String authString = null;
		try {
			if(session == null) {
				Cookie[] cookies = request.getCookies();
				if(cookies !=null) {
					for (Cookie cookie : cookies) {
						if (cookie.getName().equals(keyName)) {
							authString = cookie.getValue();
						}
					}
				}
			} else {
				authString = (String)session.getAttribute(keyName);
			}
		} catch(Exception e) {
			Malgn.errorLog("{Auth.isValid}" + e.getMessage(), e);
		}
		return parse(authString);
	}

	public int getInt(String name) {
		int ret = 0;
		try {
			ret = Integer.parseInt(data.get(name));
		} catch(Exception e) {
			Malgn.errorLog("{Auth.getInt} " + e.getMessage(), e);
		}
		return ret;
	}

	public String getString(String name) {
		return data.get(name) == null ? "" : data.get(name);
	}

	public void put(String name, String value) {
		data.put(name, value);
	}

	public void put(String name, int i) {
		put(name, "" + i);
	}

	public void save() {
		try {
			StringBuilder sb = new StringBuilder();
			Set<String> keys = data.keySet();
			for(String key : keys) {
				sb.append(URLEncoder.encode(key, "UTF-8")).append("=").append(URLEncoder.encode(data.get(key), "UTF-8")).append("|");
			}
			String info = SimpleAES.encrypt(sb.toString() + System.currentTimeMillis());
			String ek = Malgn.sha256(info + secretId);

			if(session == null) {
				Cookie cookie = new Cookie(keyName, ek + "|" + info);
				cookie.setPath(path);
				if(maxAge != -1) cookie.setMaxAge(maxAge);
				if(domain != null) cookie.setDomain(domain);
				if(secure) cookie.setSecure(true);
				if(sameSite == null) response.addCookie(cookie);
				else {
					StringBuilder c = new StringBuilder();
					c.append(cookie.getName());
					c.append("=");
					c.append(cookie.getValue());
					c.append("; Path="); c.append(path);
					c.append("; SameSite="); c.append(sameSite);
					if(secure || "none".equalsIgnoreCase(sameSite)) { c.append("; Secure"); }
					if(httpOnly) { c.append("; HttpOnly"); }
					if(domain != null) { c.append("; Domain="); c.append(cookie.getDomain()); }
					if(maxAge != -1) { c.append("; Max-Age="); c.append(cookie.getMaxAge()); }
					response.addHeader("Set-Cookie", c.toString());
				}
			} else {
				session.setAttribute(keyName, ek + "|" + info);
			}
		} catch(Exception e) {
			Malgn.errorLog("{Auth.save}" + e.getMessage(), e);
		}
	}

	public boolean parse(String authString) {
		if(authString == null) return false;
		try {

			String[] arr;
			String[] arr1 = Malgn.split("|", authString);
			if(arr1.length != 2) return false;

			if(arr1[0].length() == 64 && arr1[0].equals(Malgn.sha256(arr1[1] + secretId))) {
				arr = Malgn.split("|", SimpleAES.decrypt(arr1[1]));
			} else if(arr1[0].length() == 32 && arr1[0].equals(Malgn.md5(arr1[1] + secretId))) {
				try { arr = Malgn.split("|", Base64Coder.decode(arr1[1])); }
				catch(Exception e) { arr = Malgn.split("|", SimpleAES.decrypt(arr1[1])); }
			} else return false;
			if(arr.length < 2) return false;

			for (String s : arr) {
				String[] arr2 = Malgn.split("=", s);
				if (arr2.length == 2)
					data.put(URLDecoder.decode(arr2[0], "UTF-8"), URLDecoder.decode(arr2[1], "UTF-8"));
			}
			if(validTime == -1) return true;
			if(System.currentTimeMillis() <= (Long.parseLong(arr[arr.length - 1]) + validTime * 1000L)) {
				save();
				return true;
			}
		} catch(Exception e) {
			Malgn.errorLog("{Auth.parse} " + e.getMessage(), e);
		}
		return false;
	}

	public void delete() {
		if(session == null) {
			Cookie cookie = new Cookie(keyName, "");
			cookie.setMaxAge(0);
			cookie.setPath("/");
			if(domain != null) cookie.setDomain(domain);
			response.addCookie(cookie);
		} else {
			session.removeAttribute(keyName);
		}
	}

	public void setAuthInfo() { save(); }
	public void delAuthInfo() { delete(); }

}