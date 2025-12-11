<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>New All@Pay 주문정보 입력</title>
<style><!--
body { font-family:굴림체; font-size:12px; }
td   { font-family:굴림체; font-size:12px; }
.title { font-family:굴림체; font-size:16px; }
.head { background-color:#EFF7FC; padding: 3 3 0 5 }
.body { background-color:#FFFFFF; padding: 3 3 0 5  }
.nbody { background-color:#FFFFCC; padding: 3 3 0 5  }
//--></style>
<script language=JavaScript charset='euc-kr' src="https://tx.allatpay.com/common/NonAllatPayRE.js"></script>
<script language=Javascript>
	// 결제페이지 호출
	function ftn_approval(dfm) {
		AllatPay_Approval(dfm);
		// 결제창 자동종료 체크 시작
		AllatPay_Closechk_Start();
	}

	// 결과값 반환( receive 페이지에서 호출 )
	function result_submit(result_cd,result_msg,enc_data) {

		// 결제창 자동종료 체크 종료
		AllatPay_Closechk_End();

		if( result_cd != '0000' ){
			window.setTimeout(function(){alert(result_cd + " : " + result_msg);},1000);
		} else {
			fm.allat_enc_data.value = enc_data;

			fm.action = "allat_approval.jsp";
			fm.method = "post";
			fm.target = "_self";
			fm.submit();
		}
	}
</script>
</head>
<body>

    <p align=center class=title><u>New All@Pay™ 승인요청 예제페이지</u></p>

    <!------------- HTML : Form 설정 --------------//-->
    <form name="fm"  method=POST action="allat_approval.jsp"> <!--승인요청 및 결과수신페이지 지정 //-->

    <table border=0 cellpadding=0 cellspacing=1 bgcolor="#606060" width=1152 align=center style="TABLE-LAYOUT: fixed;">
    <font color=red>◆ 필수정보 : <b>결제 필수 항목</b></font>
    &nbsp;&nbsp;&nbsp;&nbsp<a target=_new href="https://www.allatpay.com/servlet/AllatBizV2/support/SupportFaqCL?menu_id=m040201"><b>[FAQ]</b></a>
    <tr>
        <td width="140" class="head">항목</td>
        <td width="160" class="body">예시 값</td>
        <td width="70"  class="body">&nbsp최대길이<br>(영문기준)</td>
        <td width="140"  class="body">변수명</td>
        <td class="body">변수 설명</td>
    </tr>
    <tr>
        <td class="head">상점 ID</td>
        <td class="body"><input type=text name="allat_shop_id" value="<%=siteinfo.s("pg_id")%>" size="19" maxlength=20></td>
        <td class="body">20</td>
        <td class="body">allat_shop_id</td>
        <td class="body">Allat에서 발급한 고유 상점 ID/td>
    </tr>
    <tr>
        <td class="head">주문번호</td>
        <td class="body"><input type=text name="allat_order_no" value="<%=m.time("yyyyMMddHHmmss")%>" size="19" maxlength=70></td>
        <td class="body">70</td>
        <td class="body">allat_order_no</td>
        <td class="body">쇼핑몰에서 사용하는 고유 주문번호 : 공백,작은따옴표('),큰따옴표(") 사용 불가</td>
    </tr>
    <tr>
        <td class="head">승인금액</td>
        <td class="body"><input type=text name="allat_amt" value="1000" size="19" maxlength=10></td>
        <td class="body">10</td>
        <td class="body">allat_amt</td>
        <td class="body">총 결제금액 : 숫자(0~9)만 사용가능</td>
    </tr>
    <tr>
        <td class="head">회원ID</td>
        <td class="body"><input type=text name="allat_pmember_id" value="malgn" size="19" maxlength=20></td>
        <td class="body">20</td>
        <td class="body">allat_pmember_id</td>
        <td class="body">쇼핑몰의 회원ID : 공백,작은따옴표('),큰따옴표(") 사용 불가</td>
    </tr>
    <tr>
        <td class="head">상품코드</td>
        <td class="body"><input type=text name="allat_product_cd" value="md01||md02" size="19" maxlength=1000></td>
        <td class="body">1000</td>
        <td class="body">allat_product_cd</td>
        <td class="body">여러 상품의 경우 구분자 이용, 구분자('||':파이프 2개) : 공백,작은따옴표('),큰따옴표(") 사용 불가</td>
    </tr>
    <tr>
        <td class="head">상품명</td>
        <td class="body"><input type=text name="allat_product_nm" value="테스트 상품1||테스트 상품 두번째!" size="19" maxlength=1000></td>
        <td class="body">1000</td>
        <td class="body">allat_product_nm</td>
        <td class="body">여러 상품의 경우 구분자 이용, 구분자('||':파이프 2개)</td>
    </tr>
    <tr>
        <td class="head">결제자성명</td>
        <td class="body"><input type=text name="allat_buyer_nm" value="개발자" size="19" maxlength=20></td>
        <td class="body">20</td>
        <td class="body">allat_buyer_nm</td>        
        <td class="body"></td>
    </tr>
    <tr>
        <td class="head">수취인성명</td>
        <td class="body"><input type=text name="allat_recp_nm" value="개발자" size="19" maxlength=20></td>
        <td class="body">20</td>
        <td class="body">allat_recp_nm</td>        
        <td class="body"></td>
    </tr>
    <tr>
        <td class="head">수취인주소</td>
        <td class="body"><input type=text name="allat_recp_addr" value="서울 관악구 인헌6길 9 3층" size="19" maxlength=120></td>
        <td class="body">120</td>
        <td class="body">allat_recp_addr</td>        
        <td class="body"></td>
    </tr>
    <tr>
        <td class="head">인증정보수신URL</td>
        <td class="body"><input type=text name="shop_receive_url" value="https://lms.malgn.co.kr/allat/allat_receive.jsp" size="19"></td>
        <td class="body">120</td>
        <td class="body">shop_receive_url</td>        
        <td class="body">Full URL 입력</td>
    </tr>
    <tr>
        <td class="head">주문정보암호화필드</td>
        <td class="body"><font color=red>값은 자동으로 설정됨</font></td>
        <td class="body">-</td>
        <td class="body">allat_enc_data</td>
        <td class="body"><font color=red>&ltinput type=hidden name=allat_enc_data value=''&gt<br>
                          ※hidden field로 설정해야함, 결제정보가 암호화되어 설정되는 값</font></td>
        <input type=hidden name=allat_enc_data value=''>
    </tr>
    </table>
    <br>
    <table border=0 cellpadding=0 cellspacing=1 bgcolor="#606060" width=1152 align=center style="TABLE-LAYOUT: fixed;" >
    <font color=blue><b>◆ 옵션정보</b>( 값이나 필드가 없을 경우 상점 속성이나 Default값이 반영됨 )</font>
    <tr>
        <td width=140 class="head">allat_encode_type</td>
        <td width=160 class="body"><input type=text name="allat_encode_type" value="U" size="19" maxlength=1></td>
        <td width=70  class="body">1</td>
        <td width=140 class="body">allat_encode_type</td>        
        <td class="body">-</td>
    </tr>
    <tr>
        <td width=140 class="head">신용카드 결제<br>사용 여부</td>
        <td width=160 class="body"><input type=text name="allat_card_yn" value="" size="19" maxlength=1></td>
        <td width=70  class="body">1</td>
        <td width=140 class="body">allat_card_yn</td>        
        <td class="body">사용(Y),사용하지 않음(N) - Default : 올앳과 계약된 사용여부</td>
    </tr>
    <tr>
        <td class="head">계좌이체 결제<br>사용 여부</td>
        <td class="body"><input type=text name="allat_bank_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_bank_yn</td>                
        <td class="body">사용(Y),사용하지 않음(N) - Default : 올앳과 계약된 사용여부</td>
    </tr>
    <tr>
        <td class="head">무통장(가상계좌) 결제<br>사용 여부</td>
        <td class="body"><input type=text name="allat_vbank_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_vbank_yn</td>                        
        <td class="body">사용(Y),사용하지 않음(N) - Default : 올앳과 계약된 사용여부</td>
    </tr>
    <tr>
        <td class="head">휴대폰 결제<br>사용 여부</td>
        <td class="body"><input type=text name="allat_hp_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_hp_yn</td>                        
        <td class="body">사용(Y),사용하지 않음(N) - Default : 올앳과 계약된 사용여부</td>
    </tr>
    <tr>
        <td class="head">상품권 결제<br>사용 여부</td>
        <td class="body"><input type=text name="allat_ticket_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_ticket_yn</td>                        
        <td class="body">사용(Y),사용하지 않음(N) - Default : 올앳과 계약된 사용여부</td>
    </tr>
    <tr>
        <td class="head">무통장(가상계좌)<br>인증 Key</td>
        <td class="body"><input type=text name="allat_account_key" value="" size="19" maxlength=20></td>
        <td class="body">20</td>
        <td class="body">allat_account_key</td>                        
        <td class="body">계좌 채번방식이 Key별 방식일 때만 사용함<br>
            <font color=blue>건별 채번방식일때 무시, 신청한 상점만 이용 가능하며 회원별 고유 값 필요</font></td>
    </tr>
    <tr>
        <td class="head">과세여부</td>
        <td class="body"><input type=text name="allat_tax_yn" value="Y" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_tax_yn</td>                        
        <td class="body">Y(과세), N(비과세) - Default : Y<br> 
			공급가액과 부가세가 표기되며 현금영수증 사용시 Y로 설정해야 한다.</td>
    </tr>
    <tr>
        <td class="head">할부 사용여부</td>
        <td class="body"><input type=text name="allat_sell_yn" value="Y" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_sell_yn</td>                        
        <td class="body">할부사용(Y), 할부 사용않함(N) - Default : Y</td>
    </tr>
    <tr>
        <td class="head">일반/무이자 할부<br>사용여부</td>
        <td class="body"><input type=text name="allat_zerofee_yn" value="Y" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_zerofee_yn</td>                        
        <td class="body">일반(N), 무이자 할부(Y) - Default :N
          &nbsp;&nbsp <a target=_new href="https://www.allatpay.com/servlet/AllatBizV2/support/SupportFaqCL?menu_id=m040201&type=detail&page=1&seq_no=1145"><b>[설명]</b></a></td>
    </tr>
    <tr>
        <td class="head">포인트 사용 여부</td>
        <td class="body"><input type=text name="allat_bonus_yn" value="N" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_bonus_yn</td>                        
        <td class="body">
			사용(Y), 사용 않음(N) - Default : N</br>
			상점이 포인트가맹점(삼성, 국민, BC 등) 이용시 포인트를 사용하여 결제하는 서비스</br>			
			<font color="red">상점에 포인트 가맹점이 설정되어 있어야함.</br>
			특수포인트의 경우 사용불가</br>
			예)현대 M포인트 : 할부개월+40, allat_bonus_yn='N'</br></font>
		</td>
    </tr>
    <tr>
        <td class="head">현금 영수증 발급 여부</td>
        <td class="body"><input type=text name="allat_cash_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_cash_yn</td>                        
        <td class="body">사용(Y), 사용 않음(N) - Default : 올앳과 계약된 사용여부<br>
			계좌이체/무통장입금(가상계좌)를 이용하실 때, 상점이 현금영수증 사용업체로 지정 되어 있으면 사용가능</td>
    </tr>
    <tr>
        <td class="head">상품이미지 URL</td>
        <td class="body"><input type=text name="allat_product_img" value="http://www.malgnsoft.com/data/file/fb841f6c0b3dccab40f7d6bf32103f7b.png" size="19" maxlength=256></td>
        <td class="body">256</td>
        <td class="body">all_product_img</td>                        
        <td class="body">PlugIn에 보여질 상품이미지 Full URL</td>
    </tr>
    <tr>
        <td class="head">결제 정보 수신 E-mail</td>
        <td class="body"><input type=text name="allat_email_addr" value="" size="19" maxlength=50></td>
        <td class="body">50</td>
        <td class="body">allat_email_addr</td>                        
        <td class="body"><font color=red>에스크로 서비스 사용시에 필수 필드.(결제창에서 E-Mail주소를 넣을 수도 있음)</font></td>
    </tr>
    <tr>
        <td class="head">테스트 여부</td>
        <td class="body"><input type=text name="allat_test_yn" value="Y" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_test_yn</td>                        
        <td class="body">테스트(Y),서비스(N) - Default : N <br>
		  테스트 결제는 실결제가 나지 않으며 테스트 성공시 결과값은 "0001" 리턴</td>
    </tr>
    <tr>
        <td class="head">상품 실물 여부</td>
        <td class="body"><input type=text name="allat_real_yn" value="N" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_real_yn</td>                        
        <td class="body">상품이 실물일 경우 (Y), 상품이 실물이 아닐경우 (N) - Default : N<br>
            <font color=blue>상품이 실물이고, 10만원 이상 계좌이체시 에스크로 적용여부 이용</font>
              &nbsp;&nbsp <a target=_new href="https://www.allatpay.com/servlet/AllatBizV2/support/SupportFaqCL?menu_id=m040201&type=detail&page=1&seq_no=1213"><b>[설명]</b></a><br>
			  에스크로 서비스를 이용하시려면 에스크로 특약서 및 추가신청서를 올앳에 제출 &nbsp;&nbsp <a target=_new href="https://www.allatpay.com/servlet/AllatBizV2/support/SupportFaqCL?menu_id=m040201&type=detail&page=1&seq_no=1210"><b>[설명]</b></a></td>
    </tr>
    <tr>
        <td class="head">카드 에스크로<br>적용여부</td>
        <td class="body"><input type=text name="allat_cardes_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_cardes_yn</td>                        
        <td class="body">카드 결제에 대한 에스크로 적용여부 : 적용 (Y), 미적용 (N), 고객선택 : 값없음 - Default : 값없음<br>
            <font color=blue>에스크로 적용 대상 결제건에 대해서만 적용됨</font></td>
    </tr>
    <tr>
        <td class="head">계좌이체 에스크로<br>적용여부</td>
        <td class="body"><input type=text name="allat_bankes_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_bankes_yn</td>                        
        <td class="body">계좌이체 결제에 대한 에스크로 적용여부 : 적용 (Y), 미적용 (N), 고객선택 : 없음 - Default : 없음<br>
            <font color=blue>에스크로 적용 대상 결제건에 대해서만 적용됨</font></td>
    </tr>
    <tr>
        <td class="head">무통장(가상계좌) 에스<br>크로 적용여부</td>
        <td class="body"><input type=text name="allat_vbankes_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_vbankes_yn</td>                        
        <td class="body">가상계좌 결제에 대한 에스크로 적용여부 : 적용 (Y), 미적용 (N), 고객선택 : 없음 - Default : 없음<br>
            <font color=blue>에스크로 적용 대상 결제건에 대해서만 적용됨</font></td>
    </tr>
    <tr>
        <td class="head">휴대폰 에스크로<br>적용여부</td>
        <td class="body"><input type=text name="allat_hpes_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_hpes_yn</td>                        
        <td class="body">휴대폰 결제에 대한 에스크로 적용여부 : 적용 (Y), 미적용 (N), 고객선택 : 없음 - Default : 없음<br>
            <font color=blue>에스크로 적용 대상 결제건에 대해서만 적용됨</font></td>
    </tr>
    <tr>
        <td class="head">상품권 에스크로<br>적용여부</td>
        <td class="body"><input type=text name="allat_ticketes_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_ticketes_yn</td>                        
        <td class="body">상품권 결제에 대한 에스크로 적용여부 : 적용 (Y), 미적용 (N), 고객선택 : 없음 - Default : 없음<br>
            <font color=blue>에스크로 적용 대상 결제건에 대해서만 적용됨</font></td>
    </tr>
    <tr>
        <td class="head">주민번호</td>
        <td class="body"><input type=text name="allat_registry_no" value="" size="19" maxlength=13></td>
        <td class="body">1</td>
        <td class="body">allat_registry_no</td>                        
        <td class="body">
        <font color=blue> ISP     - 주민번호 13자리(ISP일때는 특정 사업자만 사용함.대부분 사용하지 않음)</font></td>
    </tr>
    <tr>
        <td class="head">KB복합결제 적용여부</td>
        <td class="body"><input type=text name="allat_kbcon_point_yn" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_kbcon_point_yn</td>                        
        <td class="body">KB복합결제 적용여부 : 적용(Y), 미적용(N)</td>
    </tr>
    <tr>
        <td class="head">제공기간</td>
        <td class="body"><input type=text name="allat_provide_date" value="" size="19" maxlength=25></td>
        <td class="body">25</td>
        <td class="body">allat_provide_date</td>                        
        <td class="body">컨텐츠 상품의 제공기간 : YYYY.MM.DD ~ YYYY.MM.DD</td>
    </tr>
	<tr>
        <td class="head">성별</td>
        <td class="body"><input type=text name="allat_gender" value="" size="19" maxlength=1></td>
        <td class="body">1</td>
        <td class="body">allat_gender</td>
        <td class="body">구매자 성별, 남자(M)/여자(F)</td>
    </tr>
    <tr>
        <td class="head">생년월일</td>
        <td class="body"><input type=text name="allat_birth_ymd" value="" size="19" maxlength=8></td>
        <td class="body">8</td>
        <td class="body">allat_birth_ymd</td>                                
        <td class="body">구매자의 생년월일 8자, YYYYMMDD형식</td>
    </tr>
    </table>
    <p align=center>
    <table border=0 cellpadding=0 cellspacing=1 width=1152 align=center>
    <tr><td align=center>
    <input type=button value="  결  제  " name=app_btn onClick="javascript:ftn_approval(document.fm);">
    </td></tr>
    </table>
    </p>
    </form>
</body>
</html>
