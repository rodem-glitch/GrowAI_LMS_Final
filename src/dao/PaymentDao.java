package dao;

import java.util.HashMap;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class PaymentDao extends DataObject {

	//public String[] methods = { "SC0010=>신용카드", "SC0030=>계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제" };

	public String[] methods = { "01=>신용카드", "02=>실시간계좌이체", "03=>무통장입금(가상계좌)", "04=>휴대폰결제", "05=>해외발행카드", "10=>Payment via Pay-Gate", "11=>해외발행카드(PL)", "90=>무통장입금(일반)", "91=>여민동락" };
	public String[] statusList = { "1=>완료", "0=>입금대기" };

	public HashMap<String, String[]> pgMethodsAll = new HashMap<String, String[]>();

	public int siteId = 0;
	public String mid = "";
	public String resCd = "";
	public String resMsg = "";

	public PaymentDao() {
		this.table = "TB_PAYMENT";
		this.pgMethodsAll.put("lgu", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("allat", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("inicis", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("ksnet", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("kcp", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("payletter", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
		this.pgMethodsAll.put("eximbay", new String[] { "SC0010=>신용카드", "SC0030=>실시간계좌이체", "SC0040=>무통장입금(가상계좌)", "SC0060=>휴대폰결제", "SC0010=>해외발행카드", "10=>Payment via Pay-Gate", "90=>무통장입금(일반)", "91=>여민동락" });
	}

	public void setSiteId(int id) {
		this.siteId = id;
	}

	public void setMid(String mid) {
		this.mid = mid;
	}

	public boolean pay(Form f) {
		return false;
	}

	public boolean cancel(Form f) {
		return false;
	}

	public boolean validMethod(DataSet siteinfo, String payMethod) {
		return (-1 < siteinfo.s("pg_methods").indexOf("|" + payMethod + "|"));
	}

	public DataSet getMethods(DataSet siteinfo) {
		DataSet result = new DataSet();
		String sitePg = siteinfo.s("pg_nm");
		String siteMethods = siteinfo.s("pg_methods");
		String[] pgMethods = this.pgMethodsAll.get(sitePg);
		if(null == pgMethods) return result;
		
		for(int i = 0; i < methods.length; i++) {
			String[] tmp = methods[i].split("=>");
			if(-1 < siteMethods.indexOf("|" + tmp[0] + "|")) {
				result.addRow();
				result.put("id", tmp[0]);
				result.put("pgid", pgMethods[i].split("=>")[0]);
				result.put("name", tmp[1]);
			}
		}
		result.first();
		return result;
	}
}