<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 시험관리에서 새 시험 템플릿을 등록하기 위함입니다.

ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();

// 파라미터
String examName = m.rs("exam_nm");
int examTime = m.ri("exam_time") > 0 ? m.ri("exam_time") : 60;
String shuffleYn = "Y".equals(m.rs("shuffle_yn")) ? "Y" : "N";
int passingScore = m.ri("passing_score");
String questionIds = m.rs("question_ids"); // 쉼표 구분 문제 ID 목록
String content = m.rs("content"); // 시험 설명

// 검증
if("".equals(examName)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "시험명이 필요합니다.");
	result.print();
	return;
}

// 등록
int newId = exam.getSequence();
exam.item("id", newId);
exam.item("site_id", siteId);
exam.item("onoff_type", "N"); // 온라인 시험
exam.item("exam_nm", examName);
exam.item("exam_time", examTime);
// 왜: 시험 저장 시 난이도별 문항수/배점이 필수라서, 문제 목록으로 직접 계산합니다.
ArrayList<String> questionIdList = new ArrayList<String>();
if(!"".equals(questionIds)) {
	String[] rawIds = questionIds.split(",");
	for(int i = 0; i < rawIds.length; i++) {
		String qid = rawIds[i].trim();
		if(qid.matches("\\d+")) questionIdList.add(qid);
	}
}

int[] mcnt = new int[7];
int[] tcnt = new int[7];
int questionCntFinal = 0;

if(questionIdList.size() > 0) {
	String[] idArr = (String[]) questionIdList.toArray(new String[0]);
	DataSet qlist = question.find(
		"site_id = " + siteId + " AND status != -1 AND id IN (" + m.join(",", idArr) + ")"
	);
	while(qlist.next()) {
		questionCntFinal++;
		int grade = qlist.i("grade");
		if(grade < 1 || grade > 6) grade = 1;

		String qtype = qlist.s("question_type");
		if("1".equals(qtype) || "2".equals(qtype)) mcnt[grade]++;
		else tcnt[grade]++;
	}
}

int[] assigns = new int[7];
for(int i = 1; i <= 6; i++) {
	assigns[i] = (mcnt[i] + tcnt[i]) > 0 ? 1 : 0;
}
if(passingScore > 0) assigns[1] = passingScore;

exam.item("question_cnt", questionCntFinal);
exam.item("shuffle_yn", shuffleYn);
exam.item("auto_complete_yn", "Y"); // 자동채점
exam.item("retake_yn", "N");
exam.item("permission_number", 0);
exam.item("content", content);

// 문제 ID 목록을 range_idx에 저장 (기존 필드 활용)
String rangeIdx = questionIdList.size() > 0 ? m.join(",", (String[]) questionIdList.toArray(new String[0])) : "";
exam.item("range_idx", rangeIdx);

// 난이도별 객관식/주관식 문항수
exam.item("mcnt1", mcnt[1]);
exam.item("mcnt2", mcnt[2]);
exam.item("mcnt3", mcnt[3]);
exam.item("mcnt4", mcnt[4]);
exam.item("mcnt5", mcnt[5]);
exam.item("mcnt6", mcnt[6]);
exam.item("tcnt1", tcnt[1]);
exam.item("tcnt2", tcnt[2]);
exam.item("tcnt3", tcnt[3]);
exam.item("tcnt4", tcnt[4]);
exam.item("tcnt5", tcnt[5]);
exam.item("tcnt6", tcnt[6]);

// 난이도별 기본 배점
exam.item("assign1", assigns[1]);
exam.item("assign2", assigns[2]);
exam.item("assign3", assigns[3]);
exam.item("assign4", assigns[4]);
exam.item("assign5", assigns[5]);
exam.item("assign6", assigns[6]);

exam.item("manager_id", userId);
exam.item("reg_date", m.time("yyyyMMddHHmmss"));
exam.item("status", 1);

if(!exam.insert()) {
	result.put("rst_code", "5000");
	result.put("rst_message", "시험 등록 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "시험이 등록되었습니다.");
result.put("rst_data", newId);
result.print();

%>
