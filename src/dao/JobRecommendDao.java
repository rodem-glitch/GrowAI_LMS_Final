package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class JobRecommendDao extends DataObject {

	// 왜: 교수 추천은 “학생 기준 1회”로 저장되어야 하므로, 중복은 update로 흡수합니다.
	public String[] statusList = { "1=>정상", "0=>중지", "-1=>삭제" };

	public JobRecommendDao() {
		this.table = "TB_JOB_RECOMMEND";
		this.PK = "id";
	}

	private void ensureSequenceRow() {
		// 왜: MalgnLMS는 tb_sequence로 PK를 발급하므로, 누락 시 런타임에서 보완합니다.
		try {
			int cnt = this.getOneInt("SELECT COUNT(*) FROM tb_sequence WHERE id = '" + this.table + "'");
			if(cnt > 0) return;
		} catch(Exception e) {
			// 무시하고 아래에서 보완 시도
		}

		try {
			this.execute("INSERT INTO tb_sequence (id, seq) VALUES ('" + this.table + "', 0)");
		} catch(Exception e) {
			// 동시성/이미 존재 등의 이유로 실패할 수 있으니 무시합니다.
		}
	}

	public boolean saveRecommend(
		int siteId,
		int tutorUserId,
		int courseId,
		int studentUserId,
		String provider,
		String wantedAuthNo,
		String wantedInfoUrl,
		String title,
		String company,
		String region,
		String closeDt,
		String itemJson,
		String now
	) {
		// 왜: 학생 기준 1회 저장이므로 (siteId, studentUserId, provider, wantedAuthNo)로 중복을 찾습니다.
		if(siteId <= 0 || tutorUserId <= 0 || courseId <= 0 || studentUserId <= 0) return false;
		if(provider == null || "".equals(provider.trim())) provider = "WORK24";
		if(wantedAuthNo == null || "".equals(wantedAuthNo.trim())) return false;
		if(now == null || "".equals(now.trim())) now = Malgn.time("yyyyMMddHHmmss");

		provider = provider.trim().toUpperCase();
		wantedAuthNo = wantedAuthNo.trim();

		DataSet info = this.find(
			"site_id = ? AND student_user_id = ? AND provider = ? AND wanted_auth_no = ?",
			new Object[] { siteId, studentUserId, provider, wantedAuthNo }
		);

		this.item("tutor_user_id", tutorUserId);
		this.item("course_id", courseId);
		this.item("wanted_info_url", wantedInfoUrl);
		this.item("title", title);
		this.item("company", company);
		this.item("region", region);
		this.item("close_dt", closeDt);
		this.item("item_json", itemJson);
		this.item("status", 1);
		this.item("mod_date", now);

		if(info.next()) {
			// 왜: 이미 추천이 있더라도 최신 정보로 갱신합니다.
			return this.update("id = " + info.i("id"));
		}

		this.ensureSequenceRow();
		this.item("id", this.getSequence());
		this.item("site_id", siteId);
		this.item("student_user_id", studentUserId);
		this.item("provider", provider);
		this.item("wanted_auth_no", wantedAuthNo);
		this.item("reg_date", now);
		return this.insert();
	}

	public int getCount(int siteId, int studentUserId) {
		if(siteId <= 0 || studentUserId <= 0) return 0;
		return this.getOneInt(
			"SELECT COUNT(*) FROM " + this.table + " WHERE site_id = " + siteId + " AND student_user_id = " + studentUserId + " AND status = 1"
		);
	}

	public DataSet getList(int siteId, int studentUserId, int page, int size) {
		if(page < 1) page = 1;
		if(size < 1) size = 20;
		if(size > 200) size = 200;
		int offset = (page - 1) * size;

		return this.query(
			" SELECT id, tutor_user_id, course_id, student_user_id, provider, wanted_auth_no, wanted_info_url, title, company, region, close_dt, item_json, reg_date "
			+ " FROM " + this.table
			+ " WHERE site_id = ? AND student_user_id = ? AND status = 1 "
			+ " ORDER BY reg_date DESC, id DESC "
			+ " LIMIT ?, ? "
			, new Object[] { siteId, studentUserId, offset, size }
		);
	}
}

