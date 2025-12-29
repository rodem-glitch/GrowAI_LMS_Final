<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 시험관리에서 시험 템플릿을 수정하기 위함입니다.

ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();

// 파라미터
int examId = m.ri("id");
String examName = m.rs("exam_nm");
int examTime = m.ri("exam_time");
String shuffleYn = m.rs("shuffle_yn");
int passingScore = m.ri("passing_score");
String questionIds = m.rs("question_ids");
String content = m.rs("content");

// 검증
if(examId <= 0) {
	result.put("rst_code", "1001");
	result.put("rst_message", "시험 ID가 필요합니다.");
	result.print();
	return;
}

// 기존 시험 확인
DataSet info = exam.find("id = " + examId + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 시험이 존재하지 않습니다.");
	result.print();
	return;
}

// 권한 확인
if(!isAdmin && info.i("manager_id") != userId && info.i("manager_id") != -99) {
	result.put("rst_code", "4030");
	result.put("rst_message", "해당 시험을 수정할 권한이 없습니다.");
	result.print();
	return;
}

// 수정
if(!"".equals(examName)) exam.item("exam_nm", examName);
if(examTime > 0) exam.item("exam_time", examTime);
if(!"".equals(shuffleYn)) exam.item("shuffle_yn", "Y".equals(shuffleYn) ? "Y" : "N");

// 왜: 문제 목록이 바뀌면 난이도별 문항수/배점도 같이 맞춰야 합니다.
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

String rangeIdx = questionIdList.size() > 0 ? m.join(",", (String[]) questionIdList.toArray(new String[0])) : "";
exam.item("range_idx", rangeIdx);
exam.item("question_cnt", questionCntFinal);

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

exam.item("assign1", assigns[1]);
exam.item("assign2", assigns[2]);
exam.item("assign3", assigns[3]);
exam.item("assign4", assigns[4]);
exam.item("assign5", assigns[5]);
exam.item("assign6", assigns[6]);
exam.item("content", content);

if(!exam.update("id = " + examId + " AND site_id = " + siteId)) {
	result.put("rst_code", "5000");
	result.put("rst_message", "시험 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "시험이 수정되었습니다.");
result.put("rst_data", examId);
result.print();

%>
