package dao;

import malgnsoft.db.*;

public class QnaDao extends DataObject {

	public String[] secrets = { "N=>공개", "Y=>비공개" };
	public String[] ansList = { "1=>답변완료", "2=>확인중", "0=>미확인" };
	public String[] emails = { "naver.com=>naver.com", "nate.com=>nate.com", "yahoo.com=>yahoo.com", "paran.com=>paran.com", "empal.com=>empal.com", "dreamwiz.com=>dreamwiz.com", "freechal.com=>freecal.com", "hanafos.com=>hanafos.com", "hotmail.com=>hotmail.com", "lycos.co.kr=>lycos.co.kr", "korea.com=>korea.com" };

	public String[] secretsMsg = { "N=>list.qna.secrets.N", "Y=>list.qna.secrets.Y" };
	public String[] ansListMsg = { "1=>list.qna.ans_list.1", "2=>list.qna.ans_list.2", "0=>list.qna.ans_list.0" };

	public QnaDao() {
		this.table = "TB_QNA";
	}

	//업데이트-조회수
	public int updateHitCount(int id) {
		return execute("UPDATE " + table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	}

}