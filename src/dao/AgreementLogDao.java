package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class AgreementLogDao extends DataObject {
	
	//public String[] agreements = { "AGREEMENT=>Y", "SMS=>N", "EMAIL=>N" };
	public String[] receiveYn = { "Y=>수신동의", "N=>수신거부" };
	public String[] types = { "email=>이메일", "sms=>SMS", "privacy=>개인정보처리방침" };
	
	public String[] receiveYnMsg = { "Y=>list.agreement_log.receive_yn.Y", "N=>list.agreement_log.receive_yn.N" };
	public String[] typesMsg = { "email=>list.agreement_log.types.email", "sms=>list.agreement_log.types.sms", "privacy=>list.agreement_log.types.privacy" };

	private Page p;
	private int siteId = 0;

	public AgreementLogDao() {
		this.table = "TB_AGREEMENT_LOG";
		this.PK = "id";
	}

	public AgreementLogDao(Page p, int siteId) {
		this.table = "TB_AGREEMENT_LOG";
		this.PK = "id";
		this.p = p;
		this.siteId = siteId;
	}

	public void setPage(Page p) {
		this.p = p;
	}

	public boolean insertLog(DataSet siteinfo, DataSet uinfo, String type, String agreementYn, String module) throws Exception {
		return insertLog(siteinfo, uinfo, type, agreementYn, module, 0);
	}

	public boolean insertLog(DataSet siteinfo, DataSet uinfo, String type, String agreementYn, String module, int moduleId) throws Exception {
		if(null == siteinfo || null == uinfo || "".equals(type) || "".equals(agreementYn) || "".equals(module)) return false;

		this.item("site_id", siteId);
		this.item("user_id", uinfo.i("id"));
		this.item("type", type);
		this.item("agreement_yn", agreementYn);
		this.item("module", module);
		this.item("module_id", moduleId);
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));

		return this.insert();
	}

	public String getDate(int userId, String type) {
		return this.getOne("SELECT reg_date FROM " + this.table + " WHERE user_id = " + userId + " AND type = '" + type +  "' ORDER BY reg_date DESC");
	}

	public boolean getYn(int userId, String type) {
		return "Y".equals(this.getOne("SELECT agreement_yn FROM " + this.table + " WHERE user_id = " + userId + " AND type = '" + type +  "' ORDER BY reg_date DESC"));
	}
}