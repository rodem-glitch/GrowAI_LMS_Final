package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.Hashtable;

public class SiteConfigDao extends DataObject {

	public String[] statusList = { "1=>정상", "0=>중지" };
	public String[] pgList = { "lgu=>LG유플러스", "kicc=>KICC" /*, "none=>자체계좌" */ };
	public String[] ovpVendors = { "W=>위캔디오", "C=>KOLLUS", "F=>CDN" };
	public String[] types = { "C=>일반", "I=>내사", "B=>영업", "S=>지원", "E=>기타" };
	public String[] pstatusList = { "1=>사이트 개설", "2=>디자인/퍼블리싱", "3=>테스트", "4=>가오픈", "5=>운영중단", "9=>정상운영" };

	private static Hashtable<String, DataSet> cache = new Hashtable<String, DataSet>();
	private static Hashtable<String, DataSet> cacheMap = new Hashtable<String, DataSet>();
	private DataSet info = null;
	private String siteId = "0";

	public SiteConfigDao() {
		this.table = "TB_SITE_CONFIG";
		this.PK = "site_id,key";
	}

	public SiteConfigDao(int siteId) {
		this.table = "TB_SITE_CONFIG";
		this.PK = "site_id,key";
		this.siteId = "" + siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = "" + siteId;
	}

	public Hashtable<String, String> getSiteConfig(String siteId) {
		this.siteId = siteId;
		DataSet list = cache.get(siteId);
		if(list == null) {
			query("SELECT 1");
			list = find("site_id = '" + siteId + "'");
			if(list.next()) cache.put(siteId, list);
		}
		Hashtable<String, String> config = new Hashtable<String, String>();
		list.first();
		while(list.next()) {
			config.put(list.s("key").toLowerCase(), list.s("data"));
		}
		return config;
	}

	public DataSet getDataSet() {
		DataSet list = cacheMap.get(siteId);
		if(list == null) {
			list = new DataSet();
			list.addRow();
			DataSet rs = find("site_id = '" + siteId + "'");
			while(rs.next()) {
				list.put(rs.s("key").toLowerCase(), rs.s("data"));
			}
			cacheMap.put(siteId, list);
		}
		this.info = list;
		return list;
	}

	public DataSet getDataSet(int siteId) {
		this.siteId = "" + siteId;
		return getDataSet();
	}

	public String getString(String key) {
		if(this.info == null) getDataSet();
		return info.getString(key);
	}

	public String s(String key) {
		return this.getString(key);
	}

	public int getInt(String key) {
		if(this.info == null) getDataSet();
		return info.getInt(key);
	}

	public int i(String key) {
		return this.getInt(key);
	}

	public double getDouble(String key) {
		if(this.info == null) getDataSet();
		return info.getDouble(key);
	}

	public Hashtable<String, String> getArrMap(String prefix) {
		if(this.info == null) getDataSet();
		Hashtable<String, String> ret = new Hashtable<String, String>();
		String[] keys = info.getKeys();
		for(int i = 0; i < keys.length; i++) {
			if(0 == keys[i].indexOf(prefix)) {
				ret.put(keys[i], info.s(keys[i]));
			}
		}
		return ret;
	}

	public Hashtable<String, String> getArrMap(String[] prefixes) {
		if(this.info == null) getDataSet();
		Hashtable<String, String> ret = new Hashtable<String, String>();
		if(null == prefixes) return ret;

		for(int i = 0; i < prefixes.length; i++) {
			ret.putAll(this.getArrMap(prefixes[i]));
		}
		return ret;
	}

	public DataSet getArr(String prefix) {
		DataSet ret = new DataSet();
		ret.addRow(this.getArrMap(prefix));
		return ret;
	}

	public DataSet getArr(String[] prefixes) {
		DataSet ret = new DataSet();
		ret.addRow(this.getArrMap(prefixes));
		return ret;
	}

	public boolean put(String key, String val) {
		boolean ret = true;
		String where = "site_id = '" + this.siteId + "' AND `key` = '" + key + "'";
		this.item("`key`", key);
		this.item("data", val);
		if(0 < this.findCount(where)) {
			if(!update(where)) ret = false;
		} else {
			this.item("site_id", this.siteId);
			this.item("`key`", key);
			if(!insert()) ret = false;
		}
		if(ret == true) {
			if(info == null) getDataSet();
			info.put(key, val);
		}
		return ret;
	}

	public boolean put(String key, int val) {
		return this.put(key, "" + val);
	}

	public boolean put(String key, double val) {
		return this.put(key, "" + val);
	}

	public int save(DataSet list) {
		int failed = 0;
		this.item("site_id", this.siteId);
		String[] keys = list.getKeys();
		for(int i = 0; i < keys.length; i++) {
			if(!put(keys[i], list.s(keys[i]))) failed++;
		}
		return failed;
	}

	public void remove(String siteId) {
		cache.remove(siteId);
		cacheMap.remove(siteId);
	}

	public void clear() {
		cache.clear();
		cacheMap.clear();
	}

}