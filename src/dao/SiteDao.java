package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.Hashtable;

public class SiteDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] pgList = { "lgu=>LG유플러스", "allat=>올앳", "inicis=>이니시스", "ksnet=>KSNET", "kicc=>KICC", "payletter=>페이레터", "eximbay=>엑심베이", "none=>사용안함" };
	public String[] ovpVendors = { "W=>위캔디오", "C=>KOLLUS", "F=>CDN" };
	public String[] types = { "C=>일반", "I=>사내", "B=>영업", "S=>지원", "E=>기타" };
	public String[] pstatusList = { "1=>세팅", "2=>디자인", "3=>테스트", "4=>가오픈", "5=>중단", "9=>운영" };
	public String[] alertTypes = { "P=>주문결제정보" };
	public String[] oauthVendors = { "naver=>네이버", "kakao=>카카오", "google=>Google", "facebook=>Facebook", "line=>LINE" };
	//public String[] skinRoots = { "2014=>/Users/kyounghokim/IdeaProjects/MalgnLMS/public_html/html", "2017=>/home/demo/public_html/html" };

	public String[] statusListMsg = { "1=>list.site.status_list.1", "0=>list.site.status_list.0" };
	public String[] oauthVendorsMsg = { "naver=>list.site.oauth_vendors.naver", "kakao=>list.site.oauth_vendors.kakao", "google=>list.site.oauth_vendors.google", "facebook=>list.site.oauth_vendors.facebook", "line=>list.site.oauth_vendors.line" };

	private static Hashtable<String, DataSet> cache = new Hashtable<String, DataSet>();

	public SiteDao() {
		this.table = "TB_SITE";
		this.PK = "id";
	}

	public DataSet getSiteInfo(String domain) {
		return this.getSiteInfo(domain, "");
	}

	public DataSet getSiteInfo(String domain, String module) {
		DataSet info = cache.get(domain);
		if(info == null) {
			String statusField = ("sysop".equals(module) ? "sysop_status" : "status");
			query("SELECT 1");
			info = find("(domain = '" + domain + "' OR domain2 = '" + domain + "') AND " + statusField + " = 1");
			if(!info.next()) { info = find("id = 1"); info.next(); }
			cache.put(domain, info);
		}
		return info;
	}

	public String getCenterWebUrl() {
		return getOne("SELECT domain FROM " + this.table + " WHERE id = 1");
	}
	public String getCenterDataDir() {
		return getOne("SELECT doc_root FROM " + this.table + " WHERE id = 1") + "/data";
	}
	public void remove(String domain) {
		cache.remove(domain);
	}

	public void clear() {
		cache.clear();
	}

	public boolean checkIP(String clientIP, String rule) {
		String[] ips = Malgn.split("|", rule);
		boolean flag = false;
		DataSet cip = Config.getDataSet("//config/env/clientIp");
		cip.next();
		if(clientIP.equals(cip.s("headQuater")) || clientIP.equals(cip.s("laboratory"))) return true;
		for(int i=0; i<ips.length; i++) {
			String ip = ips[i].trim();
			if(ip.endsWith("*")) flag = clientIP.startsWith(ip.replace("*", ""));
			else flag = clientIP.equals(ip);
			if(flag) break;
		}
		return flag;
	}

}
