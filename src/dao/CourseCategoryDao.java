package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;
import java.io.*;

public class CourseCategoryDao extends DataObject {

	public CourseCategoryDao() {
		this.table = "LM_COURSE_CATEGORY";
	}

	public DataSet getList(int siteId) throws Exception {
		DataSet list = find("status = 1 AND site_id = " + siteId + " ", "*", "depth ASC, sort ASC");
		setData(list);
		DataSet categories = getTree();
		while(categories.next()) {
			categories.put("name_conv", categories.s("category_nm"));
			if(categories.i("depth") > 1) { 
				Vector<String> v = getParentNames(categories.s("id"));
				Collections.reverse(v); 
				categories.put("name_conv", Malgn.join(" > ", v.toArray()));
			}
			categories.put("spacing", Malgn.repeatString("&nbsp", (categories.i("depth")-1) * 4));
		}
		categories.first();
		return categories;
	}

	
	public DataSet getTreeList(int siteId) throws Exception {
		DataSet tops = find("status = 1 AND depth = 1 AND site_id = " + siteId + " ", "*", "sort ASC");
		DataSet tree = new DataSet();
		while(tops.next()) {
			DataSet ds = getTree(tops.s("id"));
			while(ds.next()) {
				if(ds.i("depth") > 1) { 
					Vector v = getParentNames(ds.s("id"));
					Collections.reverse(v); 
					ds.put("name_conv", Malgn.join(" > ", v.toArray()));
					tree.addRow(ds.getRow());
				}
			}
		}
		tree.first();
		return tree;
	}

	public String getNames(int id) {
		DataSet info = this.find("id = " + id);
		if(!info.next()) return "";
		String names = info.s("category_nm");
		int pid = info.i("parent_id");
		for(int i = info.i("depth"); i > 1; i--) {
			DataSet pinfo = this.find("id = " + pid);
			if(pinfo.next()) {
				names =	pinfo.s("category_nm") + " > " + names;
				pid = pinfo.i("parent_id");
			} else { break;	}
		}
		return names;
	}

	public int sortDepth(int id, int num, int mnum, int sid) {
		if("".equals(id) || num == 0 || mnum == 0) return -1;
		DataSet info = this.find("id = " + id + " AND status = 1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE site_id = " + sid + " AND parent_id = " + info.i("parent_id") + " AND depth = " + info.i("depth") + " AND status = 1");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + ( num >= mnum ? "+1" : "-1") + " WHERE id = " + id);
		return autoSort(info.i("depth"), info.i("parent_id"), info.i("site_id"));
	}

	public int autoSort(int depth, int pid, int sid) {
		DataSet list = this.find("site_id = " + sid + " AND parent_id = " + pid + " AND depth = " + depth + " AND status = 1", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE id = " + list.i("id") + " AND status = 1");
			sort++;
		}
		return 1;
	}


	/* 
 	 *  Make Tree by Hierarchy data
	 */

	public String name = "id";
	public String pName = "parent_id";
	public String nName = "category_nm";
	public String rootNode = "0";
	private DataSet data;
	private Hashtable map;
	private Hashtable pMap;
	private DataSet result;
	private Vector pNodes;
	private Vector pNames;
	private int depth = 0;

	public void setData(DataSet data) throws Exception {
		data.first();
		DataSet list = new DataSet();
		while(data.next()) { list.addRow(data.getRow()); }
		this.data = list;
		data.first();
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

	public String[] getChildNodes(String id) throws Exception {
		DataSet list = getTree(id);
		String[] nodes = new String[list.size()]; int i = 0;
		while(list.next()) nodes[i++] = list.s("id");
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