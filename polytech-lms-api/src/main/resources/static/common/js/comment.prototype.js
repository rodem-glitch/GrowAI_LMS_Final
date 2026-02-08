let COMMENT = function(module, moduleId, id, userId, deleteYn, isA) {
    if(!module || !moduleId || !id) {
        alert("COMMENT ERROR - missing required parameter : module, moduleId, id");
        return;
    }
    this.commentList = {};
    this.replyList = {};
    this.module = module;
    this.moduleId = moduleId;
    this.id = id;
    this.initName = "";
    this.callModule = "comment";
    this.initUserId = parseInt(userId);
    this.deleteYn = deleteYn;
    this.isA = isA;

    if(this.module === "clpost") {
        this.callModule = "clcomment";
    }

    if(!$) {
        alert("jQuery is required");
        return;
    }

    this.element = $("#" + id);
    if(!this.element) {
        alert("COMMENT ERROR - Element not found");
    }
}

COMMENT.prototype.adjustTextAreaHeight = function(el) {
    // el.style.height = "1px";
    el.style.height = el.scrollHeight + "px";
}

COMMENT.prototype.createComment = function() {
    const commentWrap = $("#" + this.id);
    if(this.isA) {
        //comment table
        const commentTable = $("<table class='c_tb01'>");
        //comment table tr
        const commentTbTr = $("<tr>");
        //comment table tr td
        const commentTbTrTd = $("<td class='c_th01'>");
        //comment table tr td span[comment_cnt]
        const commentCount = $("<span>댓글 <span id='comment_cnt'>0</span>개</span>");
        commentTbTrTd.append(commentCount);
        commentTbTr.append(commentTbTrTd);
        commentTable.append(commentTbTr);
        commentWrap.append(commentTable);
    }

    //comment input
    const commentInput = $("<div class='comment_input'>");
    //comment label
    const commentLabel = $("<label id='comment'>");
    //comment textarea
    const commentTextarea = $("<textarea name='comment' id='comment_area' placeholder='댓글을 입력해주세요.'>");
    commentTextarea.attr("onkeyup", (this.initName !== "" ? this.initName + ".adjustTextAreaHeight(this)" : ""));
    commentLabel.append(commentTextarea);
    //comment button
    const btnSubmit = $("<button type='button' class='bttn2'>등록</button>");
    btnSubmit.attr("onclick", (this.initName !== "" ? this.initName + ".addComment()" : ""));
    if(!this.isA) {
        commentInput.append($("<h4>댓글 <span id='comment_cnt'>0</span>개</h4>"));
        btnSubmit.addClass("bgColor");
    }
    commentInput.append(commentLabel);
    commentInput.append(btnSubmit);

    commentWrap.append(commentInput);
}

COMMENT.prototype.initComment = function() {
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=comment_list&module_id=" + this.moduleId, {}, function(ret) {
    }, 'json').then((ret) => {
        if (ret.error === 0) {
            // console.log(ret);
            this.createComment();
            const dataList = ret.data["data_list"];
            if (dataList.length > 0) {
                dataList.forEach((item) => {
                    // console.log(item.comment_id);
                    if (!this.commentList) this.commentList = {};
                    this.commentList[item.comment_id] = item;
                    const replyDataList = this.commentList[item.comment_id]["reply_list"];
                    if(replyDataList.length > 0) {
                        replyDataList.forEach((item) => {
                            if(!this.replyList[item.parent_id]) this.replyList[item.parent_id] = {};
                            this.replyList[item.parent_id][item.comment_id] = item;
                        });
                    }
                    // console.log(commentList[item.comment_id]);
                });
                // console.log(commentList);
            }
            this.addCommentList();
            this.updateCommentCount();
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.addCommentList = function() {
    for(let commentId in this.commentList) {
        this.appendComment(this.commentList[commentId]);
    }
}

COMMENT.prototype.addComment = function() {
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=comment_add&module_id=" + this.moduleId, { "content" : $("#comment_area").val() }, function(ret) {}, 'json').then((ret) => {
        if (ret.error === 0) {
            // console.log(ret);
            const commentId = ret.data.rows[0].comment_id;
            this.commentList[commentId] = ret.data.rows[0];
            this.appendComment(this.commentList[commentId]);
            this.updateCommentCount();
            $("#comment_area").val("");
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.appendComment = function(retData) {
    //wrap
    const commentBox = $("<div class='comment_box'>");
    commentBox.attr("data-cid", retData["comment_id"]);
    commentBox.attr("data-uid", retData["user_id"]);
    $("#" + this.id).append(commentBox);

    //comment
    const comment = $("<div class='comment'>");
    commentBox.append(comment);

    //comment header
    this.createCommentHeader(retData, comment);

    //comment body
    this.createCommentBody(retData, comment);
}

COMMENT.prototype.createCommentHeader = function(retData, parentEle) {
    //header
    const commentHeader = $("<div class='comment_header'>");
    parentEle.append(commentHeader);

    //comment user
    const commentUser = $("<span class='comment_user'>" + retData["user_nm"] + "(" + retData["login_id"] + ")" + "</span>");
    commentHeader.append(commentUser);

    //comment date
    const commentDate = $("<span class='comment_date'>" + retData["date_conv"] + "</span>");
    commentHeader.append(commentDate);

    //post writer
    if(retData["writer_yn"] === "Y") {
        const postWriter = $("<span class='post_writer'>작성자</span>");
        if(!this.isA) postWriter.addClass("pointBorder").addClass("pointColor");
        commentHeader.append(postWriter);
    }

    //btn modify
    if(this.isA || this.initUserId === retData["user_id"]) {
        const btnModify = $("<button type='button' class='btn_simp blue'>수정</button>");
        btnModify.attr("onclick", (this.initName !== "" ? this.initName + ".toggleModifyComment(" + retData["comment_id"] + ")" : ""));
        commentHeader.append(btnModify);
    }

    //btn delete
    if(this.isA || this.initUserId === retData["user_id"] || this.deleteYn) {
        const btnDelete = $("<button type='button' class='btn_delete'><i class=\"fa fa-times\" aria-hidden=\"true\"/></button>");
        btnDelete.attr("onclick", (this.initName !== "" ? this.initName + ".deleteComment(" + retData["comment_id"] + ")" : ""));
        commentHeader.append(btnDelete);
    }
}

COMMENT.prototype.createCommentBody = function(retData, parentEle) {
    //body
    const commentBody = $("<div class='comment_body'>");
    commentBody.attr("data-cid", retData["comment_id"]);
    parentEle.append(commentBody);

    //comment content
    const commentContent = $("<p class='comment_content'>" + retData["content_conv"] + "</p>");
    commentContent.attr("data-cid", retData["comment_id"]);
    commentBody.append(commentContent);

    //comment modify
    this.createModifyComment(retData["comment_id"]);

    //btn reply
    const btnReply = $("<button type='button' class='btn_simp'>답글</button>");
    btnReply.attr("data-cid", retData["comment_id"]);
    btnReply.attr("onclick", (this.initName !== "" ? this.initName + ".toggleReplyInput(" + retData["comment_id"] + ")" : ""));
    commentBody.append(btnReply);

    //toggle reply
    const toggleReply = $("<a class='toggle_reply'>답글(" + retData["reply_cnt"] + ")개보기</a>");
    toggleReply.attr("data-cid", retData["comment_id"]);
    toggleReply.attr("data-cnt", retData["reply_cnt"]);
    toggleReply.attr("onclick", (this.initName !== "" ? this.initName + ".toggleReply(" + retData["comment_id"] + ")" : ""));
    commentBody.append(toggleReply);

    this.addReplyList(retData["comment_id"]);
    this.createReply(retData["comment_id"], retData["user_id"]);
}

COMMENT.prototype.toggleReply = function(parentId) {
    const replyWrap = $(".reply_wrap[data-cid=" + parentId + "]");
    const toggleRep =  $(".toggle_reply[data-cid=" + parentId + "]");
    const replyInput = $(".reply_input[data-cid=" + parentId + "]");

    if(toggleRep.hasClass("on")) {
        replyWrap.hide();
        toggleRep.removeClass("on");
        toggleRep.text("답글(" + toggleRep.attr("data-cnt") + ")개보기");
        console.log(toggleRep.attr("data-cnt"));
        if(replyInput.hasClass("on")) this.toggleReplyInput(parentId);
    } else {
        replyWrap.show();
        toggleRep.addClass("on");
        toggleRep.text("답글숨기기");
    }
}

COMMENT.prototype.toggleModifyComment = function(commentId) {
    const commentInput = $(".comment_input[data-cid=" + commentId + "]");
    const commentContent = $(".comment_content[data-cid=" + commentId + "]");
    if(commentInput.hasClass("on")) {
        commentContent.show();
        commentInput.hide();
        commentInput.removeClass("on");
    } else {
        const commentTextArea = $(".comment_input[data-cid=" + commentId + "] > label > textarea");
        commentContent.hide();
        commentInput.show();
        // this.adjustTextAreaHeight(commentTextArea);
        commentTextArea.css("height", commentTextArea.prop("scrollHeight"));
        commentInput.addClass("on");
        commentTextArea.focus();
    }
}

COMMENT.prototype.createModifyComment = function(commentId) {
    //input modify
    const commentInputWrap = $("<div class='comment_input'>");
    commentInputWrap.attr("data-cid", commentId);
    const commentLabel = $("<label id='content'>");
    const commentModify = $("<textarea name='content' placeholder='댓글을 입력해주세요.'>" + this.commentList[commentId]['content'] + "</textarea>");
    commentModify.attr("onkeyup", (this.initName !== "" ? this.initName + ".adjustTextAreaHeight(this)" : ""));
    commentLabel.append(commentModify);
    const submitModify = $("<button type='button' class='bttn2'>수정</button>");
    submitModify.attr("onclick", (this.initName !== "" ? this.initName + ".modifyComment(" + commentId + ")" : ""));
    commentInputWrap.append(commentLabel);
    commentInputWrap.append(submitModify);
    $(".comment_body[data-cid=" + commentId + "]").append(commentInputWrap);
    commentInputWrap.hide();
}

COMMENT.prototype.modifyComment = function(commentId) {
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=comment_modify&module_id=" + this.moduleId, { "comment_id" : commentId, "content" : $(".comment_input[data-cid=" + commentId + "] > label > textarea[name=content]").val() }, function(ret) {
    }, 'json').then((ret) => {
        // console.log(ret);
        if (ret.error === 0) {
            this.commentList[commentId] = ret.data.rows[0];
            this.updateComment(this.commentList[commentId]);
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.updateComment = function(retData) {
    $(".comment_content[data-cid=" + retData["comment_id"] + "]").html(retData["content_conv"]);
    this.toggleModifyComment(retData["comment_id"]);
}

COMMENT.prototype.deleteComment = function(commentId) {
    if(!confirm("삭제하시겠습니까?")) return;
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=del&module_id=" + this.moduleId, { "comment_id" : commentId }, function(ret) {
    }, 'json').then((ret) => {
        if (ret.error === 0) {
            this.removeComment(commentId);
            this.updateCommentCount();
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.createReply = function(commentId, userId) {
    const replyInputWrap = $("<div class='reply_input'>");
    replyInputWrap.attr("data-cid", commentId);
    const replyLabel = $("<label id='reply'>");
    const replyContent = $("<textarea name='reply' placeholder='@" + this.commentList[commentId]["user_nm"] + " 답글을 입력해주세요.'></textarea>");
    replyContent.attr("onkeyup", (this.initName !== "" ? this.initName + ".adjustTextAreaHeight(this)" : ""));
    replyLabel.append(replyContent);
    const btnReply = $("<button type='button' class='bttn2'>등록</button>");
    btnReply.attr("onclick", (this.initName !== "" ? this.initName + ".addReply(" + commentId + ", " + userId + ")" : ""));
    if(!this.isA) btnReply.addClass("bgColor");
    replyInputWrap.append(replyLabel);
    replyInputWrap.append(btnReply);
    $(".comment_body[data-cid=" + commentId + "]").append(replyInputWrap);
    replyInputWrap.hide();
}

COMMENT.prototype.addReply = function(commentId, userId) {
    // console.log(commentId, userId);
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=reply_add&module_id=" + this.moduleId, { "parent_id" : commentId, "reply_user_id" : userId, "content" : $(".reply_input[data-cid=" + commentId + "] > label > textarea[name=reply]").val() }, function(ret) {}, 'json').then((ret) => {
        // console.log(ret);
        if (ret.error === 0) {
            const replyId = ret.data.rows[0]["comment_id"];
            if(!this.replyList[commentId]) this.replyList[commentId] = {};
            if(!this.replyList[commentId][replyId]) this.replyList[commentId][replyId] = {};
            this.replyList[commentId][replyId] = ret.data.rows[0];
            this.appendReply(this.replyList[commentId][replyId], $(".reply_wrap[data-cid=" + commentId + "]"));
            this.updateReplyCount(commentId);
            $(".reply_input[data-cid=" + commentId + "] > label > textarea[name=reply]").val("");
            this.toggleReplyInput(commentId);
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.toggleReplyInput = function(commentId) {
    const replyInput = $(".reply_input[data-cid=" + commentId + "]");
    if(replyInput.hasClass("on")) {
        replyInput.hide();
        replyInput.removeClass("on");
    } else {
        if(!$(".reply_wrap[data-cid=" + commentId + "]").hasClass("on")) this.toggleReply(commentId);
        replyInput.show();
        replyInput.addClass("on");
        $(".reply_input[data-cid=" + commentId + "] > label > textarea").focus();
    }
}

COMMENT.prototype.addReplyList = function(parentId) {
    //reply wrap
    const replyWrap = $("<div class='reply_wrap'>");
    replyWrap.attr("data-cid", parentId);
    $(".comment_body[data-cid=" + parentId + "]").append(replyWrap);

    for(let commentId in this.replyList[parentId]) {
        this.appendReply(this.replyList[parentId][commentId], replyWrap);
    }
}

COMMENT.prototype.appendReply = function(retData, replyWrap) {
    // console.log(retData);
    const parentId = retData["parent_id"];
    const commentId = retData["comment_id"];
    const userId = retData["user_id"];

    //reply box
    const replyBox = $("<div class='reply_box'>");
    replyBox.attr("data-cid", commentId);
    replyBox.attr("data-pid", parentId);
    replyBox.attr("data-uid", userId);
    replyWrap.append(replyBox);

    //reply
    const reply = $("<div class='reply'>");
    replyBox.append(reply);

    //reply header
    this.createReplyHeader(retData, reply);

    //reply body
    this.createReplyBody(retData, reply);
}

COMMENT.prototype.createReplyHeader = function(retData, parentEle) {
    const commentId = retData["comment_id"];

    //header
    const replyHeader = $("<div class='reply_header'>");
    parentEle.append(replyHeader);

    //reply user
    const replyUser = $("<span class='reply_user'>" + retData["user_nm"] + "(" + retData["login_id"] + ")" + "</span>");
    replyHeader.append(replyUser);

    //reply target user
    const replyTargetUser = $("<span class='reply_target_user'>@" + retData["reply_user_nm"] + "(" + retData["reply_user_login_id"] + ")" + "</span>");
    replyHeader.append(replyTargetUser);


    //reply date
    const replyDate = $("<span class='reply_date'>" + retData["date_conv"] + "</span>");
    replyHeader.append(replyDate);

    //post writer
    if(retData["writer_yn"] === "Y") {
        const postWriter = $("<span class='post_writer'>작성자</span>");
        if(!this.isA) postWriter.addClass("pointBorder").addClass("pointColor");
        replyHeader.append(postWriter);
    }

    //btn reply
    const btnReply = $("<button type='button' class='btn_simp'>답글</button>");
    btnReply.attr("data-cid", commentId);
    btnReply.attr("onclick", (this.initName !== "" ? this.initName + ".toggleReply2(" + commentId + ")" : ""));
    replyHeader.append(btnReply);

    //btn modify
    if(this.isA || this.initUserId === retData["user_id"]) {
        const btnModify = $("<button type='button' class='btn_simp blue'>수정</button>");
        btnModify.attr("onclick", (this.initName !== "" ? this.initName + ".toggleModifyReply(" + commentId + ")" : ""));
        replyHeader.append(btnModify);
    }

    //btn delete
    if(this.isA || this.initUserId === retData["user_id"] || this.deleteYn) {
        const btnDelete = $("<button type='button' class='btn_delete'><i class=\"fa fa-times\" aria-hidden=\"true\"/></button>");
        btnDelete.attr("onclick", (this.initName !== "" ? this.initName + ".deleteReply(" + commentId + ")" : ""));
        replyHeader.append(btnDelete);
    }
}

COMMENT.prototype.createReplyBody = function(retData, parentEle) {
    const parentId = retData["parent_id"];
    const commentId = retData["comment_id"];

    //body
    const replyBody = $("<div class='reply_body'>");
    replyBody.attr("data-cid", commentId);
    parentEle.append(replyBody);

    //reply content
    const replyContent = $("<p class='reply_content'>" + retData["content_conv"] + "</p>");
    replyContent.attr("data-cid", commentId);
    replyBody.append(replyContent);

    //reply modify
    this.createModifyReply(parentId, commentId);

    this.createReply2(retData);
}

COMMENT.prototype.createReply2 = function(retData) {
    const replyId = retData["comment_id"];

    const replyInputWrap = $("<div class='reply_input'>");
    replyInputWrap.attr("data-cid", replyId);
    const replyLabel = $("<label id='reply'>");
    const replyContent = $("<textarea name='reply' placeholder='@" + retData["user_nm"] + " 답글을 입력해주세요.'></textarea>");
    replyContent.attr("onkeyup", (this.initName !== "" ? this.initName + ".adjustTextAreaHeight(this)" : ""));
    replyLabel.append(replyContent);
    const btnReply = $("<button type='button' class='bttn2'>등록</button>");
    btnReply.attr("onclick", (this.initName !== "" ? this.initName + ".addReply2(" + retData["parent_id"] + ", " + retData["comment_id"] + "," + retData["user_id"] + ")" : ""));
    replyInputWrap.append(replyLabel);
    replyInputWrap.append(btnReply);
    $(".reply_body[data-cid=" + replyId + "]").append(replyInputWrap);
    replyInputWrap.hide();
}

COMMENT.prototype.addReply2 = function(parentId, commentId, userId) {

    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=reply_add&module_id=" + this.moduleId, { "parent_id" : parentId, "reply_user_id" : userId, "content" : $(".reply_input[data-cid=" + commentId + "] > label > textarea[name=reply]").val() }, function(ret) {}, 'json').then((ret) => {
        // console.log(ret);
        if (ret.error === 0) {
            const replyId = ret.data.rows[0]['comment_id'];
            if(!this.replyList[parentId]) this.replyList[parentId] = {};
            if(!this.replyList[parentId][replyId]) this.replyList[parentId][replyId] = {};
            this.replyList[parentId][replyId] = ret.data.rows[0];
            // console.log(this.replyList[parentId][replyId]);
            this.appendReply(this.replyList[parentId][replyId], $(".reply_wrap[data-cid=" + parentId + "]"));
            this.updateReplyCount(parentId);
            $(".reply_input[data-cid=" + commentId + "] > label > textarea[name=reply]").val("");
            this.toggleReply2(commentId);
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.toggleReply2 = function(replyId) {
    const replyInputWrap = $(".reply_input[data-cid=" + replyId + "]");
    const btnReply = $(".reply_header > button[data-cid=" + replyId + "]");
    if(btnReply.hasClass("on")) {
        replyInputWrap.hide();
        btnReply.removeClass("on");
    } else {
        replyInputWrap.show();
        btnReply.addClass("on");
    }

}

COMMENT.prototype.toggleModifyReply = function(replyId) {
    const replyInput = $(".reply_input[data-mid=" + replyId + "]");
    const replyContent = $(".reply_content[data-cid=" + replyId + "]");
    if(replyInput.hasClass("on")) {
        replyContent.show();
        replyInput.hide();
        replyInput.removeClass("on");
    } else {
        const replyTextArea = $(".reply_input[data-mid=" + replyId + "] > label > textarea");
        replyContent.hide();
        replyInput.show();
        // this.adjustTextAreaHeight(replyTextArea);
        replyTextArea.css("height", replyTextArea.prop("scrollHeight"));
        replyInput.addClass("on");
        replyTextArea.focus();
    }
}

COMMENT.prototype.createModifyReply = function(parentId, replyId) {
    //reply modify
    const replyInputWrap = $("<div class='reply_input'>");
    replyInputWrap.attr("data-mid", replyId);
    const replyLabel = $("<label id='reply_modify'>");
    const replyModify = $("<textarea name='reply_modify' placeholder='@" + this.replyList[parentId][replyId]["reply_user_nm"] + " 답글을 입력해주세요.'>" + this.replyList[parentId][replyId]['content'] + "</textarea>");
    replyModify.attr("onkeyup", (this.initName !== "" ? this.initName + ".adjustTextAreaHeight(this)" : ""));
    replyLabel.append(replyModify);
    const submitModify = $("<button type='button' class='bttn2'>수정</button>");
    submitModify.attr("onclick", (this.initName !== "" ? this.initName + ".modifyReply(" + parentId + ", " + replyId + ")" : ""));
    replyInputWrap.append(replyLabel);
    replyInputWrap.append(submitModify);
    $(".reply_body[data-cid=" + replyId + "]").append(replyInputWrap);
    replyInputWrap.hide();
}

COMMENT.prototype.modifyReply = function(parentId, replyId) {
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=comment_modify&module_id=" + this.moduleId, { "comment_id" : replyId, "content" : $(".reply_input[data-mid=" + replyId + "] > label > textarea[name=reply_modify]").val() }, function(ret) {
    }, 'json').then((ret) => {
        // console.log(ret);
        if (ret.error === 0) {
            this.replyList[parentId][replyId] = ret.data.rows[0];
            this.updateReply(this.replyList[parentId][replyId]);
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.updateReply = function(retData) {
    $(".reply_content[data-cid=" + retData["comment_id"] + "]").html(retData["content_conv"]);
    this.toggleModifyReply(retData["comment_id"]);
}

COMMENT.prototype.deleteReply = function(replyId) {
    if(!confirm("삭제하시겠습니까?")) return;
    $.post("../comment/call_" + this.callModule + ".jsp?module=" + this.module + "&mode=del&module_id=" + this.moduleId, { "comment_id" : replyId }, function(ret) {
    }, 'json').then((ret) => {
        if (ret.error === 0) {
            const parentId = $(".reply_box[data-cid=" + replyId + "]").attr("data-pid");
            this.removeReply(replyId);
            this.updateReplyCount(parentId);
        } else {
            alert(ret.message);
        }
    });
}

COMMENT.prototype.removeReply = function(commentId) {
    $(".reply_box[data-cid=" + commentId + "]").remove();
}

COMMENT.prototype.updateReplyCount = function(parentId) {
    const toggleReply = $(".toggle_reply[data-cid=" + parentId + "]");
    toggleReply.attr("data-cnt", $(".reply_box[data-pid=" + parentId + "]").length);

    if(!toggleReply.hasClass("on")) toggleReply.text("답글(" + toggleReply.attr("data-cnt") + ")개보기");
}

COMMENT.prototype.updateCommentCount = function() {
    $("#comment_cnt").text($(".comment_box").length);
}

COMMENT.prototype.removeComment = function(commentId) {
    $(".comment_box[data-cid=" + commentId + "]").remove();
}