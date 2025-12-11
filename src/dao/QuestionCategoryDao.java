package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;
import java.io.*;

public class QuestionCategoryDao extends DataObject {

	private HashMap<String, DataSet> subset = new HashMap<String, DataSet>();

	public QuestionCategoryDao() {
		this.table = "LM_QUESTION_CATEGORY";
		this.PK = "id";
	}

	public DataSet getList(int siteId) throws Exception {
		DataSet list = find("status = 1 AND site_id = " + siteId + " ", "*", "depth ASC, sort ASC");
		return getTreeSet(list);
		//setData(list);
		//return getTreeList(siteId);
	}

	public DataSet getTreeSet(DataSet rs) {
		while(rs.next()) {
			String pcd = rs.s("parent_id");
			if(!"0".equals(pcd)) {
				if(!subset.containsKey(pcd)) subset.put(pcd, new DataSet());
				subset.get(pcd).addRow(rs.getRow());
			}
		}
		rs.first();
		DataSet ret = new DataSet();
		while(rs.next()) {
			if("0".equals(rs.s("parent_id"))) {
				ret.addRow(rs.getRow());
				ret.put("name_conv", rs.s("category_nm"));
				addSub(rs.s("id"), ret, rs.s("category_nm"));
			}
		}
		ret.first();
		return ret;
	}

	private void addSub(String key, DataSet ret, String name) {
		if(subset.containsKey(key)) {
			DataSet sub = subset.get(key);
			sub.first();
			while(sub.next()) {
				ret.addRow(sub.getRow());
				String pathName = name + " > " + sub.s("category_nm");
				ret.put("name_conv", pathName);
				addSub(sub.s("id"), ret, pathName);
			}
		}
	}
	
	public DataSet getTreeList(int siteId) throws Exception {
		DataSet tops = find("status = 1 AND depth = 1 AND site_id = " + siteId + " ", "*", "sort ASC");
		DataSet tree = new DataSet();
		while(tops.next()) {
			tree.addRow(tops.getRow());
			tree.put("name_conv", tops.s("category_nm"));
			DataSet ds = getTree(tops.s("id"));
			while(ds.next()) {
				if(ds.i("depth") > 1) { 
					ds.put("name_conv", getTreeNames(ds.s("id")));
					tree.addRow(ds.getRow());
				}
			}
		}
		tree.first();
		return tree;
	}
	
	public String getTreeNames(int id) throws Exception {
		return getTreeNames(""+id);
	}

	public String getTreeNames(String id) throws Exception {
		Vector<String> v = getParentNames(id);
		Collections.reverse(v); 
		return Malgn.join(" > ", v.toArray());
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

	public int sortDepth(int id, int num, int mnum, int siteId) {
		if("".equals(id) || num == 0 || mnum == 0) return -1;
		DataSet info = this.find("id = " + id + " AND status = 1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE site_id = " + siteId + " AND parent_id = " + info.i("parent_id") + " AND depth = " + info.i("depth") + " AND status = 1");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + ( num >= mnum ? "+1" : "-1") + " WHERE id = " + id);
		return autoSort(info.i("depth"), info.i("parent_id"), info.i("site_id"));
	}

	public int autoSort(int depth, int pid, int siteId) {
		DataSet list = this.find("site_id = " + siteId + " AND parent_id = " + pid + " AND depth = " + depth + " AND status = 1", "id, sort", "sort ASC");
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
		while(list.next()) nodes[i++] = list.s("id");
		return nodes;
	}

	public String[] getChildNodes(String id, DataSet rs) throws Exception {
		rs.first();
		DataSet ret = new DataSet();
		while(rs.next()) {
			if(id.equals(rs.s("parent_id"))) {
				ret.addRow(rs.getRow());
				ret.put("name_conv", rs.s("category_nm"));
				addSub(rs.s("id"), ret, rs.s("category_nm"));
			}
		}
		ret.first();

		String[] nodes = new String[ret.size() + 1]; int i = 0;
		nodes[i++] = id;
		while(ret.next()) nodes[i++] = ret.s("id");
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