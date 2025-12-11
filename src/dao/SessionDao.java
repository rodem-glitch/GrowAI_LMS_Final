package dao;

import malgnsoft.util.*;

import java.util.*;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.net.URLDecoder;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

final public class SessionDao {

	private HttpServletRequest request;
	private HttpServletResponse response;
	private HttpSession session;
	private static final String encoding = Config.getEncoding();
	private static final String secretId = Config.getSecretId();
	private final Hashtable<String, String> data;

	private String keyName = "_sessdata";
	public String domain = null;
	public int validTime = -1;
	public int maxAge = -1;
	private String path = "/";

	public SessionDao(HttpServletRequest request, HttpServletResponse response) {
		this.request = request;
		session = this.request.getSession(true);
		this.response = response;
		this.data = new Hashtable<String, String>();
		getSessionData();
	}

	public SessionDao(HttpServletRequest request, HttpServletResponse response, String keyName, int maxAge) {
		this.request = request;
		session = this.request.getSession(true);
		this.response = response;
		this.keyName = keyName;
		this.maxAge = maxAge;
		this.data = new Hashtable<String, String>();
		getSessionData();
	}

	public void setKeyName(String key) {
		this.keyName = key;
	}

	public void setValidTime(int second) {
		this.validTime = second;
	}

	public void setMaxAge(int second) {
		this.maxAge = second;
	}

	private void getSessionData() {
		String dataString = null;
		try {
			if(!session.isNew()) {
				Enumeration attributes = session.getAttributeNames();
				while (attributes.hasMoreElements()) {
					String attribute = (String) attributes.nextElement();
					if(attribute.equals(keyName)) {
						dataString = session.getAttribute(attribute).toString();
					}
				}
			}

			if (dataString == null) {
				String sessionId = Malgn.sha256("" + System.currentTimeMillis() + Malgn.getUniqId());
				put("id", sessionId);
				save();
				return;
			}

			String[] arr;
			String[] arr1 = Malgn.split("|", dataString);
			if (arr1.length != 2) return;

			if (arr1[0].length() == 64 && arr1[0].equals(Malgn.sha256(arr1[1] + secretId))) {
				arr = Malgn.split("|", SimpleAES.decrypt(arr1[1]));
			} else if (arr1[0].length() == 32 && arr1[0].equals(Malgn.md5(arr1[1] + secretId))) {
				try {
					arr = Malgn.split("|", Base64Coder.decode(arr1[1]));
				} catch (IllegalArgumentException iae) {
					arr = Malgn.split("|", SimpleAES.decrypt(arr1[1]));
				} catch (Exception e) {
					arr = Malgn.split("|", SimpleAES.decrypt(arr1[1]));
				}
			} else return;
			if (arr.length < 2) return;

			for (String s : arr) {
				String[] arr2 = Malgn.split("=", s);
				if (arr2.length == 2)
					data.put(URLDecoder.decode(arr2[0], "UTF-8"), URLDecoder.decode(arr2[1], "UTF-8"));
			}
			if (validTime == -1) return;
			if (System.currentTimeMillis() <= (Long.parseLong(arr[arr.length - 1]) + validTime * 1000L)) {
				save();
			}
		} catch(NullPointerException npe) {
			Malgn.errorLog("{SessionDao.getSessionData::npe}" + npe.getMessage(), npe);
		} catch(UnsupportedEncodingException uee) {
			Malgn.errorLog("{SessionDao.getSessionData::uee}" + uee.getMessage(), uee);
		} catch(Exception e) {
			Malgn.errorLog("{SessionDao.getSessionData::e}" + e.getMessage(), e);
		}
	}

	public boolean delSession() {
		session.invalidate();
		return true;
	}

	public String getData() { return data.toString(); }

	public void save() {
		try {
			StringBuilder sb = new StringBuilder();
			Set<String> keys = data.keySet();
			for (String key : keys) {
				sb.append(URLEncoder.encode(key, "UTF-8")).append("=").append(URLEncoder.encode(data.get(key), "UTF-8")).append("|");
			}
			String info = SimpleAES.encrypt(sb.toString() + System.currentTimeMillis());
			String ek = Malgn.sha256(info + secretId);

			session.setAttribute(keyName, ek + "|" + info);
			if(maxAge != -1) session.setMaxInactiveInterval(maxAge);
		} catch(NullPointerException npe) {
			Malgn.errorLog("{SessionDao.save::npe}" + npe.getMessage(), npe);
		} catch(UnsupportedEncodingException uee) {
			Malgn.errorLog("{SessionDao.save::uee}" + uee.getMessage(), uee);
		} catch(Exception e) {
			Malgn.errorLog("{SessionDao.save::e}" + e.getMessage(), e);
		}
	}

	public String s(String key) {
		return getString(key);
	}

	public int i(String key) {
		return getInt(key);
	}

	public int getInt(String name) {
		int ret = 0;
		try {
			ret = null != data.get(name) ? Integer.parseInt(data.get(name)) : 0;
		} catch(NumberFormatException nfe) {
			Malgn.errorLog("{SessionDao.getInt::nfe} " + nfe.getMessage(), nfe);
		} catch(Exception e) {
			Malgn.errorLog("{SessionDao.getInt::e} " + e.getMessage(), e);
		} finally {
			return ret;
		}
	}

	public String getString(String name) {
		return null != data.get(name) ? data.get(name) : "";
	}

	public void put(String name, String value) {
		data.put(name, value);
	}

	public void put(String name, int i) {
		put(name, "" + i);
	}
}

