<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(19, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();

String[] keys = { "col0=>id", "col1=>name", "col2=>passwd", "col3=>email", "col4=>mobile", "col5=>birthday", "col6=>sex", "col7=>zipcode", "col8=>addr1", "col9=>addr2"};

DataSet list = new DataSet();
//파일업로드시
if(m.isPost()) {
	File file = f.saveFile("file");
	if(null != file) {
		String path = m.getUploadPath(f.getFileName("file"));
		list = new ExcelReader(path).getDataSet(1);
		if(!"".equals(path)) m.delFileRoot(path);

		//포멧팅
		DataSet tmp = m.arr2loop(keys);
		int i=0;
		while(list.next()) {
			tmp.first();
			while(tmp.next()) {
				list.put(tmp.s("name"), list.s(tmp.s("id")));
			}
			list.put("gender", m.getItem(list.s("gender"), user.genders));
			list.put("__ord", ++i);
		}
	}
}


//출력
p.setLayout("blank");
p.setBody("user.user_reg");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setLoop("list", list);
p.display();

%>