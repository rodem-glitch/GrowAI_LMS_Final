<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp"%><%

//접근권한
if(!(Menu.accessible(918, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WordFilterDao wordFilterDao = new WordFilterDao();

f.addElement("word", null, "hname:'비속어', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
    String word = f.get("word");
    
    //제한-100자 넘는 단어
    if(word.length() > 100) {
        m.jsAlert("필터단어는 100자를 넘을 수 없습니다.");
        return;
    }
    
    //제한-이미 존재하는단어
    if(wordFilterDao.check(word)) {
        m.jsAlert("이미 존재하는 단어입니다.");
        return;
    }
    
    //등록
    wordFilterDao.add(word);
    
    m.jsAlert("등록하였습니다.");
    m.js("parent.parent.location.href = parent.parent.location.href");
    return;
}


//출력
p.setLayout("poplayer");
p.setBody("word.insert");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.display();

%>