<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//변수
String templateType = "P".equals(m.rs("type")) ? "P" : "C";

//접근권한
int menuId = "P".equals(templateType) ? 931 : 914;
if(!Menu.accessible(menuId, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

//폼체크
f.addElement("type", templateType, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(certificateTemplate.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.template_type = '" + templateType + "'");
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.template_cd, a.template_nm, a.content", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("template_nm_conv", m.cutString(list.s("template_nm"), 100));
    list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
    list.put("status_conv", m.getItem(list.s("status"), certificateTemplate.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
    String excelTitle = ("P".equals(templateType) ? "합격증" : "수료증") + "템플릿관리(" + m.time("yyyy-MM-dd") + ")";
    ExcelWriter ex = new ExcelWriter(response, excelTitle + ".xls");
    ex.setData(list, new String[] { "__ord=>No", "template_cd=>템플릿코드", "template_nm=>템플릿명", "content=>내용", "status_conv=>상태" }, excelTitle);
    ex.write();
    return;
}

//출력
p.setBody("certificate.template_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,type"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(certificateTemplate.statusList));
p.setVar("template_type", templateType);
p.display();

%>
