package dao;

import java.io.File;
import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.regex.*;

public class MailDao extends DataObject {

	/*
	public String[] templates = { 
		"default=>알림", "qna_answer=>질문답변", "join=>회원가입"
		, "course=>수강신청", "ebook=>전자책대여", "findpw_authno=>인증번호", "findpw_newpw=>새비밀번호"
		, "close1=>수강종료1일전", "close7=>수강종료7일전"
		, "payment=>결제완료", "account=>가상계좌"
	};
	*/

	public String[] types = { "A=>수신동의자", "I=>전체(수신거부자 포함)" };
	public String[] alltypes = { "A=>수신동의자", "I=>전체(수신거부자 포함)", "S=>시스템" };

	public String[] typesMsg = { "A=>list.mail.types.A", "I=>list.mail.types.I" };
	public String[] alltypesMsg = { "A=>list.mail.alltypes.A", "I=>list.mail.alltypes.I", "S=>list.mail.alltypes.S" };

	Malgn m;

	public MailDao() {
		this.table = "TB_MAIL";

		m = new Malgn();
	}

	public boolean isMail(String value) {
		Pattern pattern = Pattern.compile("^[a-z0-9A-Z\\_\\.\\-]+@([a-z0-9A-Z\\.\\-]+)\\.([a-zA-Z]+)$");
		Matcher match = pattern.matcher(value);
		return match.find();
	}


	public boolean insertMail(int siteId, int userId, String sender, String subject, String content, DataSet uinfo) {
		return insertMail(siteId, userId, sender, subject, content, uinfo, "S");
	}

	public boolean insertMail(int siteId, int userId, String sender, String subject, String content, DataSet uinfo, String mailType) {
		
		MailUserDao mailUser = new MailUserDao();

		int newId = this.getSequence();

		this.item("id", newId);
		this.item("site_id", siteId);

		this.item("module", "user");
		this.item("module_id", 0);
		this.item("user_id", userId);
		this.item("mail_type", mailType);
		this.item("sender", sender);
		this.item("subject", subject);
		this.item("content", content);
		this.item("resend_id", 0);
		this.item("send_cnt", 1);
		this.item("fail_cnt", 0);
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		this.item("status", 1);
		if(!this.insert()) return false;

		mailUser.item("site_id", siteId);
		mailUser.item("mail_id", newId);
		mailUser.item("email", uinfo.s("email"));
		mailUser.item("user_id", uinfo.s("id"));
		mailUser.item("user_nm", uinfo.s("user_nm"));
		mailUser.item("send_yn", "Y");
		if(!mailUser.insert()) {
			this.delete("id = " + newId + "");
			return false;
		}
		return true;
	}

	/*
	public DataSet getFiles(String path) throws Exception {
		DataSet list = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return list;

		File[] files = dir.listFiles();
		for(int i = 0; i < files.length; i++) {
			String filename = files[i].getName();
			list.addRow();
			list.put("id", filename.substring(0, filename.indexOf(".")));
			list.put("name", Malgn.getItem(list.s("id"), templates));
		}
		return list;
	}
	*/

	public String maskMail(String value) {
		if(!this.isMail(value)) return value;

		String account = Malgn.split("@", value)[0];
		int length = account.length();
		if(length < 3) {
			return Malgn.strpad(value.replace(account, ""), length, "*");
		} else if(length == 3) {
			return value.replaceAll("\\b(\\S+)[^@][^@]+@(\\S+)", "$1**@$2");
		} else {
			return value.replaceAll("\\b(\\S+)[^@][^@][^@][^@]+@(\\S+)", "$1****@$2");
		}
	}

	public boolean send(DataSet siteinfo, String email, String templateCd, Page p) throws Exception {
		DataSet uinfo = new DataSet();
		uinfo.addRow();
		uinfo.put("id", 0);
		uinfo.put("user_nm", "[비회원]");
		uinfo.put("email", email);
		return send(siteinfo, uinfo, templateCd, p);
	}

	public boolean send(DataSet siteinfo, DataSet uinfo, String templateCd, Page p) throws Exception {
		if(siteinfo == null || "".equals(templateCd) || p == null) return false;
		if(!this.isMail(uinfo.s("email"))) return false;

		//정보
		DataSet tinfo = new MailTemplateDao().find("template_cd = '" + templateCd + "' AND site_id = " + siteinfo.i("id") + " AND status = 1");
		if(!tinfo.next()) return false;

		//설정
		if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
		siteinfo.put("logo_url", Malgn.getUploadUrl(siteinfo.s("logo"), "http://" + siteinfo.s("domain") + "/data"));

		p.setRoot(siteinfo.s("doc_root") + "/html");
		p.setVar("SITE_INFO", siteinfo);
		p.setVar("user", uinfo);

		String sender = siteinfo.s("site_email");
		String subject = p.parseString(tinfo.s("subject"));
		String body = p.fetchString(tinfo.s("content"));

		p.setVar("subject", subject);
		p.setVar("MBODY", body);

		//발송
		boolean result = false;;
		m.mailFrom = sender;
		m.mail(uinfo.s("email"), "[" + siteinfo.s("site_nm") + "] " + subject, p.fetchRoot("mail/template.html"));
		result = this.insertMail(siteinfo.i("id"), -9, sender, subject, body, uinfo, "I");

		//사본발송
		if(result) {
			subject = "[사본] " + subject;
			DataSet clist = new UserDao().find("status = 1 AND id IN ('" + m.replace(tinfo.s("copy_idx"), "|", "','") + "')", "id,user_nm,email,mobile");
			while(clist.next()) {
				if(this.isMail(clist.s("email"))) {
					m.mail(clist.s("email"), "[" + siteinfo.s("site_nm") + "] " + subject, p.fetchRoot("mail/template.html"));
					this.insertMail(siteinfo.i("id"), -9, sender, subject, body, clist, "I");
				}
			}
		}

		return result;
	}

}