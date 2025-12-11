package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;
import java.io.*;

public class ModuleDao extends DataObject {

	public String[] displayYn = { "Y=>노출", "N=>노출 안 함" };
	public String[] statuses = { "1=>정상", "0=>중지" };

	public String[] displayYnMsg = { "Y=>list.module.display_yn.Y", "N=>list.module.display_yn.N" };
	public String[] statusesMsg = { "1=>list.module.statuses.1", "0=>list.module.statuses.0" };

	public ModuleDao() {
		this.table = "TB_MODULE";
		this.PK = "id";
	}

	public DataSet getList() throws Exception {
		DataSet list = find("status = 1", "*", "depth ASC, sort ASC");
		setData(list);
		return getTreeList();
	}
	
	
	public DataSet getTreeList() throws Exception {
		DataSet tops = find("status = 1 AND depth = 1", "*", "sort ASC");
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

	public DataSet getSubList(int categoryId) throws Exception {
		return getSubList(categoryId, 0);
	}

	public DataSet getSubList(int categoryId, int depth) throws Exception {
		return find(
			"status = 1 AND parent_id = " + categoryId
			+ (0 < depth ? " AND depth = " + depth : "")
			+ " AND (display_yn = 'Y' OR depth > 1) "
			, "*"
			, "sort ASC"
		);
	}

	public String getSubIdx(int categoryId) throws Exception {
		if(data == null) {
			DataSet list = find("status = 1", "*", "depth ASC, sort ASC");
			setData(list);
		}
		String[] idx = getChildNodes("" + categoryId);
		return Malgn.join(", ", idx);
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

	public int sortDepth(int id, int num, int mnum) {
		if("".equals(id) || num == 0 || mnum == 0) return -1;
		DataSet info = this.find("id = " + id + " AND status = 1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE parent_id = " + info.i("parent_id") + " AND depth = " + info.i("depth") + " AND status = 1");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + ( num >= mnum ? "+1" : "-1") + " WHERE id = " + id);
		return autoSort(info.i("depth"), info.i("parent_id"));
	}

	public int sort(int id, int num, int pnum) {
		if(id == 0 || num == 0 || pnum == 0) return -1;
		DataSet info = this.find("id = " + id + " AND status != -1");
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE depth = " + info.i("depth") + " AND parent_id = " + info.i("parent_id") + "");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + (pnum <= num ? "+1" : "-1") + " WHERE id = " + id);
		return autoSort(info.i("depth"), info.i("parent_id"));
	}

	public int autoSort(int depth, int pid) {
		DataSet list = this.find("parent_id = " + pid + " AND depth = " + depth + " AND status = 1", "id, sort", "sort ASC");
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

	public Vector<String> getParentNames(String id) throws Exception {
		if(null == data) return new Vector();
		data.first();
		map = new Hashtable();
		while(data.next()) map.put(data.s(name), data.getRow());
		pNodes = new Vector(); pNames = new Vector();
		parentNodes(id + "");
		return pNames;
	}

}