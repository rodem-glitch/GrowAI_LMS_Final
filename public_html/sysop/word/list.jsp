<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(918, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WordFilterDao wordFilterDao = new WordFilterDao();

//변수
String mode = m.rs("mode");

//삭제
if("del".equals(mode)) {
    String[] idx = f.getArr("idx");
    for(int i = 0; i < idx.length; i++) {
        if(Malgn.parseInt(idx[i]) == 0) idx[i] = "0";
    }
    wordFilterDao.delete("id IN (" + Malgn.join(",", idx) + ")");
    wordFilterDao.clear();
    m.jsAlert("선택한 단어를 삭제하였습니다.");
    m.jsReplace("list.jsp?" + m.qs("mode"), "parent");
    return;
}

//폼체크
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(mode) ? sysExcelCnt : f.getInt("s_listnum", 20));
lm.setTable(
    wordFilterDao.table + " a "
);
lm.setFields("a.*");
lm.addSearch("a.word", f.get("s_keyword"), "LIKE");
lm.setOrderBy("a.id desc");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
    list.put("word_conv", Malgn.htt(list.s("word")));
    list.put("reg_date_conv", Malgn.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
}

//엑셀
if("excel".equals(mode)) {
    ExcelWriter ex = new ExcelWriter(response, "비속어관리(" + m.time("yyyy-MM-dd") + ").xls");
    ex.setData(list, new String[] { "__ord=>No", "word=>비속어", "reg_date_conv=>등록일", "status_conv=>상태" });
    ex.write();
    return;
}

//출력
p.setLayout(ch);
p.setBody("word.list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>