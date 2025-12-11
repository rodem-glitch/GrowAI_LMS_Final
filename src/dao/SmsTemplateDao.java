package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class SmsTemplateDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.sms_template.status_list.1", "0=>list.sms_template.status_list.0" };

	private int siteId = 0;

	Malgn m;
	SmsDao sms;

	public SmsTemplateDao() {
		this.table = "TB_SMS_TEMPLATE";
		this.PK = "id";

		m = new Malgn();
		sms = new SmsDao();
	}

	public SmsTemplateDao(int siteId) {
		this.table = "TB_SMS_TEMPLATE";
		this.PK = "id";
		this.siteId = siteId;

		m = new Malgn();
		sms = new SmsDao();
		this.sms.setSite(siteId);
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
		this.sms.setSite(siteId);
	}

	public void setMalgn(Malgn m) { 
		this.m = m;
	}

	public DataSet getList(int siteId) {
		return this.find("site_id = " + siteId + " AND status = 1", "template_cd id, template_nm name, template_nm value", "template_nm ASC");
	}

	public String getTemplate(int siteId, String templateCd) {
		return this.getOne("SELECT content FROM " + this.table + " WHERE site_id = " + siteId + " AND template_cd = '" + templateCd + "' AND status = 1");
	}

	public String fetchTemplate(int siteId, String templateCd, Page p) throws Exception {
		if(siteId == 0 || "".equals(templateCd) || p == null) return "";
	
		return p.fetchString(this.getTemplate(siteId, templateCd));
	}

	public boolean sendSms(DataSet siteinfo, String mobile, String templateCd, Page p) throws Exception {
		DataSet uinfo = new DataSet();
		uinfo.addRow();
		uinfo.put("id", 0);
		uinfo.put("user_nm", "[비회원]");
		uinfo.put("mobile", mobile);
		return sendSms(siteinfo, uinfo, templateCd, p);
	}

	public boolean sendSms(DataSet siteinfo, DataSet uinfo, String templateCd, Page p) throws Exception {
		return sendSms(siteinfo, uinfo, templateCd, p, null);
	}

	public boolean sendSms(DataSet siteinfo, DataSet uinfo, String templateCd, Page p, String alertCode) throws Exception {
		if(siteinfo == null || !siteinfo.b("sms_yn") || "".equals(templateCd) || p == null) {
			//m.log("smst", "[" + templateCd + "] " + m.time("yyyyMMddHHmmss") + " / ERR#1 / " + uinfo.serialize());
			return false;
		}
		//m.log("smst", "[" + templateCd + "] " + m.time("yyyyMMddHHmmss") + " / RUN / " + uinfo.serialize());

		this.sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

		String mobile = !"".equals(uinfo.s("mobile")) ? (uinfo.s("mobile").length() % 4 == 0 ? SimpleAES.decrypt(uinfo.s("mobile")) : uinfo.s("mobile")) : "";
		if("".equals(mobile)) mobile = uinfo.s("mobile");
		if(!sms.isMobile(mobile)) {
			//m.log("smst", "[" + templateCd + "] " + m.time("yyyyMMddHHmmss") + " / ERR#2 - " + uinfo.s("mobile") + "=>" + mobile + " / " + uinfo.serialize());
			return false;
		}
		uinfo.put("mobile", mobile);

		p.setVar("SITE_INFO", siteinfo);
		p.setVar("user", uinfo);

		String content = this.fetchTemplate(siteinfo.i("id"), templateCd, p);
		String sender = siteinfo.s("sms_sender");

		if("".equals(content)) {
			//m.log("smst", "[" + templateCd + "] " + m.time("yyyyMMddHHmmss") + " / ERR#3 - " + mobile + " / " + uinfo.serialize());
			return false;
		}

		//발송
		sms.send(mobile, sender, content);
		if(alertCode != null && !"".equals(alertCode) && -1 < siteinfo.s("alert_type_sms").indexOf("|" + alertCode + "|")) sms.send(siteinfo.s("alert_phone"), sender, "[관리자알림] " + content);

		//m.log("smst", "[" + templateCd + "] " + m.time("yyyyMMddHHmmss") + " / SUCCESS - " + mobile);
		//등록-메일
		return sms.insertSms(siteinfo.i("id"), -9, sender, content, uinfo, "I");
	}

	public int copyTemplate(int siteId) {
		if(0 == siteId) return -1;

		DataSet list = this.find("site_id = 1 AND base_yn = 'Y'");
		String[] columns = list.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		int success = 0;
		while(list.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], list.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", siteId);
			this.item("status", "0");
			this.item("reg_date", now);
			if(1 > this.findCount("site_id = " + siteId + " AND template_cd = '" + list.s("template_cd") + "'") && this.insert()) success++;
		}

		return success;
	}

	public int copyTemplate(String templateCd) {
		if("".equals(templateCd)) return -1;

		SiteDao site = new SiteDao(); site.jndi = this.jndi;

		DataSet info = this.find("template_cd = ? AND site_id = 1 AND base_yn = 'Y'", new String[] { templateCd });
		if(!info.next()) return -1;

		String[] columns = info.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		int success = 0;

		DataSet slist = site.find("status != -1");
		while(slist.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], info.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", slist.s("id"));
			this.item("reg_date", now);
			if(1 > this.findCount("site_id = " + slist.s("id") + " AND template_cd = '" + templateCd + "'") && this.insert()) success++;
		}

		return success;
	}

}