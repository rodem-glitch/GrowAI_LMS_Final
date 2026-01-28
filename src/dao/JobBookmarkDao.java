package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class JobBookmarkDao extends DataObject {

	// 왜: 채용 북마크는 화면에서 “저장/해제/목록”만 우선 필요해서, 최소 필드로 단순하게 관리합니다.
	public String[] statusList = { "1=>정상", "0=>중지", "-1=>삭제" };

	public JobBookmarkDao() {
		this.table = "TB_JOB_BOOKMARK";
		this.PK = "id";
	}

	private String normalizeProvider(String provider) {
		// 왜: Work24 쪽은 API에서 infoSvc 값이 `VALIDATION` 등으로 내려오는 케이스가 있어,
		// DB/화면/삭제 키가 서로 달라지면 “저장 해제가 안 되는” 문제가 생깁니다.
		// 따라서 현재는 제공처를 (JOBKOREA) vs (그 외=WORK24) 두 그룹으로 정규화합니다.
		if(provider == null) return "WORK24";
		String v = provider.trim().toUpperCase();
		if("JOBKOREA".equals(v)) return "JOBKOREA";
		return "WORK24";
	}

	private void ensureSequenceRow() {
		// 왜: MalgnLMS는 많은 테이블이 AUTO_INCREMENT가 아니라 `tb_sequence`로 ID를 발급합니다.
		// - 새 테이블을 만들 때 tb_sequence에 행을 안 넣으면 getSequence()가 실패하면서 500이 날 수 있습니다.
		// - DDL을 실행했더라도 실수로 빠질 수 있으니, 런타임에서도 “없는 경우만” 보완합니다.
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

	public boolean saveBookmark(
		int siteId,
		int userId,
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
		// 왜: (siteId,userId,provider,wantedAuthNo) 유니크로 중복을 막고, 재저장은 UPDATE로 흡수합니다.
		if(siteId <= 0 || userId <= 0) return false;
		if(provider == null || "".equals(provider.trim())) provider = "WORK24";
		if(wantedAuthNo == null || "".equals(wantedAuthNo.trim())) return false;
		if(now == null || "".equals(now.trim())) now = Malgn.time("yyyyMMddHHmmss");

		provider = normalizeProvider(provider);
		wantedAuthNo = wantedAuthNo.trim();

		// 왜: 과거 데이터에 provider가 WORK24가 아닌 값(예: VALIDATION)으로 저장된 경우가 있어,
		// 저장 시에도 “WORK24 그룹”을 먼저 찾아서 한 행으로 흡수(정규화)합니다.
		DataSet info = null;
		boolean hasInfo = false;
		if("JOBKOREA".equals(provider)) {
			info = this.find(
				"site_id = ? AND user_id = ? AND provider = ? AND wanted_auth_no = ?",
				new Object[] { siteId, userId, provider, wantedAuthNo }
			);
			hasInfo = info.next();
		} else {
			DataSet infoWork24 = this.find(
				"site_id = ? AND user_id = ? AND provider = ? AND wanted_auth_no = ?",
				new Object[] { siteId, userId, "WORK24", wantedAuthNo }
			);
			if(infoWork24.next()) {
				info = infoWork24;
				hasInfo = true;
			} else {
				info = this.find(
					"site_id = ? AND user_id = ? AND wanted_auth_no = ? AND provider != ?",
					new Object[] { siteId, userId, wantedAuthNo, "JOBKOREA" }
				);
				hasInfo = info.next();
			}
		}

		this.item("wanted_info_url", wantedInfoUrl);
		this.item("title", title);
		this.item("company", company);
		this.item("region", region);
		this.item("close_dt", closeDt);
		this.item("item_json", itemJson);
		this.item("status", 1);
		this.item("mod_date", now);
		this.item("provider", provider);

		if(hasInfo) {
			// 왜: 소프트삭제(-1) 상태였더라도 다시 저장하면 정상(1)로 되돌립니다.
			this.item("reg_date", now);
			return this.update("id = " + info.i("id"));
		}

		this.ensureSequenceRow();
		this.item("id", this.getSequence());
		this.item("site_id", siteId);
		this.item("user_id", userId);
		this.item("provider", provider);
		this.item("wanted_auth_no", wantedAuthNo);
		this.item("reg_date", now);
		return this.insert();
	}

	public boolean deleteBookmark(int siteId, int userId, String provider, String wantedAuthNo, String now) {
		// 왜: 목록에서만 빠지면 되므로, 실제 삭제 대신 status=-1로 표기합니다.
		if(siteId <= 0 || userId <= 0) return false;
		if(provider == null || "".equals(provider.trim())) provider = "WORK24";
		if(wantedAuthNo == null || "".equals(wantedAuthNo.trim())) return false;
		if(now == null || "".equals(now.trim())) now = Malgn.time("yyyyMMddHHmmss");

		provider = normalizeProvider(provider);
		wantedAuthNo = wantedAuthNo.trim();

		// 왜: provider 정규화 이전에 저장된 데이터(예: provider=VALIDATION)는
		// 화면에서는 WORK24로 보이지만, 삭제는 provider 매칭이 안 되어 “해제 불가”가 됩니다.
		// 그래서 WORK24 그룹은 (provider != JOBKOREA) 전체를 대상으로 멱등 삭제합니다.
		DataSet info = null;
		if("JOBKOREA".equals(provider)) {
			info = this.find(
				"site_id = ? AND user_id = ? AND provider = ? AND wanted_auth_no = ? AND status != -1",
				new Object[] { siteId, userId, provider, wantedAuthNo }
			);
		} else {
			info = this.find(
				"site_id = ? AND user_id = ? AND wanted_auth_no = ? AND provider != ? AND status != -1",
				new Object[] { siteId, userId, wantedAuthNo, "JOBKOREA" }
			);
		}
		if(!info.next()) return true; // 왜: 이미 없는(또는 삭제된) 상태면 멱등 처리합니다.

		boolean ok = true;
		this.item("status", -1);
		this.item("mod_date", now);
		do {
			ok = ok && this.update("id = " + info.i("id"));
		} while(info.next());

		return ok;
	}

	public int getCount(int siteId, int userId) {
		if(siteId <= 0 || userId <= 0) return 0;
		return this.getOneInt(
			"SELECT COUNT(*) FROM " + this.table + " WHERE site_id = " + siteId + " AND user_id = " + userId + " AND status = 1"
		);
	}

	public DataSet getList(int siteId, int userId, int page, int size) {
		if(page < 1) page = 1;
		if(size < 1) size = 20;
		if(size > 200) size = 200;
		int offset = (page - 1) * size;

		// 왜: 북마크는 DB에 스냅샷을 저장해두므로, 목록은 DB만으로 빠르게 뽑을 수 있습니다.
		return this.query(
			" SELECT id, provider, wanted_auth_no, wanted_info_url, title, company, region, close_dt, item_json, reg_date "
			+ " FROM " + this.table
			+ " WHERE site_id = ? AND user_id = ? AND status = 1 "
			+ " ORDER BY reg_date DESC, id DESC "
			+ " LIMIT ?, ? "
			, new Object[] { siteId, userId, offset, size }
		);
	}
}
