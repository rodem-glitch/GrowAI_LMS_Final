var links = { 
	//소개
	"/main/page.jsp?code=greeting" : { GNB : "gnb_intro" , LNB : "lnb_greeting" }
	, "/main/page.jsp?code=location" : { GNB : "gnb_intro" , LNB : "lnb_location" }
	
	//수강신청
	, "/course/course_list.jsp" : { GNB : "gnb_course" , LNB : "LNB_COURSE" }
	, "/course/course_view.jsp" : { GNB : "gnb_course" , LNB : "LNB_COURSE" }
	, "/course/freepass_list.jsp" : { GNB : "gnb_course" , LNB : "LNB_FREEPASS" }
	, "/course/freepass_view.jsp" : { GNB : "gnb_course" , LNB : "LNB_FREEPASS" }
	, "/main/page.jsp?code=course.course_step" : { GNB : "gnb_course" , LNB : "LNB_PROCESS" }
	
	//수강신청
	, "/webtv/webtv_list.jsp" : { GNB : "GNB_WEBTV" , LNB : "LNB_WEBTV" }
	, "/webtv/webtv_view.jsp" : { GNB : "GNB_WEBTV" , LNB : "LNB_WEBTV" }

	, "/tutor/tutor_list.jsp" : { GNB : "gnb_intro" , LNB : "lnb_teacher" }
	, "/tutor/tutor_view.jsp" : { GNB : "gnb_intro" , LNB : "lnb_teacher" }

	
	//고객센터
	, "/board/index.jsp?code=notice" : { GNB : "gnb_board" , LNB : "lnb_notice" } //공지사항
	, "/board/read.jsp?code=notice" : { GNB : "gnb_board" , LNB : "lnb_notice" }
	, "/board/index.jsp?code=pds" : { GNB : "gnb_board" , LNB : "lnb_pds" } //자료실
	, "/board/read.jsp?code=pds" : { GNB : "gnb_board" , LNB : "lnb_pds" }
	, "/board/index.jsp?code=qna" : { GNB : "gnb_board" , LNB : "lnb_qna" } //QNA
	, "/board/read.jsp?code=qna" : { GNB : "gnb_board" , LNB : "lnb_qna" }
	, "/board/write.jsp?code=qna" : { GNB : "gnb_board" , LNB : "lnb_qna" }
	, "/board/modify.jsp?code=qna" : { GNB : "gnb_board" , LNB : "lnb_qna" }
	, "/board/index.jsp?code=faq" : { GNB : "gnb_board" , LNB : "lnb_faq" } //FAQ


	
	, "/board/index.jsp?code=privacy1" : { GNB : "gnb_priv" , LNB : "lnb_privacy1" } //privacy1
	, "/board/read.jsp?code=privacy1" : { GNB : "gnb_priv" , LNB : "lnb_privacy1" }
	, "/board/write.jsp?code=privacy1" : { GNB : "gnb_priv" , LNB : "lnb_privacy1" }
	, "/board/modify.jsp?code=privacy1" : { GNB : "gnb_priv" , LNB : "lnb_privacy1" }

	, "/board/index.jsp?code=privacy2" : { GNB : "gnb_priv" , LNB : "lnb_privacy2" } //privacy2
	, "/board/read.jsp?code=privacy2" : { GNB : "gnb_priv" , LNB : "lnb_privacy2" }
	, "/board/write.jsp?code=privacy2" : { GNB : "gnb_priv" , LNB : "lnb_privacy2" }
	, "/board/modify.jsp?code=privacy2" : { GNB : "gnb_priv" , LNB : "lnb_privacy2" }
	
	, "/board/index.jsp?code=privacy3" : { GNB : "gnb_priv" , LNB : "lnb_privacy3" } //privacy3
	, "/board/read.jsp?code=privacy3" : { GNB : "gnb_priv" , LNB : "lnb_privacy3" }
	, "/board/write.jsp?code=privacy3" : { GNB : "gnb_priv" , LNB : "lnb_privacy3" }
	, "/board/modify.jsp?code=privacy3" : { GNB : "gnb_priv" , LNB : "lnb_privacy3" }

	
	, "/board/index.jsp?code=errata" : { GNB : "gnb_book" , LNB : "lnb_errata" } //정오표
	, "/board/read.jsp?code=errata" : { GNB : "gnb_book" , LNB : "lnb_errata" }
	, "/board/write.jsp?code=errata" : { GNB : "gnb_book" , LNB : "lnb_errata" }
	, "/board/modify.jsp?code=errata" : { GNB : "gnb_book" , LNB : "lnb_errata" }


	, "/course/review_list.jsp" : { GNB : "gnb_board" , LNB : "lnb_review" } //수강후기
	, "/course/review_view.jsp" : { GNB : "gnb_board" , LNB : "lnb_review" }
	, "/course/review_insert.jsp" : { GNB : "gnb_board" , LNB : "lnb_review" }
	, "/main/formmail.jsp" : { GNB : "gnb_board" , LNB : "lnb_formmail" } // 이메일문의
	
	, "/board/index.jsp?code=event" : { GNB : "gnb_board" , LNB : "lnb_event" } //event
	, "/board/read.jsp?code=event" : { GNB : "gnb_board" , LNB : "lnb_event" }
	
	
	//마이페이지
	, "/mypage/index.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_myindex" }
	, "/mypage/course_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_mycourse" }
	, "/mypage/book_list.jsp" : { GNB : "gnb_mypage" , LNB : "LNB_BOOK" }
	, "/mypage/certificate_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_certificate" }
	, "/order/cart_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_cart" }

	, "/mypage/order_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_myorder" }
	, "/mypage/order_view.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_myorder" }
	, "/mypage/coupon_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_coupon" }
	, "/mypage/freepass_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_free" }
	, "/mypage/message_list.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_message" }
	, "/mypage/message_view.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_message" }
	, "/mypage/modify2.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_profile" }
	, "/mypage/modify.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_profile" }
	, "/mypage/modify_verify.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_profile" }
	, "/mypage/modify_passwd.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_profile" }
	, "/mypage/out.jsp" : { GNB : "gnb_mypage" , LNB : "lnb_profile" }
	
	//강의실
	, "/classroom/index.jsp" : { GNB : "" , LNB : "LNB_MAIN" }
	, "/classroom/course_info.jsp" : { GNB : "" , LNB : "LNB_COURSE" }
	, "/classroom/cpost_list.jsp?code=notice" : { GNB : "" , LNB : "LNB_NOTICE" } //공지사항
	, "/classroom/cpost_view.jsp?code=notice" : { GNB : "" , LNB : "LNB_NOTICE" }
	, "/classroom/curriculum.jsp" : { GNB : "" , LNB : "LNB_CURRI" }

	, "/classroom/exam.jsp" : { GNB : "" , LNB : "LNB_EXAM" }
	, "/classroom/exam_view.jsp" : { GNB : "" , LNB : "LNB_EXAM" }

	, "/classroom/homework.jsp" : { GNB : "" , LNB : "LNB_HOMEWORK" }
	, "/classroom/homework_view.jsp" : { GNB : "" , LNB : "LNB_HOMEWORK" }

	, "/classroom/forum.jsp" : { GNB : "" , LNB : "LNB_FORUM" }
	, "/classroom/forum_view.jsp" : { GNB : "" , LNB : "LNB_FORUM" }
	, "/classroom/forum_read.jsp" : { GNB : "" , LNB : "LNB_FORUM" }

	, "/classroom/survey.jsp" : { GNB : "" , LNB : "LNB_SURVEY" }
	, "/classroom/survey_view.jsp" : { GNB : "" , LNB : "LNB_SURVEY" }

	, "/classroom/library.jsp" : { GNB : "" , LNB : "LNB_LIBRARY" }
	, "/classroom/library_view.jsp" : { GNB : "" , LNB : "LNB_LIBRARY" }

	, "/classroom/cpost_list.jsp?code=qna" : { GNB : "" , LNB : "LNB_QNA" } //QNA
	, "/classroom/cpost_insert.jsp?code=qna" : { GNB : "" , LNB : "LNB_QNA" }
	, "/classroom/cpost_modify.jsp?code=qna" : { GNB : "" , LNB : "LNB_QNA" }
	, "/classroom/cpost_view.jsp?code=qna" : { GNB : "" , LNB : "LNB_QNA" }
	
	, "/classroom/cpost_list.jsp?code=review" : { GNB : "" , LNB : "LNB_REVIEW" } //수강후기
	, "/classroom/cpost_insert.jsp?code=review" : { GNB : "" , LNB : "LNB_REVIEW" }
	, "/classroom/cpost_modify.jsp?code=review" : { GNB : "" , LNB : "LNB_REVIEW" }
	, "/classroom/cpost_view.jsp?code=review" : { GNB : "" , LNB : "LNB_REVIEW" }

	//회원서비스
	, "/member/login.jsp" : { GNB : "" , LNB : "lnb_login" }
	, "/member/agreement.jsp" : { GNB : "" , LNB : "lnb_join" }
	, "/member/join.jsp" : { GNB : "" , LNB : "lnb_join" }
	, "/member/join_success.jsp" : { GNB : "" , LNB : "lnb_join" }
	, "/member/find.jsp" : { GNB : "" , LNB : "lnb_findpw" }
	, "/main/page.jsp?code=privacy" : { GNB : "" , LNB : "lnb_privacy" }
	, "/main/page.jsp?code=clause" : { GNB : "" , LNB : "lnb_terms" }
	, "/main/page.jsp?code=refund" : { GNB : "" , LNB : "lnb_refund" }
	, "/main/page.jsp?code=member.notemail" : { GNB : "" , LNB : "LNB_EMAIL" }

};


var modules = { 
	"/main/page.jsp" : "code"
	, "/board/index.jsp" : "code" 
	, "/board/read.jsp" : "code" 
	, "/board/write.jsp" : "code" 
	, "/board/modify.jsp" : "code" 
	, "/classroom/cpost_list.jsp" : "code" 
	, "/classroom/cpost_insert.jsp" : "code" 
	, "/classroom/cpost_modify.jsp" : "code" 
	, "/classroom/cpost_view.jsp" : "code" 
}; 

$(document).ready(function() {
	var currUrl = decodeURIComponent(location.href);
	var currDomain = document.domain;
	var currPath = currUrl.replace("http://" + currDomain, "").replace("https://" + currDomain, "").replace(location.hash, "");
	
	var query = currUrl.slice(currUrl.indexOf('?') + 1, currUrl.length).replace(location.hash, "");
	var path = currPath.replace("?" + query, "");
	
	try {
		if(path in modules) {
			var parameters = query.split('&');
			for(var i = 0 ; i < parameters.length ; i++) {
				var key = parameters[i].split('=')[0];
				if(key.toLowerCase() == modules[path]) {
					value = parameters[i].split('=')[1];
					path += "?" + key + "=" + value;
					break;
				}
			}
		}

		var gnb = links[path].GNB ? links[path].GNB : "" ;
		var lnb = links[path].LNB ? links[path].LNB : "" ;

		if(gnb) {
			var classNameGnb = document.getElementById(gnb).className;
			document.getElementById(gnb).className = classNameGnb + " on";
		}
		if(lnb) {
			var classNameLnb = document.getElementById(lnb).className;
			document.getElementById(lnb).className = classNameLnb + " on";
		}

	} catch(e) { }
	
});