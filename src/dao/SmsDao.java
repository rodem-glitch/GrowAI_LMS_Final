package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.regex.*;

public class SmsDao extends DataObject {
	
	public String smsId = "";
	public String smsPasswd = "";
	
	private int siteId = 0;

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] types = { "A=>영리/광고성", "I=>비광고성" };
	public String[] alltypes = { "A=>영리/광고성", "I=>비광고성", "S=>시스템" };
	
	public String[] statusListMsg = { "1=>list.sms.status_list.1", "0=>list.sms.status_list.0" };
	public String[] typesMsg = { "A=>list.sms.types.A", "I=>list.sms.types.I" };
	public String[] alltypesMsg = { "A=>list.sms.alltypes.A", "I=>list.sms.alltypes.I", "S=>list.sms.alltypes.S" };

	public SmsDao() {
		this.table = "TB_SMS";
	}

	public SmsDao(int siteId) {
		this.table = "TB_SMS";
		this.siteId = siteId;
	}

	public SmsDao(String smsId) {
		this.table = "TB_SMS";
		this.smsId = smsId;
	}

	public void setAccount(String id, String passwd) {
		this.smsId = id;
		this.smsPasswd = passwd;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public boolean isMobile(String value) {
		Pattern pattern = Pattern.compile("^([0-9]{2,3}-?[0-9]{3,4}-?[0-9]{4})$");
		Matcher match = pattern.matcher(value);
		return match.find();
	}

	public boolean insertSms(int siteId, int userId, String sender, String content, DataSet uinfo) throws Exception {
		return insertSms(siteId, userId, sender, content, uinfo, "I");
	}

	public boolean insertSms(int siteId, int userId, String sender, String content, DataSet uinfo, String smsType) throws Exception {
		SmsUserDao smsUser = new SmsUserDao();

		int newId = this.getSequence();
		this.item("id", newId);
		this.item("site_id", siteId);

		this.item("module", "user");
		this.item("module_id", 0);
		this.item("user_id", userId);
		this.item("sms_type", smsType);
		this.item("sender", sender);
		this.item("content", content);
		this.item("resend_id", 0);
		this.item("send_cnt", 1);
		this.item("fail_cnt", 0);
		this.item("send_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);
		if(!this.insert()) return false;

		smsUser.item("site_id", siteId);
		smsUser.item("sms_id", newId);
		smsUser.item("mobile", SimpleAES.encrypt(uinfo.s("mobile")));
		smsUser.item("user_id", uinfo.i("id"));
		smsUser.item("user_nm", uinfo.s("user_nm"));
		smsUser.item("send_yn", "Y");
		if(!smsUser.insert()) {
			this.delete("id = " + newId + "");
			return false;
		}
		
		return true;
	}

	public void send(String to, String from, String message) throws Exception {
		this.send(to, from, message, "");
	}

	public void send(String to, String from, String message, String date) throws Exception {
		/*
		date = (date == null || "".equals(date)) ? Malgn.getTimeString("yyyyMMddHHmmss") : Malgn.getTimeString("yyyyMMddHHmmss", date);
		Http http = new Http("http://www.hostit.co.kr/API/MalgnSMS.php");
		http.setEncoding("euc-kr");
		//http.setDebug(out);
		http.setParam("id", smsId);
		http.setParam("pass", smsPasswd);
		http.setParam("to", to);
		http.setParam("from", from);
		http.setParam("message", message.trim());
		if(date != null) http.setParam("date", date);
		http.send("POST");
		*/
		BizSMS bizSMS = new BizSMS(smsId, smsPasswd);
		bizSMS.setSite(siteId);
		bizSMS.send(to, from, message, date);
	}

	public void send(String to, String from, String message, String date, String title) throws Exception {
		BizSMS bizSMS = new BizSMS(smsId, smsPasswd);
		bizSMS.setSite(siteId);
		bizSMS.send(to, from, message, date, title);
	}

	public DataSet getHours() {
		DataSet hours = new DataSet();
		for(int i=0; i<24; i++) {
			hours.addRow();
			hours.put("id", (i < 10 ? "0" : "") + i);
			hours.put("name", (i < 10 ? "0" : "") + i);
		}
		hours.first();
		return hours;
	}
	public DataSet getMinutes() {
		return getMinutes(1);
	}
	public DataSet getMinutes(int step) {
		DataSet minutes = new DataSet();
		for(int i=0; i<60; i+=step) {
			minutes.addRow();
			minutes.put("id", (i < 10 ? "0" : "") + i);
			minutes.put("name", (i < 10 ? "0" : "") + i);
		}
		minutes.first();
		return minutes;
	}

	public String maskMobile(String value) {
		if(!this.isMobile(value)) return value;

		String mobile[] = Malgn.split("-", value);
		return mobile[0] + "-" + Malgn.strpad("", mobile[1].length(), "*") + "-" + mobile[2];
	}
}