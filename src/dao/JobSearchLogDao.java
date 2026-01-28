package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class JobSearchLogDao extends DataObject {

	// 왜: 검색어 로그는 삭제 대신 status=-1로만 관리하고, 통계는 status=1만 집계합니다.
	public String[] statusList = { "1=>정상", "0=>중지", "-1=>삭제" };

	public JobSearchLogDao() {
		this.table = "TB_JOB_SEARCH_LOG";
		this.PK = "id";
	}

	public boolean insertLog(int siteId, int userId, String provider, String queryText, String now) {
		// 왜: 교수 통계에서 익명 집계를 하려면 "누가(userId)가 어떤 검색어를 검색했는지"가 최소로 필요합니다.
		if(siteId <= 0 || userId <= 0) return false;
		if(queryText == null) return false;
		if(provider == null) return false;
		if(now == null || "".equals(now.trim())) return false;

		String q = queryText.trim();
		if("".equals(q)) return false;
		// 왜: 폴백(조용히 자르기) 없이, 입력 제한을 위반하면 실패로 처리해 원인을 드러냅니다.
		if(q.length() > 200) return false;

		String p = provider.trim().toUpperCase();
		// 왜: 현재 자연어 검색 로그는 통합(ALL)만 사용합니다. 다른 값은 오류로 처리합니다(폴백 금지).
		if(!"ALL".equals(p)) return false;

		// 왜: 이 테이블의 PK는 tb_sequence 기반입니다. 누락 상태를 조용히 보완하지 않고, 로그로 원인을 남깁니다.
		int seqCnt = 0;
		try {
			seqCnt = this.getOneInt("SELECT COUNT(*) FROM tb_sequence WHERE id = '" + this.table + "'");
		} catch(Exception e) {
			Malgn.errorLog("{dao.JobSearchLogDao} tb_sequence check error: " + e.getMessage(), e);
			return false;
		}
		if(seqCnt <= 0) {
			Malgn.errorLog("{dao.JobSearchLogDao} tb_sequence row missing: " + this.table);
			return false;
		}

		this.item("id", this.getSequence());
		this.item("site_id", siteId);
		this.item("user_id", userId);
		this.item("provider", p);
		this.item("query_text", q);
		this.item("reg_date", now);
		this.item("status", 1);
		return this.insert();
	}
}
