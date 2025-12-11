<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
boolean afterLog = "log".equals(m.rs("after"));

//접근권한
if(!afterLog && !Menu.accessible(113, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
UserOutDao userOut = new UserOutDao();
UserSleepDao userSleep = new UserSleepDao();

SiteDao site = new SiteDao();

MailDao mail = new MailDao();

//변수
DataSet slist = new DataSet();
String now = m.time("yyyyMMddHHmmss");
String whereMail     = "status =  1 AND conn_date  <= '" + m.addDate("D", (-365 + 30), now, "yyyyMMdd000000") + "' AND user_kind = 'U' AND site_id = ";
String whereSleep    = "status = 30 AND conn_date  <= '" + m.addDate("D",        -365, now, "yyyyMMdd000000") + "' AND user_kind = 'U' AND site_id = ";
String whereOut      = "status = 31 AND sleep_date <= '" + m.addDate("D",        -365, now, "yyyyMMdd000000") + "' AND user_kind = 'U' AND site_id = ";
String whereOutSleep = "status = 30 AND sleep_date <= '" + m.addDate("D",        -365, now, "yyyyMMdd000000") + "' AND user_kind = 'U' AND site_id = ";

//목록-사이트
if("all".equals(m.rs("site"))) slist = site.find("id IN (1, 3)"); //전체사이트조건
else slist = site.find("id = " + siteId + " AND status = 1"); //접속사이트

//등록
if("sleep".equals(m.rs("mode"))) {
	while(slist.next()) {
		if(afterLog) out.println("[" + m.time("yyyy.MM.dd HH:mm:ss") + " " + slist.s("site_nm") + " 사이트 휴면처리 시작]");

		//목록
		DataSet mailList = user.find(whereMail + slist.s("id")); //정상=>휴면대상
		DataSet sleepList = user.find(whereSleep + slist.s("id")); //휴면대상=>휴면
		DataSet outList = user.find(whereOut + slist.s("id")); //휴면=>탈퇴

		//변수
		boolean errorMail = false;
		boolean errorSleep = false;
		boolean errorOut = false;

		int countMail = 0;
		int countSleepInsert = 0;
		int countSleepModify = 0;
		int countOutInsert = 0;
		int countOutStatus = 0;
		int countOutDelete = 0;

		//정상=>휴면대상
		while(mailList.next()) {
			//회원정보수정
			user.item("status", "30");
			if(user.update(whereMail + slist.s("id"))) {
				countMail++;

				//메일
				p.setVar("sleep_date", m.addDate("D", 365, mailList.s("conn_date"), "yyyy년 MM월 dd일"));
				mail.send(siteinfo, mailList, "sleep_pre", p);

				/*
				if(mail.isMail(mailList.s("email"))) {
					if("".equals(mailList.s("conn_date"))) mailList.put("conn_date", mailList.s("reg_date"));
					
					if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
					String msender = siteinfo.s("site_email");
					String msubject = "휴면계정 시행에 대한 사전 안내";
					String sleepDate = m.addDate("D", 365, mailList.s("conn_date"), "yyyy년 MM월 dd일");

					m.mailFrom = msender;
					p.setRoot(siteinfo.s("doc_root") + "/html");
					p.setLayout("mail");
					p.setBody("mail.sleep_pre");
					p.setVar("sleep_date", sleepDate);
					String mbody = p.fetchAll();

					//발송
					//m.mail(mailList.s("email"), "[" + siteinfo.s("site_nm") + "] " + msubject, mbody);
					//m.mail("chhwi@malgnsoft.com", "[" + siteinfo.s("site_nm") + "] " + msubject, mbody);
				}
				*/
			}
		}

		if(0 >= countMail && 0 < mailList.size()) {
			if(afterLog) out.println("휴면대상으로 전환하는 중 오류가 발생했습니다.");
			else m.jsAlert("휴면대상으로 전환하는 중 오류가 발생했습니다.");
			errorMail = true;
		}

		//휴면대상=>휴면
		if(0 < sleepList.size()) {
			//휴면정보등록
			countSleepInsert = userSleep.execute("INSERT INTO " + userSleep.table + " SELECT * FROM " + user.table + " WHERE " + whereSleep + slist.s("id"));
			if(0 >= countSleepInsert) {
				if(afterLog) out.println("휴면정보를 등록하는 중 오류가 발생했습니다.");
				else m.jsAlert("휴면정보를 등록하는 중 오류가 발생했습니다.>");
				errorSleep = true;
			}

			//회원정보수정
			if(!errorSleep) countSleepModify = user.execute(
				" UPDATE " + user.table + " SET dept_id = 0, passwd = '', email = '', zipcode = '', addr = '', new_addr = '', addr_dtl = '' "
				+ " , gender = '', birthday = '', mobile = '', needs = '', etc1 = '', etc2 = '', etc3 = '', etc4 = '', etc5 = '' "
				+ " , sleep_date = '" + now + "', status = 31 WHERE " + whereSleep + slist.s("id")
			);
			if(!errorSleep && 0 >= countSleepModify) {
				if(afterLog) out.println("휴면상태로 전환하는 중 오류가 발생했습니다.");
				else m.jsAlert("휴면상태로 전환하는 중 오류가 발생했습니다.");
				errorSleep = true;
			}
		}

		//휴면=>탈퇴
		if(0 < outList.size()) {
			//탈퇴정보등록
			countOutInsert = userOut.execute(
				" INSERT INTO " + userOut.table + " SELECT "
				+ " id user_id, 'H5' out_type, '휴면계정 전환 후 1년 미접속자 자동탈퇴' memo, 0 admin_id, "
				+ " '" + now + "' out_date, '" + now + "' reg_date, 1 status "
				+ " FROM " + user.table + " WHERE " + whereOut + slist.s("id")
			);
			if(0 >= countOutInsert) { 
				if(afterLog) out.println("탈퇴정보를 등록하는 중 오류가 발생했습니다.");
				else m.jsAlert("탈퇴정보를 등록하는 중 오류가 발생했습니다.");
				errorOut = true;
			}

			//탈퇴상태전환
			if(!errorOut) countOutStatus = user.execute("UPDATE " + user.table + " SET status = -1 WHERE " + whereOut + slist.s("id"));
			if(!errorOut && 0 >= countOutStatus) {
				if(afterLog) out.println("탈퇴상태로 전환하는 중 오류가 발생했습니다.");
				else m.jsAlert("탈퇴상태로 전환하는 중 오류가 발생했습니다.");
				errorOut = true;
			}

			//휴면삭제
			if(!errorOut) countOutDelete = userSleep.findCount(whereOutSleep + slist.s("id"));
			if(!errorOut && !userSleep.delete(whereOutSleep + slist.s("id"))) {
				if(afterLog) out.println("휴면정보를 삭제하는 중 오류가 발생했습니다.");
				else m.jsAlert("휴면정보를 삭제하는 중 오류가 발생했습니다.");
				countOutDelete = 0;
				errorOut = true;
			}
		}

		//이동
		if(afterLog) {
			out.println("[1. 정상=>휴면대상] 상태전환 : " + m.nf(countMail));
			out.println("[2. 휴면대상=>휴면] 휴면정보등록 : " + m.nf(countSleepInsert) + " / 휴면상태전환 : " + m.nf(countSleepModify));
			out.println("[3. 휴면=>탈퇴] 탈퇴정보등록 : " + m.nf(countOutInsert) + " / 탈퇴상태전환 : " + m.nf(countOutStatus) + " / 휴면정보삭제 : " + m.nf(countOutDelete));
			out.println("[" + m.time("yyyy.MM.dd HH:mm:ss") + " " + slist.s("site_nm") + " 사이트 휴면처리 완료]");
			out.println("");
		} else {
			m.jsAlert("휴면처리가 완료되었습니다.");
			m.jsReplace("../user/sleep_list.jsp?" + m.qs("mode,after"), "parent");
		}
	}
	return;
}

//출력
p.setBody("user.sleep_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("mail_count", m.nf(user.findCount(whereMail + siteId))); //정상=>휴면대상
p.setVar("sleep_count", m.nf(user.findCount(whereSleep + siteId))); //휴면대상=>휴면
p.setVar("out_count", m.nf(user.findCount(whereOut + siteId))); //휴면=>탈퇴

p.display();

%>