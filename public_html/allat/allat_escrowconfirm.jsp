<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %>
<!-- 올앳관련 함수 Import //-->
<%@ page import="java.util.*,java.net.*,com.allat.util.AllatUtil" %>

<%
  //Request Value Define
  //----------------------

  
  // Service Code
  String sCrossKey = siteinfo.s("pg_key"); //설정필요
  String sShopId   = siteinfo.s("pg_id");   //설정필요
  String sEncData  = request.getParameter("allat_enc_data");
  String strReq = "";

  // 요청 데이터 설정
  //----------------------
  strReq = "allat_shop_id="   +sShopId;
  strReq +="&allat_enc_data=" +sEncData;
  strReq +="&allat_cross_key="+sCrossKey;

  // 올앳 결제 서버와 통신  : AllatUtil.escrowchkReq->통신함수, HashMap->결과값
  //-----------------------------------------------------------------------------
  AllatUtil util = new AllatUtil();
  HashMap hm     = null;
  hm = util.escrowConfirmReq(strReq, "SSL");

  // 결제 결과 값 확인
  //------------------
  String sReplyCd      = (String)hm.get("reply_cd");
  String sReplyMsg     = (String)hm.get("reply_msg");

  /* 결과값 처리
  --------------------------------------------------------------------------
     결과 값이 '0000'이면 정상임. 단, allat_test_yn=Y 일경우 '0001'이 정상임.
     실제 결제   : allat_test_yn=N 일 경우 reply_cd=0000 이면 정상
     테스트 결제 : allat_test_yn=Y 일 경우 reply_cd=0001 이면 정상
  --------------------------------------------------------------------------*/
  if( sReplyCd.equals("0000") ){
    // reply_cd "0000" 일때만 성공
	String sEsConfirmYn = (String)hm.get("es_confirm_yn");
	String sEsReject    = (String)hm.get("es_reject");

    out.println("결과코드    : " + Malgn.htt(sReplyCd)      + "<br>");
    out.println("결과메세지   : " + Malgn.htt(sReplyMsg)    + "<br>");
    out.println("구매결정    : " + Malgn.htt(sEsConfirmYn) + "<br>");
    out.println("구매거부사유 : " + Malgn.htt(sEsReject)   + "<br>");
  }else{
    // reply_cd 가 "0000" 아닐때는 에러 (자세한 내용은 매뉴얼참조)
    // reply_msg 가 실패에 대한 메세지
    out.println("결과코드   : " + Malgn.htt(sReplyCd)    + "<br>");
    out.println("결과메세지 : " + Malgn.htt(sReplyMsg)   + "<br>");
  }

%>
