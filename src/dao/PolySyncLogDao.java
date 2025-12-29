package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class PolySyncLogDao extends DataObject {

	public PolySyncLogDao() {
		this.table = "LM_POLY_SYNC_LOG";
		this.PK = "sync_key";
	}

	// 왜: 배치 동기화는 실패해도 원인 추적이 가능해야 하므로, 마지막 실행 결과를 한 곳에 기록합니다.
	public boolean upsert(String syncKey, String result, String message) {
		if(syncKey == null || "".equals(syncKey)) return false;
		String now = Malgn.time("yyyyMMddHHmmss");
		int ret = this.execute(
			" REPLACE INTO " + this.table
			+ " (sync_key, last_sync_date, last_result, last_message, reg_date, mod_date) "
			+ " VALUES(?,?,?,?,?,?) "
			, new Object[] { syncKey, now, result, message, now, now }
		);
		return -1 < ret;
	}
}
