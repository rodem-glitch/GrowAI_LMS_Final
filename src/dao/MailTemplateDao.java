package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class MailTemplateDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	
	public String[] statusListMsg = { "1=>list.mail_template.status_list.1", "0=>list.mail_template.status_list.0" };

	Malgn m;
	MailDao mail;

	public MailTemplateDao() {
		this.table = "TB_MAIL_TEMPLATE";
		this.PK = "id";

		m = new Malgn();
		mail = new MailDao();
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

	public boolean sendMail(DataSet siteinfo, String email, String templateCd, String msubject, Page p) throws Exception {
		DataSet uinfo = new DataSet();
		uinfo.addRow();
		uinfo.put("id", 0);
		uinfo.put("user_nm", "[비회원]");
		uinfo.put("email", email);
		return sendMail(siteinfo, uinfo, templateCd, msubject, p);
	}

	public boolean sendMail(DataSet siteinfo, DataSet uinfo, String templateCd, String subject, Page p) throws Exception {
		return sendMail(siteinfo, uinfo, templateCd, subject, p, null);
	}

	public boolean sendMail(DataSet siteinfo, DataSet uinfo, String templateCd, String subject, Page p, String alertCode) throws Exception {
		if(siteinfo == null || "".equals(templateCd) || "".equals(subject) || p == null) return false;
		if(!mail.isMail(uinfo.s("email"))) return false;

		siteinfo.put("logo_url", Malgn.getUploadUrl(siteinfo.s("logo"), "http://" + siteinfo.s("domain") + "/data"));

		p.setRoot(siteinfo.s("doc_root") + "/html");
		//p.setLayout(null);
		//p.setBody("mail.template");
		p.setVar("SITE_INFO", siteinfo);
		p.setVar("user", uinfo);
		p.setVar("subject", subject);

		String mbody = this.fetchTemplate(siteinfo.i("id"), templateCd, p);
		p.setVar("MBODY", mbody);

		if("".equals(mbody)) return false;

		//발송자
		if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
		String sender = siteinfo.s("site_email");

		//발송
		m.mailFrom = sender;
		m.mail(uinfo.s("email"), "[" + siteinfo.s("site_nm") + "] " + subject, p.fetchRoot("mail/template.html"));
		if(alertCode != null && !"".equals(alertCode) && -1 < siteinfo.s("alert_type_email").indexOf("|" + alertCode + "|")) m.mail(siteinfo.s("alert_email"), "[" + siteinfo.s("site_nm") + "] [관리자알림] " + subject, p.fetchRoot("mail/template.html"));

		//등록-메일
		return mail.insertMail(siteinfo.i("id"), -9, sender, subject, mbody, uinfo, "I");
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

		DataSet slist = site.find("id != 1 AND status != -1");
		while(slist.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], info.s(columns[i])); }
			this.record.remove("id");
			this.item("site_id", slist.s("id"));
			this.item("reg_date", now);
			if(1 > this.findCount("site_id = " + slist.s("id") + " AND template_cd = '" + templateCd + "'")) {
				if(this.insert()) success++;
			} else {
				if(this.update("site_id = " + slist.s("id") + " AND template_cd = '" + templateCd + "'")) success++;
			}
		}

		return success;
	}

}