<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 수료관리에서 수료증/합격증 출력 시, 사용할 템플릿 목록을 조회할 수 있어야 합니다.

String templateType = m.rs("template_type"); //C(수료), P(합격) - 선택

CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();
DataSet list = new DataSet();

try {
	list = certificateTemplate.getList(siteId, templateType);
} catch(Exception e) {
	//왜: 환경마다 컬럼(예: template_type) 존재 여부가 다를 수 있어, 실패하면 전체 템플릿으로 fallback 합니다.
	list = certificateTemplate.getList(siteId);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

