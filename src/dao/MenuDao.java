package dao;

import java.io.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

import malgnsoft.util.*;
import malgnsoft.db.*;

public class MenuDao extends DataObject {

	private Page p;
	private int siteId;
	private int manualId = 0;
	private String locale = "default";
	public String menuNm = "";

	public MenuDao() {
		this.table = "TB_MENU";
	}
	public MenuDao(Page p, String locale) {
		this.table = "TB_MENU";
		this.p = p;
		this.locale = locale;
	}
	public MenuDao(Page p, int siteId, String locale) {
		this.table = "TB_MENU";
		this.p = p;
		this.siteId = siteId;
		this.locale = locale;
	}

	public boolean accessible(int id, int userId, String type) throws Exception {
		return accessible(id, userId, type, true);
	}

	public boolean accessible(int id, int userId, String type, boolean setPageYn) throws Exception {
		boolean isAuth = false;
		if(this.p != null) {
			DataSet info = find("id = " + id);
			if(info.next()) {
				UserMenuDao userMenu = new UserMenuDao();
				SiteMenuDao siteMenu = new SiteMenuDao();
				MenuLocaleDao menuLocale = new MenuLocaleDao(this.locale);
				if("S".equals(type)) isAuth = true;
				else if(!"".equals(userId) && userMenu.findCount("menu_id = " + id + " AND user_id = " + userId + "") > 0) isAuth = true;
				if(0 < this.siteId && siteMenu.findCount("menu_id = " + id + " AND site_id = " + siteId) < 1) isAuth = false;
				if(setPageYn) {
					p.setLayout(info.s("layout"));
					p.setVar("p_title", menuLocale.getName(id, info.s("menu_nm")));
					p.setVar("Menu", info);
				}
				this.manualId = info.i("manual_id");
				this.menuNm = info.s("menu_nm");
			} else return isAuth;
		}
		return isAuth;
	}

	//파일 자동생성
	public void createFile(String url, String MID) throws Exception {
		BufferedWriter bw = null;
		BufferedWriter bw2 = null;
		try {
			if (url.indexOf("http://") == -1) {
				String docRoot = Config.getDocRoot() + "/sysop";
				url = Malgn.replace(url.substring(0, (url.indexOf("?") != -1 ? url.indexOf("?") : url.length())), "..", "");
				String path = docRoot + url;
				String path2 = docRoot + "/html" + Malgn.replace(url, ".jsp", ".html");
				File jsp = new File(path);
				File html = new File(path2);
				String[] arr = url.split("\\/");
				String ownerAccount = Config.get("ownerAccount");

				if (arr.length == 3) {
					if (!jsp.exists()) {
						if (null == jsp.getParentFile()) throw new NullPointerException();
						if (!jsp.getParentFile().isDirectory()) jsp.getParentFile().mkdirs();
						StringBuffer buff = new StringBuffer();
						buff.append("<__@ page contentType=\"text/html; charset=utf-8\" __><__@ include file=\"init.jsp\" __><__");
						buff.append("\n");
						buff.append("\nif(!Menu.accessible(" + MID + ", userId, userKind)) { m.jsError(\"접근 권한이 없습니다.\"); return; }");
						buff.append("\n");
						buff.append("\n//객체");
						buff.append("\n");
						buff.append("\n//출력");
						buff.append("\np.setBody(\"" + arr[1] + "." + Malgn.replace(arr[2], ".jsp", "") + "\");");
						buff.append("\np.setVar(\"list_query\", m.qs(\"id\"));");
						buff.append("\np.setVar(\"query\", m.qs());");
						buff.append("\np.display();");
						buff.append("\n");
						buff.append("\n__>");
						bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(path), "UTF8"));
						bw.write(Malgn.replace(buff.toString().trim(), "__", "%"));

						String initPath = jsp.getParentFile() + "/init.jsp";
						if (!new File(initPath).exists()) {
							StringBuffer buff2 = new StringBuffer();
							buff2.append("<__@ include file=\"../init.jsp\" __><__");
							buff2.append("\n");
							buff2.append("\nString ch = \"sysop\";");
							buff2.append("\n");
							buff2.append("\n__>");
							bw2 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(initPath), "UTF8"));
							bw2.write(Malgn.replace(buff2.toString().trim(), "__", "%"));
						}

						if (!"".equals(ownerAccount)) {
							try {
								Runtime.getRuntime().exec("chown -R " + ownerAccount + ":" + ownerAccount + " " + jsp.getParentFile());
							} catch (RuntimeException re) {
								Malgn.errorLog("RuntimeException : MenuDao.createFile() : " + re.getMessage(), re);
							} catch (Exception e) {
								Malgn.errorLog("Exception : MenuDao.createFile() : " + e.getMessage(), e);
							}
						}
					}

					if (!html.exists()) {
						if (null == html.getParentFile()) throw new NullPointerException();
						if (!html.getParentFile().isDirectory()) html.getParentFile().mkdirs();
						bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(path2), "UTF8"));
						bw.write(path2);

						if (!"".equals(ownerAccount)) {
							try {
								Runtime.getRuntime().exec("chown -R " + ownerAccount + ":" + ownerAccount + " " + html.getParentFile());
							} catch (RuntimeException re) {
								Malgn.errorLog("RuntimeException : MenuDao.createFile() : " + re.getMessage(), re);
							} catch (Exception e) {
								Malgn.errorLog("Exception : MenuDao.createFile() : " + e.getMessage(), e);
							}
						}
					}
				}
			}
		} catch (IOException ioe) {
			Malgn.errorLog("IOException : MenuDao.createFile() : " + ioe.getMessage(), ioe);
		} catch (Exception e) {
			Malgn.errorLog("Exception : MenuDao.createFile() : " + e.getMessage(), e);
		} finally {
			bw.close();
			bw2.close();
		}
	}

	public int getManualId() {
		return this.manualId;
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
			Malgn.errorLog("NullPointerException : MenuDao.getLayouts() : " + npe.getMessage(), npe);
			return new DataSet();
		}
	}

	public int sortMenu(int id, int num, int pnum) {
		return sortMenu(id, num, pnum, "ADMIN");
	}

	public int sortMenu(int id, int num, int pnum, String type) {
		if(id == 0 || num == 0 || pnum == 0) return -1;
		DataSet info = this.find("id= " + id);
		if(!info.next()) return -1;
		this.execute("UPDATE " + table + " SET sort = sort * 1000 WHERE menu_type = '" + type + "' AND depth = " + info.i("depth") + " AND menu_type = '" + info.s("menu_type") + "' AND parent_id = " + info.i("parent_id") + "");
		this.execute("UPDATE " + table + " SET sort = " + num + " * 1000" + (pnum <= num ? "+1" : "-1") + " WHERE menu_type = '" + type + "' AND id = " + id);
		return autoSort(info.i("depth"), info.i("parent_id"), info.s("menu_type"));
	}

	public int autoSort(int depth, int pmenu, String type) {
		DataSet list = this.find("menu_type = '" + type + "' AND depth = " + depth + " AND parent_id = " + pmenu + "", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + table + " SET sort = " + sort + " WHERE id = " + list.i("id") + "");
			sort++;
		}
		return 1;
	}

	public DataSet getList(String type) throws Exception {
		DataSet list = find("status != -1 AND menu_type = '" + type + "'", "*", "depth ASC, sort ASC");
		setData(list);
		return getTreeList(type);
	}


	public DataSet getTreeList(String type) throws Exception {
		DataSet tops = find("status = 1 AND depth = 1 AND menu_type = '" + type + "'", "*", "sort ASC");
		DataSet tree = new DataSet();
		while(tops.next()) {
			tree.addRow(tops.getRow());
			tree.put("name_conv", tops.s("menu_nm"));
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
		String names = info.s("menu_nm");
		int pid = info.i("parent_id");
		for(int i = info.i("depth"); i > 1; i--) {
			DataSet pinfo = this.find("id = " + pid);
			if(pinfo.next()) {
				names =	pinfo.s("menu_nm") + " > " + names;
				pid = pinfo.i("parent_id");
			} else { break;	}
		}
		return names;
	}

	/*
 	 *  Make Tree by Hierarchy data
	 */

	public String name = "id";
	public String pName = "parent_id";
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