<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//기본키
String module = m.rs("module");
int moduleId = m.ri("module_id");

//객체
CommentDao comment = new CommentDao(siteId); comment.setMaskYn("Y".equals(SiteConfig.s("masking_yn")));
Json j = new Json(out);

BoardDao board = new BoardDao();
PostDao post = new PostDao();

WebtvDao webtv = new WebtvDao();

//변수
String mode = m.rs("mode");
boolean isWrite = 0 < userId;
boolean isAdmin = 0 < userId && "S".equals(userKind);
boolean isDelete = isAdmin;

//print(int code, String message)
if(moduleId < 1 || "".equals(module)) { j.print(-1, _message.get("alert.common.required_key")); return; }

//모듈별제한
if("post".equals(module)) {
    DataSet minfo = post.query(
        " SELECT a.*, b.private_yn, b.admin_idx "
            + " FROM " + post.table + " a "
            + " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.comment_yn = 'Y' "
            + " WHERE a.id = ? AND a.status = 1 AND a.display_yn = 'Y' "
        , new Object[] { moduleId }
    );
    if(!minfo.next()) { j.print(-1, _message.get("alert.post.nodata")); return; }
    if(minfo.b("private_yn") && userId != minfo.i("user_id")) { j.print(-1, _message.get("alert.post.nodata")); return; }
    isWrite = board.accessible("comm", minfo.i("board_id"), userGroups, userKind);
    try {
        isAdmin = 0 != userId && ("S".equals(userKind) || Menu.accessible(80, userId, userKind, false) || minfo.s("admin_idx").contains("|" + userId + "|"));
    } catch (Exception e) {
        Malgn.errorLog("{comment.call_comment} Menu access error", e);
    }
} else if("webtv".equals(module)) {
    DataSet minfo = webtv.find("id = ? AND comment_yn = 'Y' AND status = 1", new Object[] { moduleId });
    if(!minfo.next()) { j.print(-1, _message.get("alert.webtv.nodata")); return; }
}

if(m.isPost()) {
    if("comment_add".equals(mode)) {
        //폼체크
        f.addElement("content", null, "hname:'댓글', required:'Y'");

        if(f.validate() && isWrite) {
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, _message.get("alert.board.capacity_text", new String[] {"maximum=>1000", "text_length=>" + textLength})); return; }

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
            if(!comment.insert()) { j.print(-1, _message.get("alert.common.error_insert")); return; }

            j.setJson(new JSONObject(comment.getInfo(newId)).toString());
            j.print(0, "등록 하였습니다.");
        } else if(!isWrite) {
            j.print(-1, _message.get("alert.common.permission_insert")); return;
        }

    } else if("comment_modify".equals(mode)) {
        //폼체크
        f.addElement("content", null, "hname:'댓글', required:'Y'");
        if(f.validate() && isWrite) {
            //기본키
            int commentId = f.getInt("comment_id");
            if(commentId == 0) { j.print(-1, _message.get("alert.common.required_key")); return; }

            //변수
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, _message.get("alert.board.capacity_text", new String[] {"maximum=>1000", "text_length=>" + textLength})); return; }

            //정보
            DataSet info = comment.find("module = '" + module + "' AND module_id = " + moduleId + " AND id = " + commentId + " AND status = 1");
            if(!info.next()) { j.print(-1, _message.get("alert.common.nodata")); return; }

            //제한-작성자 또는 관리자
            if((info.i("user_id") != userId) && !isAdmin) { j.print(-1, _message.get("alert.common.permission_modify")); return; }

            //수정
            comment.item("mod_date", sysNow);
            comment.item("content", f.get("content"));
            if(!comment.update("module = '" + module + "' AND module_id = " + moduleId + " AND id = " + info.i("id") + " AND status = 1")) { j.print(-1, _message.get("alert.common.error_modify")); return; }

            j.setJson(new JSONObject(comment.getInfo(commentId)).toString());
            j.print(0, "수정 하였습니다.");
        }

    } else if("del".equals(mode)) {

        //기본키
        int commentId = f.getInt("comment_id");
        if(commentId == 0) { j.print(-1, _message.get("alert.common.required_key")); return; }

        //정보
        DataSet info = comment.find("module = '" + module + "' AND module_id = " + moduleId + " AND id = " + commentId + " AND status = 1");
        if(!info.next()) { j.print(-1, _message.get("alert.common.nodata")); return; }

        //제한-작성자 또는 관리자
        if((info.i("user_id") != userId) && !isAdmin) { j.print(-1, _message.get("alert.common.permission_delete")); return; }

        //삭제
        comment.item("status", -1);
        if(!comment.update("module = '" + module + "' AND module_id = " + moduleId + " AND id = " + info.i("id") + " AND status = 1")) { j.print(-1, _message.get("alert.common.error_delete")); return; }

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

        if(f.validate() && isWrite) {
            //기본키
            int parentId = f.getInt("parent_id");
            int replyUserId = f.getInt("reply_user_id");
            String content = f.get("content");

            //제한-글자수
            int textLength = Malgn.stripTags(content).length();
            if(1000 < textLength) { j.print(-1, _message.get("alert.board.capacity_text", new String[] {"maximum=>1000", "text_length=>" + textLength})); return; }

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
            if(!comment.insert()) { j.print(-1, _message.get("alert.common.error_insert")); return; }

            j.setJson(new JSONObject(comment.getReplyInfo(newId)).toString());
            j.print(0, "등록 되었습니다.");
        } else if(!isWrite) {
            j.print(-1, _message.get("alert.common.permission_insert")); return;
        }
    }
}

%>