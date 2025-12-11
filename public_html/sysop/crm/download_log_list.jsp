<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FileDao file = new FileDao();
FileLogDao fileLog = new FileLogDao();

//폼체트
f.addElement("s_start_date", null, null);
f.addElement("s_end_date", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	fileLog.table + " a "
	+ " LEFT JOIN " + file.table + " f ON a.file_id = f.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
);
lm.setFields("a.*, u.login_id, f.module, f.module_id");
lm.addWhere("a.user_id = " + uid + "");
if(!"".equals(f.get("s_start_date"))) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd", f.get("s_start_date")) + "000000'");
if(!"".equals(f.get("s_end_date"))) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd", f.get("s_end_date")) + "235959'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.ip_addr, a.agent, a.filename", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	int filesize = list.i("filesize") / 1024;
	if(filesize < 1024 ) { list.put("filesize_conv", m.nf(filesize) + "KB"); }
	if(filesize > 1024) { list.put("filesize_conv", m.nf((filesize / 1024)) + "MB"); }

	if(list.i("file_id") < 1) { list.put("file_id", "-"); }
	if(list.i("module_id") < 1) { list.put("module_id", "-");}
	if("".equals(list.s("module"))) { list.put("module", "-");}

	list.put("request_uri_conv", list.s("request_uri") + "?" + list.s("request_query"));
	list.put("agent_conv", fileLog.getBrowser(list.s("agent")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("filename_conv", m.cutString(list.s("filename"), 35));
}

//출력
p.setLayout(ch);
p.setBody("crm.download_log_list");
p.setVar("p_title", "다운로드");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("tab_log", "current");
p.setVar("tab_sub_download", "current");
p.display();

%>