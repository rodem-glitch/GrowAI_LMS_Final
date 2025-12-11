<%@ page contentType="text/html; charset=UTF-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//기본키
String module = m.rs("module");
int moduleId = m.ri("module_id");

//객체
ClCommentDao comment = new ClCommentDao(siteId); comment.setMaskYn("Y".equals(SiteConfig.s("masking_yn")));
Json j = new Json(out);

//변수
String mode = m.rs("mode");

if(moduleId < 1 || "".equals(module)) { j.print(-1, "기본키는 반드시 지정하여야 합니다."); return; }

if(m.isPost()) {
    if("comment_add".equals(mode)) {
        //폼체크
        f.addElement("content", null, "hname:'댓글', required:'Y'");

        if(f.validate()) {
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, "내용은 1000글자를 초과해 작성하실 수 없습니다.\\n(현재 " + textLength + "글자)"); return; }

            int newId = comment.getSequence();
            comment.item("id", newId);
            comment.item("site_id", siteId);
            comment.item("module", module);
            comment.item("module_id", moduleId);
            if("post".equals(module)) comment.item("post_id", moduleId);
            comment.item("user_id", userId);
            comment.item("writer", userName);
            comment.item("content", content);
            comment.item("mod_date", "");
            comment.item("reg_date", sysNow);
            comment.item("status", 1);
            if(!comment.insert()) { j.print(-1, "등록하는 중 오류가 발생하였습니다."); return; }

            j.setJson(new JSONObject(comment.getInfo(newId)).toString());
            j.print(0, "등록 되었습니다.");
        }

    } else if("comment_modify".equals(mode)) {
        //폼체크
        f.addElement("content", null, "hname:'댓글', required:'Y'");
        if(f.validate()) {
            //기본키
            int commentId = f.getInt("comment_id");
            if(commentId == 0) { j.print(-1, "기본키는 반드시 지정해야 합니다."); return; }

            //변수
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, "내용은 1000글자를 초과해 작성하실 수 없습니다.\\n(현재 " + textLength + "글자)"); return; }

            //정보
            DataSet info = comment.find("module = 'clpost' AND module_id = " + moduleId + " AND id = " + commentId + " AND status = 1");
            if(!info.next()) { j.print(-1, "해당 정보가 없습니다."); return; }

            //수정
            comment.item("mod_date", sysNow);
            comment.item("content", f.get("content"));
            if(!comment.update("module = 'clpost' AND module_id = " + moduleId + " AND id = " + info.i("id") + " AND status = 1")) { j.print(-1, "수정하는 중 오류가 발생하였습니다."); return; }

            j.setJson(new JSONObject(comment.getInfo(commentId)).toString());
            j.print(0, "수정 하였습니다.");
        }

    } else if("del".equals(mode)) {

        //기본키
        int commentId = f.getInt("comment_id");
        if(commentId == 0) { j.print(-1, "기본키는 반드시 지정해야 합니다."); return; }

        //정보
        DataSet info = comment.find("module = 'clpost' AND module_id = " + moduleId + " AND id = " + commentId + " AND status = 1");
        if(!info.next()) { j.print(-1, "해당 정보가 없습니다."); return; }

        //삭제
        comment.item("status", -1);
        if(!comment.update("module = 'clpost' AND module_id = " + moduleId + " AND id = " + info.i("id") + " AND status = 1")) { j.print(-1, "삭제하는 중 오류가 발생하였습니다."); return; }

        j.print(0, "삭제 하였습니다.");

    } else if("comment_list".equals(mode)) {

        JSONArray commentArr = new JSONArray(comment.getList(moduleId, module));
        j.put("data_list", commentArr);
        j.print(0, "등록된 댓글 목록 출력");

    } else if("reply_add".equals(mode)) {
        //폼체크
        f.addElement("parent_id", null, "hname:'답글대상아이디', required:'Y'");
        f.addElement("reply_user_id", null, "hname:'답글대상회원아이디', required:'Y'");
        f.addElement("content", null, "hname:'댓글', required:'Y'");

        if(f.validate()) {
            //기본키
            int parentId = f.getInt("parent_id");
            int replyUserId = f.getInt("reply_user_id");
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, "내용은 1000글자를 초과해 작성하실 수 없습니다.\\n(현재 " + textLength + "글자)"); return; }

            int newId = comment.getSequence();
            comment.item("id", newId);
            comment.item("site_id", siteId);
            comment.item("module", module);
            comment.item("module_id", moduleId);
            comment.item("parent_id", parentId);
            if("post".equals(module)) comment.item("post_id", moduleId);
            comment.item("user_id", userId);
            comment.item("writer", userName);
            comment.item("reply_user_id", replyUserId);
            comment.item("content", content);
            comment.item("mod_date", "");
            comment.item("reg_date", sysNow);
            comment.item("status", 1);
            if(!comment.insert()) { j.print(-1, "등록하는 중 오류가 발생하였습니다."); return; }

            j.setJson(new JSONObject(comment.getReplyInfo(newId)).toString());
            j.print(0, "등록 되었습니다.");
        }
    }
}

%>