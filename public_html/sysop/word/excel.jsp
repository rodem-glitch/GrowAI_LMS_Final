<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp"%><%

//접근권한
if(!(Menu.accessible(918, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WordFilterDao wordFilterDao = new WordFilterDao();

f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost() && f.validate()) {
    
    //배열
    String[] fields = { "col0=>word"};
    
    String[] required = { "col0" };
    
    String path = dataDir + "/tmp/word.xls";
    File f1 = f.saveFile("file", path);
    if(f1 == null) {
        m.jsAlert("엑셀파일을 읽는 중 오류가 발생했습니다.");
        return;
    }
    
    DataSet records = new DataSet();
    
    records = new ExcelReader(path).getDataSet(1);
    
    if(!"".equals(path)) m.delFile(path);
    
    //목록
    if("register".equals(f.get("mode"))) {
        
        //변수
        int successCnt = 0;
        int invalidCnt = 0;
        
        //폼입력
        int i = 0;
        while(records.next()) {
            boolean flag = true;
            for(int j = 0; j < required.length; j++) {
                if("".equals(records.s(required[j]))) flag = false;
            }
            
            if(flag) {
                String word = records.s("col0");
    
                //제한-100자 넘김
                if(word.length() > 100) {
                    invalidCnt++;
                    continue;
                }
    
                //제한-이미 존재하는단어
                if(wordFilterDao.check(word)) {
                    invalidCnt++;
                    continue;
                }
                
                int newId = wordFilterDao.add(word);
                if(newId > 0) successCnt++;
                else invalidCnt++;
            }
        }
        
        m.jsAlert("총 " + successCnt + "개가 등록됐습니다.\\n실패 : " + invalidCnt + "개\\n등록된 데이터를 확인해주세요.");
        
        m.jsReplace("list.jsp", "parent");
        return;
        
    } else if("list".equals(f.get("mode"))) {
        
        //포맷팅
        DataSet list = new DataSet();
        DataSet tmp = m.arr2loop(fields);
        int i = 0;
        while(records.next()) {
            boolean flag = true;
            for(int j = 0; j < required.length; j++) {
                if("".equals(records.s(required[j]))) flag = false;
            }
            
            if(flag) {
                tmp.first();
                while(tmp.next()) {
                    records.put(tmp.s("name"), records.s(tmp.s("id")));
                }
    
                String word = records.s("word");
                if(word.length() > 100) {
                    continue;
                }
    
                //제한-이미 존재하는단어
                if(wordFilterDao.check(word)) {
                    continue;
                }
                
                records.put("word_conv", Malgn.htt(word));
                records.put("__ord", ++i);
                
                list.addRow(records.getRow());
            }
            if(i == 20) break;
        }
        
        //출력
        p.setLayout("blank");
        p.setBody("word.excel");
        p.setVar("query", m.qs());
        p.setVar("list_query", m.qs("id"));
        p.setVar("form_script", f.getScript());
        
        p.setLoop("list", list);
        p.setVar("list_area", true);
        p.display();
        
        return;
    }
}

//출력
p.setLayout(ch);
p.setBody("word.excel");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("upload_area", true);

p.display();

%>