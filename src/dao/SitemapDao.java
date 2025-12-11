package dao;

import java.io.*;
import java.util.*;

import malgnsoft.util.*;
import malgnsoft.db.*;

public class SitemapDao extends DataObject {

	private int siteId;

	public String[] displayTypes = { "A=>전체 노출", "I=>회원만 노출", "O=>비회원만 노출" };
	public String[] displayYn = { "Y=>노출", "N=>노출 안 함" };
	public String[] statusList = { "1=>정상", "0=>중지" };

	public String[] displayTypesMsg = { "A=>list.sitemap.display_types.A", "I=>list.sitemap.display_types.I", "O=>list.sitemap.display_types.O" };
	public String[] displayYnMsg = { "Y=>list.sitemap.display_yn.Y", "N=>list.sitemap.display_yn.N" };
	public String[] statusListMsg = { "1=>list.sitemap.status_list.1", "0=>list.sitemap.status_list.0" };

	public SitemapDao() {
		this.table = "TB_SITEMAP";
	}
	public SitemapDao(int siteId) {
		this.table = "TB_SITEMAP";
		this.siteId = siteId;
	}

	public void setSiteId(int siteId) {
		this.siteId = siteId;
	}

	public int copy(int siteId) {
		if(0 == siteId) return -1;

		DataSet list = this.find("site_id = 1 AND status = 1");
		String[] columns = list.getColumns();
		String now = Malgn.time("yyyyMMddHHmmss");
		int success = 0;
		while(list.next()) {
			for(int i = 0; i < columns.length; i++) { this.item(columns[i], list.s(columns[i])); }
			this.item("id", this.getSequence());
			this.item("site_id", siteId);
			this.item("status", "1");
			this.item("reg_date", now);
			if(1 > this.findCount("site_id = " + siteId + " AND code = '" + list.s("code") + "' AND status != -1") && this.insert()) success++;
		}

		return success;
	}

	public DataSet getLayouts(String path) throws Exception {
		DataSet ds = new DataSet();
		File dir = new File(path);
		if(!dir.exists()) return ds;

		try {
			File[] files = dir.listFiles();
			if(null == files) throw new NullPointerException();
			for (int i = 0; i < files.length; i++) {
				if(null == files[i]) throw new NullPointerException();
				String filename = files[i].getName();
				if (filename.startsWith("layout_")) {
					ds.addRow();
					ds.put("id", filename.substring(7, filename.length() - 5));
					ds.put("name", filename);
				}
			}
			return ds;
		} catch (NullPointerException npe) {
			Malgn.errorLog("NullPointerException : SitemapDao.getLayouts() : " + npe.getMessage(), npe);
			return new DataSet();
		}
	}

	public DataSet getList() throws Exception {
		return getList("", "");
	}

	public DataSet getList(String parentCd) throws Exception {
		return getList(parentCd, "");
	}

	public DataSet getList(String parentCd, String where) throws Exception {
		DataSet list = find("status = 1 AND site_id = " + this.siteId + (!"".equals(parentCd) ? " AND code IN ('" + Malgn.join("','", this.getChildNodes(parentCd)) + "') " : "") + (!"".equals(where) ? " AND " + where : ""), "*", "depth ASC, sort ASC");
		setData(list);
		return getTreeList(parentCd, where);
	}

	public DataSet getTreeList() throws Exception {
		return getTreeList("", "");
	}

	public DataSet getTreeList(String parentCd) throws Exception {
		return getTreeList(parentCd, "");
	}

	public DataSet getTreeList(String parentCd, String where) throws Exception {
		DataSet tops = find("status = 1 " + (!"".equals(parentCd) ? " AND code = '" + parentCd + "'" : " AND depth = 1 " ) + " AND site_id = " + this.siteId + (!"".equals(where) ? " AND " + where : ""), "*", "sort ASC");
		DataSet tree = new DataSet();
		while(tops.next()) {
			tree.addRow(tops.getRow());
			tree.put("name_conv", tops.s("menu_nm"));
			DataSet ds = getTree(tops.s("code"));
			while(ds.next()) {
				if(ds.i("depth") > 1) { 
					ds.put("name_conv", getTreeNames(ds.s("code")));
					tree.addRow(ds.getRow());
				}
			}
		}
		tree.first();
		return tree;
	}

	public DataSet getParentList(String code) throws Exception {
		return getParentList(code, "");
	}

	public DataSet getParentList(String code, String where) throws Exception {
		String[] parents = new String[] {};
		try {
			parents = this.getParentNodes(code);
		}
		catch (NullPointerException npe) { return new DataSet(); }
		catch (Exception e) { return new DataSet(); }
		if(1 > parents.length) return new DataSet();

		DataSet tree = find("code IN ('" + Malgn.join("','", parents) + "') AND status = 1 AND site_id = " + this.siteId + (!"".equals(where) ? " AND " + where : ""), "*", "depth ASC");
		tree.first();
		return tree;
	}

	public DataSet getSubList(String code) throws Exception {
		return getSubList(code, 0);
	}

	public DataSet getSubList(String code, int depth) throws Exception {
		return find(
			"status = 1 AND site_id = " + this.siteId + " AND parent_cd = '" + code + "'"
			+ (0 < depth ? " AND depth = " + depth : "")
			+ " AND (display_yn = 'Y' OR depth > 1) "
			, "*"
			, "sort ASC"
		);
	}

	public String getSubCodes(String code) throws Exception {
		if(data == null) {
			DataSet list = find("status = 1 AND site_id = " + this.siteId, "*", "depth ASC, sort ASC");
			setData(list);
		}
		String[] codes = getChildNodes(code);
		return "'" + Malgn.join("', '", codes) + "'";
	}

	public String getTreeNames(String code) throws Exception {
		Vector<String> v = getParentNames(code);
		Collections.reverse(v); 
		return Malgn.join(" > ", v.toArray());
	}

	public String getNames(String code) {
		DataSet info = this.find("code = '" + id + "' AND site_id = " + this.siteId);
		if(!info.next()) return "";
		String names = info.s("menu_nm");
		String parentCd = info.s("parent_cd");
		for(int i = info.i("depth"); i > 1; i--) {
			DataSet pinfo = this.find("code = '" + parentCd + "' AND site_id = " + this.siteId);
			if(pinfo.next()) {
				names =	pinfo.s("menu_nm") + " > " + names;
				parentCd = pinfo.s("parent_cd");
			} else { break;	}
		}
		return names;
	}

	public int sortDepth(String code, int num, int mnum) {
		if("".equals(code) || num == 0 || mnum == 0) return -1;
		DataSet info = this.find("site_id = " + this.siteId + " AND code = '" + code + "' AND status = 1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE site_id = " + this.siteId + " AND parent_cd = '" + info.s("parent_cd") + "' AND depth = " + info.i("depth") + " AND status = 1");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + ( num >= mnum ? "+1" : "-1") + " WHERE site_id = " + this.siteId + " AND code = '" + code + "'");
		return autoSort(info.i("depth"), info.s("parent_cd"));
	}

	public int autoSort(int depth, String parentCd) {
		DataSet list = this.find("site_id = " + this.siteId + " AND parent_cd = '" + parentCd + "' AND depth = " + depth + " AND status = 1", "code, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE site_id = " + this.siteId + " AND code = '" + list.s("code") + "' AND status = 1");
			sort++;
		}
		return 1;
	}


	/* 
 	 *  Make Tree by Hierarchy data
	 */

	public String name = "code";
	public String pName = "parent_cd";
	public String nName = "menu_nm";
	public String rootNode = "0";
	private DataSet data;
	private Hashtable map;
	private Hashtable pMap;
	private DataSet result;
	private Vector pNodes;
	private Vector pNames;
	private int depth = 0;

	public void setData(DataSet data) throws Exception {
		this.data = new DataSet(data);
		/*
		data.first();
		DataSet list = new DataSet();
		while(data.next()) { list.addRow(data.getRow()); }
		this.data = list;
		data.first();
		*/
	}

	public DataSet getTree() throws Exception {
		return getTree(rootNode);
	}

	public DataSet getTree(String id) throws Exception {
		if(null == data) return new DataSet(); 
		data.first();
		pMap = new Hashtable();
		DataSet sRow = new DataSet(); int i = 0; 
		while(data.next()) {
			String pid = data.s(pName);
			Vector nodes = pMap.containsKey(pid) ? (Vector)pMap.get(pid) : new Vector();
			nodes.add(data.getRow());
			pMap.put(pid, nodes);
			if(!rootNode.equals(id) && data.s(name).equals(id)) sRow.addRow(data.getRow());
			if(rootNode.equals(id) && i++ == 0) sRow.addRow(data.getRow());
		}
		result = new DataSet(); sRow.first();
		if(sRow.next()) {
			result.addRow(sRow.getRow());
			childNodes(sRow.s(name));
			result.first();
		}
		return result;
	}

	private void childNodes(String pid) throws Exception { //private
		if(pMap.containsKey(pid)) {
			Object[] nodes = ((Vector)pMap.get(pid)).toArray();
			for(int i=0; i<nodes.length; i++) {
				Hashtable row = (Hashtable)nodes[i];
				result.addRow(row);
				childNodes(row.get(name).toString());
			}
		}
	}
	
	public Vector getChildNodes(String[] nodes) throws Exception {
		Vector<String> result = new Vector<String>();
		for(int i=0, max=nodes.length; i<max; i++) {
			result.add(nodes[i]);
		}
		return result;
	}

	public String[] getChildNodes(String id) throws Exception {
		DataSet list = getTree(id);
		String[] nodes = new String[list.size()]; int i = 0;
		while(list.next()) nodes[i++] = list.s("code");
		return nodes;
	}

	public String[] getParentNodes(String id) throws Exception {
		if(null == data) return new String[] {};
		data.first();
		map = new Hashtable();
		while(data.next()) map.put(data.s(name), data.getRow());
		pNodes = new Vector();
		parentNodes(id + "");
		String[] nodes = new String[pNodes.size()];
		return (String[])pNodes.toArray(nodes);
	}

	private void parentNodes(String id) throws Exception { //private
		if(map.containsKey(id)) {
			pNodes.add(id);
			Hashtable row = (Hashtable)map.get(id);
			pNames.add(row.containsKey(nName) ? row.get(nName).toString() : "");
			parentNodes(row.get(pName).toString());
		}
	}

	public Vector getParentNames(String id) throws Exception {
		if(null == data) return new Vector();
		data.first();
		map = new Hashtable();
		while(data.next()) map.put(data.s(name), data.getRow());
		pNodes = new Vector(); pNames = new Vector();
		parentNodes(id + "");
		return pNames;
	}

}