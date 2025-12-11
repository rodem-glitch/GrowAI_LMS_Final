package dao;

import malgnsoft.db.*;
import malgnsoft.util.Http;
import malgnsoft.util.Malgn;
import java.util.regex.*;
import java.util.*;

public class CodeDao extends DataObject {

	public CodeDao() {
		this.table = "TB_CODE";
	}

	public int sortDepth(int id, int num, int pnum, int sid) {
		if(id == 0 || num == 0 || pnum == 0) return -1;
		DataSet info = this.find("id = " + id + "");
		if(!info.next()) return -1;
		this.execute("UPDATE " + this.table + " SET sort = sort * 1000 WHERE site_id = " + sid + " AND depth = " + info.getInt("depth") + " AND parent_id = " + info.i("parent_id") + "");
		this.execute("UPDATE " + this.table + " SET sort = " + num + " * 1000" + (pnum <= num ? "+1" : "-1") + " WHERE id = " + id + "");
		return autoSort(info.getInt("depth"), info.getInt("parent_id"), info.i("site_id"));
	}

	public int autoSort(int depth, int pid, int sid) {
		DataSet list = this.find("site_id = " + sid + " AND depth=" + depth + " AND parent_id = " + pid + "", "id, sort", "sort ASC");
		int sort = 1;
		while(list.next()) {
			this.execute("UPDATE " + this.table + " SET sort = " + sort + " WHERE id = " + list.getInt("id") + "");
			sort++;
		}
		return 1;
	}

	public String[] getCodes(String code, int sid) {
		DataSet list = this.find("parent_id = (SELECT id FROM " + this.table + " WHERE site_id = " + sid + " AND code = '" + code + "' AND parent_id = 0)", "*", "sort ASC");
		String[] arr = new String[list.size()];
		int i = 0;
		while(list.next()) {
			arr[i] = list.s("code") + "=>" + list.s("name");
			i++;
		}
		list.first();
		return arr;
	}

	/* utility */
	public boolean isMobile(String value) {
		Pattern pattern = Pattern.compile("^([0-9]{2,3}-?[0-9]{3,4}-?[0-9]{4})$");
		Matcher match = pattern.matcher(value);
		return match.find();
	}

	public boolean isMail(String value) {
		Pattern pattern = Pattern.compile("^[a-z0-9A-Z\\_\\.\\-]+@([a-z0-9A-Z\\.\\-]+)\\.([a-zA-Z]+)$");
		Matcher match = pattern.matcher(value);
		return match.find();
	}

	public DataSet getYears() {
		return getYears(Malgn.parseInt(Malgn.getTimeString("yyyy")));
	}
	public DataSet getYears(String year) {
		if("".equals(year)) year = Malgn.getTimeString("yyyy");
		return getYears(Malgn.parseInt(year));
	}
	public DataSet getYears(int year) {
		DataSet list = new DataSet();
		for(int i=year-5; i<year+5; i++) {
			list.addRow();
			list.put("id", i);
			list.put("name", i);
		}
		list.first();
		return list;
	}
	public DataSet getMonths() {
		DataSet months = new DataSet();
		for(int i = 1; i <= 12; i++) {
			months.addRow();
			months.put("id", (i < 10 ? "0" : "") + i);
			months.put("name", (i < 10 ? "0" : "") + i);
		}
		return months;
	}

	public DataSet getDays() {
		DataSet days = new DataSet();
		for(int i=1; i<=31; i++) {
			days.addRow();
			days.put("id", (i < 10 ? "0" : "") + i);
			days.put("name", (i < 10 ? "0" : "") + i);
		}
		days.first();
		return days;
	}

	public DataSet getHours() {
		DataSet hours = new DataSet();
		for(int i=0; i<24; i++) {
			hours.addRow();
			hours.put("id", (i < 10 ? "0" : "") + i);
			hours.put("name", (i < 10 ? "0" : "") + i);
		}
		hours.first();
		return hours;
	}

	public DataSet getMinutes() {
		return getMinutes(1);
	}
	public DataSet getMinutes(int step) {
		DataSet minutes = new DataSet();
		for(int i=0; i<60; i+=step) {
			minutes.addRow();
			minutes.put("id", (i < 10 ? "0" : "") + i);
			minutes.put("name", (i < 10 ? "0" : "") + i);
		}
		minutes.first();
		return minutes;
	}

	public int getWeekNum(String date, String format) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(Malgn.strToDate(format, date));
		return calendar.get(calendar.DAY_OF_WEEK);
	}

	public int getWeekNum(String date) {
		return getWeekNum(date, "yyyyMMdd");
	}

	public Date getWeekFirstDate(String date) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(Malgn.strToDate("yyyyMMdd", date));
		return Malgn.addDate("D", -1 * calendar.get(calendar.DAY_OF_WEEK) + 1, calendar.getTime());
	}
	public Date getWeekLastDate(String date) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(Malgn.strToDate("yyyyMMdd", date));
		return Malgn.addDate("D", 7 - calendar.get(calendar.DAY_OF_WEEK), calendar.getTime());
	}

	public DataSet getMonthDays(String date) {
		return getMonthDays(date, "yyyy-MM-dd");
	}
	public DataSet getMonthDays(String date, String format) {
		int month = Integer.parseInt(Malgn.getTimeString("MM", date));
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(Malgn.strToDate(format, date));
		Date startDate = Malgn.addDate("D", -1, getWeekFirstDate(Malgn.getTimeString("yyyyMM", date) + "01"));
		Date endDate = getWeekLastDate(Malgn.getTimeString("yyyyMM", date) + calendar.getActualMaximum(calendar.DAY_OF_MONTH));

		DataSet list = new DataSet(); int d = 0;
		while(true) {
			startDate = Malgn.addDate("D", 1, startDate);
			list.addRow();
			list.put("date", Malgn.getTimeString(format, startDate));
			if(Integer.parseInt(Malgn.getTimeString("MM", startDate)) < month) list.put("type", "1");
			if(Integer.parseInt(Malgn.getTimeString("MM", startDate)) == month) list.put("type", "2");
			if(Integer.parseInt(Malgn.getTimeString("MM", startDate)) > month) list.put("type", "3");
			list.put("weekday", (d % 7) + 1);
			list.put("__last", false);
			d++;

			if(Malgn.getTimeString(format, startDate).equals(Malgn.getTimeString(format, endDate))) break;
		}
		list.put("__last", true);
		list.first();
		return list;
	}

	public String getRandomQuery(String sql, int limit) {
		String dbType = this.getDBType();
		if("oracle".equals(dbType)) {
			sql = "SELECT * FROM (" + sql + " ORDER BY dbms_random.value) WHERE rownum  <= " + limit;
		} else if("mssql".equals(dbType)) {
			sql = sql.replaceAll("(?i)^(SELECT)", "SELECT TOP(" + limit + ")") + " ORDER BY NEWID()";
		} else if("db2".equals(dbType)) {
			sql = sql.replaceAll("(?i)^(SELECT)", "SELECT RAND() as IDXX, ") + " ORDER BY IDXX FETCH FIRST " + limit + " ROWS ONLY";
		} else {
			sql += " ORDER BY RAND() LIMIT " + limit;
		}
		return sql;
	}

	public String getLimitQuery(String sql, int limit) {
		String dbType = getDBType();
		if("oracle".equals(dbType)) {
			sql = "SELECT * FROM (" + sql + ") WHERE rownum  <= " + limit;
		} else if("mssql".equals(dbType)) {
			sql = sql.replaceAll("(?i)^(SELECT)", "SELECT TOP(" + limit + ")");
		} else if("db2".equals(dbType)) {
			sql += " FETCH FIRST " + limit + " ROWS ONLY";
		} else {
			sql += " LIMIT " + limit;
		}
		return sql;
	}

	public String getConcatQuery(String[] arr) {
		String dbType = getDBType();
		String str = "";
		if("mssql".equals(dbType)) {
			str = Malgn.join(" + ", arr);
		} else if("oracle".equals(dbType)) {
			str = Malgn.join(" || ", arr);
		} else {
			str = "CONCAT(" + Malgn.join(", ", arr) + ")";
		}
		return str;
	}

/* Make Tree by Hierarchy data
 	 *
	 */

	public String name = "id";
	public String pName = "parent_id";
	public String nName = "name";
	public String rootNode = "-";
	private DataSet data;
	private Hashtable map;
	private Hashtable pMap;
	private DataSet result;
	private Vector pNodes;
	private Vector pNames;

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
			String pid = data.getString(pName);
			Vector nodes = pMap.containsKey(pid) ? (Vector)pMap.get(pid) : new Vector();
			nodes.add(data.getRow());
			pMap.put(pid, nodes);
			if(!rootNode.equals(id) && data.getString(name).equals(id)) sRow.addRow(data.getRow());
			if(rootNode.equals(id) && i++ == 0) sRow.addRow(data.getRow());
		}
		result = new DataSet(); sRow.first();
		if(sRow.next()) {
			result.addRow(sRow.getRow());
			childNodes(sRow.getString(name));
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
		while(list.next()) nodes[i++] = list.getString("id");
		return nodes;
	}

	public String[] getParentNodes(String id) throws Exception {
		if(null == data) return new String[] {};
		data.first();
		map = new Hashtable();
		while(data.next()) map.put(data.getString(name), data.getRow());
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
		while(data.next()) map.put(data.getString(name), data.getRow());
		pNodes = new Vector(); pNames = new Vector();
		parentNodes(id + "");
		return pNames;
	}

}