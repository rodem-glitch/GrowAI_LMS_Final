package dao;

import malgnsoft.db.*;

public class SendAutoDao extends DataObject {

	public String[] statusList = { "1=>사용", "0=>중지" };
	public String[] types = { "S=>SMS", "E=>이메일", "M=>쪽지" };

	public String[] homeworkList = { "-=>해당 없음", "Y=>과제 제출", "N=>과제 미제출" };
	public String[] examList = { "-=>해당 없음", "Y=>시험 제출", "N=>시험 미제출" };
	public String[] atypes = { "-=>모두", "Y=>제출", "N=>미제출" };
	public String[] stypes = { "S=>학습 시작일", "E=>학습 종료일" };

	public String[] names = { 
		"A=>성명", "B=>학습시작일", "C=>학습종료일"
		, "D=>과정명", "E=>총점", "F=>진도율", "G=>진도점수"
		, "H=>과제점수", "I=>시험점수", "J=>토론점수" 
	};

	public String[] matchingList = { 
		"$A$=>user_name", "$B$=>start_date", "$C$=>end_date"
		, "$D$=>step_name", "$E$=>total_score", "$F$=>progress_ratio", "$G$=>progress_score"
		, "$H$=>homework_score", "$I$=>exam_score", "$J$=>forum_score" 
	};
	
	public String[] statusListMsg = { "1=>list.send_auto.status_list.1", "0=>list.send_auto.status_list.0" };
	public String[] typesMsg = {"S=>list.send_auto.types.S", "E=>list.send_auto.types.E", "M=>list.send_auto.types.M"};

	public String[] homeworkListMsg = {"-=>list.send_auto.homework_list.-", "Y=>list.send_auto.homework_list.Y", "N=>list.send_auto.homework_list.N"};
	public String[] examListMsg = {"-=>list.send_auto.exam_list.-", "Y=>list.send_auto.exam_list.Y", "N=>list.send_auto.exam_list.N"};
	public String[] atypesMsg = {"-=>list.send_auto.atypes.-", "Y=>list.send_auto.atypes.Y", "N=>list.send_auto.atypes.N"};
	public String[] stypesMsg = { "S=>list.send_auto.stypes.S", "E=>list.send_auto.stypes.E" };

	public String[] namesMsg = { 
		"A=>list.send_auto.names.A", "B=>list.send_auto.names.B", "C=>list.send_auto.names.C"
		, "D=>list.send_auto.names.D", "E=>list.send_auto.names.E", "F=>list.send_auto.names.F", "G=>list.send_auto.names.G"
		, "H=>list.send_auto.names.H", "I=>list.send_auto.names.I", "J=>list.send_auto.names.J" 
	};

	public SendAutoDao() {
		this.table = "TB_SEND_AUTO";
		this.PK = "id";
	}
}