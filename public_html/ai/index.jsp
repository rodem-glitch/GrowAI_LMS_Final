<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String module = m.rs("module", "lesson");
int moduleId = m.ri("module_id");
if(moduleId == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String mode = m.rs("mode");
int pid = 0;
Json j = new Json(out);

//객체
DataObject dao = new LessonDao();
if("lesson".equals(module)) {
    dao = new LessonDao();
}
OpenAiDao ai = new OpenAiDao(siteId);

//정보
DataSet info = dao.find("id = " + moduleId + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }
if(!info.b("ai_chat_yn")) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }

if(m.isPost() && "chat".equals(mode)) {
    int parentId = m.ri("parent_id");
    String content = Malgn.htt(f.get("content"));
    if("".equals(content)) { j.error(-1, _message.get("alert.common.enter_contents")); return; }

    DataSet prevInfo = ai.find("id = ? AND user_id = ? AND module = ? AND module_id = ?", new Object[] { parentId, userId, module, moduleId }, "request_msg, response_msg, prompt_tokens, completion_tokens, total_tokens");

    ai.setEndUserId(userId, moduleId);

    //질의
    j = ai.chat(content, prevInfo);

    //결과 확인 및 데이터 등록
    if(!"".equals(j.getString("//choices/0/message/content"))) {
        DataSet result = new DataSet();
        result.addRow();
        result.put("parent_id", parentId);
        result.put("site_id", siteId);
        result.put("user_id", userId);
        result.put("module", module);
        result.put("module_id", moduleId);
        result.put("content", content);
        result.put("data", j.toString());
        int newId = ai.add(result);

        j.put("id", newId);
        j.put("content", Malgn.nl2br(j.getString("//choices/0/message/content")));

    }

    j.setWriter(out);
    j.print(0, "success");
    return;
}

//목록-기존 채팅정보
DataSet list = ai.find("module = ? AND module_id = ? AND user_id = ?", new Object[] { module, moduleId, userId }, "id, request_msg, response_msg, reg_date", "id desc", 10);
list.sort("id", "ASC");
while(list.next()) {
    list.put("question", Malgn.nl2br(Malgn.htt(list.s("request_msg"))));
    list.put("answer", Malgn.nl2br(Malgn.htt(list.s("response_msg"))));
    list.put("reg_date_conv", Malgn.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
    pid = list.i("id");
}

//출력
p.setLayout(null);
p.setBody("ai.index");

p.setVar("module", info);

p.setLoop("list", list);

p.setVar("parent_id", pid);

p.display();

%>