package dao;

import java.io.IOException;

import malgnsoft.util.*;
import malgnsoft.db.*;

import com.daou.BizRecv;
import com.daou.BizSend;
import com.daou.entity.ReportMsgEntity;
import com.daou.entity.SendMsgEntity;

public class BizSMS extends DataObject {
	private String userId = "";
	private String userPw = "";

	private String server = "biz.ppurio.com";
	private int sendPort = 18100;
	private int recvPort = 18200;
	private boolean useSsl = true;

	private int siteId = 0;

	public BizSMS() {
		this.table = "TB_UDS_LOG";
		this.PK = "cmid";
	}

	public BizSMS(String userId, String userPw) {
		this.table = "TB_UDS_LOG";
		this.PK = "cmid";
		this.setAccount(userId, userPw);
	}

	public void setAccount(String userId, String userPw) {
		this.userId = userId;
		this.userPw = userPw;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public void setServer(String server) {
		this.server = server;
	}

	public void setPort(int sendPort, int recvPort, boolean useSsl) {
		this.sendPort = sendPort;
		this.recvPort = recvPort;
		this.useSsl = useSsl;
	}

	public boolean send(String to, String from, String message) throws Exception {
		return this.send(to, from, message, "", "");
	}

	public boolean send(String to, String from, String message, String date) throws Exception {
		return this.send(to, from, message, date, "");
	}

	public boolean send(String to, String from, String message, String date, String title) throws Exception {
		if(0 == siteId) return false;
		if("".equals(userId) || "".equals(userPw) || "".equals(to) || "".equals(from) || "".equals(message)) return false;
		if(userId == null || userPw == null || to == null || from == null || message == null) return false;

		//객체
		BizSend bs = new BizSend();
		
		//변수
		SendMsgEntity sme = null;

		boolean msgEnryptOpt = false;
		boolean fileEncryptOpt = false;
		boolean fileDeleteOpt = false;

		int messageType = message.getBytes("KSC5601").length > 80 ? 5 : 0;

		String newCmid = (System.nanoTime() / 1000) + "";
		String subject = 5 == messageType ? Malgn.cutString(message, 40, "") : "";
		String now = Malgn.time("yyyyMMddHHmmss");
		String sendTime = (date == null || "".equals(date)) ? now : Malgn.time("yyyyMMddHHmmss", date);
		String sendTimeUnix = Malgn.getUnixTime(sendTime) + "";

		//저장
		this.item("cmid", newCmid);
		this.item("msg_type", messageType);
		this.item("status", 0); //대기 0, 발송 중 1, 발송 완료 2, 에러 3
		this.item("request_time", now);
		this.item("send_time", sendTime);
		this.item("dest_phone", to);
		this.item("send_phone", from);
		this.item("subject", !"".equals(title) ? title : subject);
		this.item("msg_body", message);
		this.item("site_id", siteId);
		if(!this.insert()) return false;
	
		//SMS서버연결
		bs.setLogEnabled(false); //Console에서 로그를 확인할 경우 설정
		bs.doBegin(server, sendPort, userId, userPw, useSsl);
		
		sme = new SendMsgEntity();
		sme.setCMID(newCmid);
		sme.setMSG_TYPE(messageType);
		sme.setSEND_TIME(sendTimeUnix);
		sme.setDEST_PHONE(to);
		sme.setSEND_PHONE(from);
		sme.setSUBJECT(subject);
		sme.setMSG_BODY(message);

		try {
			this.item("umid", bs.sendMsg(sme, msgEnryptOpt, fileEncryptOpt, fileDeleteOpt));
		} catch (IOException ioe) {
			this.item("IOException", ioe.getMessage());
		} catch (Exception ex) {
			this.item("exception", ex.getMessage());
		}

		bs.doEnd();

		return this.update("cmid = '" + newCmid + "'");
	}

}