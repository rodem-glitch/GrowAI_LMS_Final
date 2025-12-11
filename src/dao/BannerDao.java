package dao;

import java.io.*;
import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.regex.*;
import java.util.HashMap;

public class BannerDao extends DataObject {

	//public String[] types = { "main=>메인", "right=>오른쪽", "top=>상단", "mobile=>모바일", };
	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] targets = { "_self=>현재 창 이동 (_self)", "_blank=>새 창 띄움 (_blank)", "_parent=>상위 창 이동 (_parent)" };
	
	public String[] statusListMsg = { "1=>list.banner.status_list.1", "0=>list.banner.status_list.0" };
	public String[] targetsMsg = { "_self=>list.banner.targets._self", "_blank=>list.banner.targets._blank", "_parent=>list.banner.targets._parent" };

	public int siteId = 0;

	private static HashMap<String, String> cache = new HashMap<String, String>();

	public BannerDao() {
		this.table = "TB_BANNER";
	}

	public BannerDao(int siteId) {
		this.table = "TB_BANNER";
		this.siteId = siteId;
	}

	public int sortBanner(int id, int num, int mnum) {
		if("".equals(id) || num == 0 || mnum == 0) return -1;
		DataSet info = this.find("id = " + id + " AND status > -1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + this.table + " SET sort = sort * 1000 WHERE site_id = " + siteId + " AND banner_type = '" + info.s("banner_type") + "' AND status > -1");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + ( num >= mnum ? "+1" : "-1") + " WHERE id = " + id + "");
		return autoSort(info.s("banner_type"));
	}

	public int autoSort(String type) {
		DataSet list = this.find("site_id = " + siteId + " AND banner_type = '" + type + "' AND status > -1", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE id = " + list.s("id") + " AND status > -1");
			sort++;
		}
		return 1;
	}

	public void printBanner(int id, Writer out) throws Exception {
		String key = "" + id;
		if(!cache.containsKey(key)) {
			DataSet info = this.find("status = 1 AND site_id = " + siteId + " AND id = " + id);
			if(info.next()) {
				if("".equals(info.s("banner_file_url"))) {
					info.put("banner_file_url", Malgn.getUploadUrl(info.s("banner_file"), "/data"));
				}
				String img = "<img src=\"" + info.s("banner_file_url") + "\" alt=\"" + info.s("banner_nm") + "\" width=\"" + info.i("width") + "\" height=\"" + info.i("height") + "\">";
				img = img.replace(" width=\"0\"", "");
				img = img.replace(" height=\"0\"", "");
				if(!"".equals(info.s("link"))) img = "<a href=\"" + info.s("link") + "\" target=\"" + info.s("target") + "\">" + img + "</a>";
				cache.put(key, img);
			} else {
				cache.put(key, "");
			}
		}
		try {
			out.write(cache.get(key));
		} catch(NullPointerException npe) {
			Malgn.errorLog("NullPointerException : BannerDao.prinBanner() : " + npe.getMessage(), npe);
			out.write("err");
		} catch(IOException ioe) {
			Malgn.errorLog("IOException : BannerDao.prinBanner() : " + ioe.getMessage(), ioe);
			out.write("err");
		}
	}

	public boolean copy(int siteId) {
		if(0 == siteId) return false;

		DataSet info = this.find("site_id = 1 AND status = 1", "*", "sort ASC", 1);
		String[] columns = info.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		while(info.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], info.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", siteId);
			this.item("sort", 1);
			//this.item("status", "1");
			this.item("reg_date", now);
			return this.insert();
		}

		return false;
	}

	public void removeCache(int id) {
		cache.remove("" + id);
	}
}