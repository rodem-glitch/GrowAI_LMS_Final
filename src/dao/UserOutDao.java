package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class UserOutDao extends DataObject {
	
	public String[] statusList = { "0=>탈퇴", "1=>삭제" };
	public String[] types = {
		"H1=>홈페이지 이용 불편"
		, "H2=>교육과정 부족"
		, "H3=>부족한 강의 수준"
		, "H4=>시스템 장애"
		, "H5=>장기간 부재 (군 입대, 유학 등)"
		, "H6=>서비스 부족"
		, "H7=>개인정보의 노출 우려"
		, "ETC=>기타"
	};

	public String[] statusListMsg = { "1=>list.user_out.status_list.1", "0=>list.user_out.status_list.0" };
	public String[] typesMsg = {
		"H1=>list.user_out.types.H1"
		, "H2=>list.user_out.types.H2"
		, "H3=>list.user_out.types.H3"
		, "H4=>list.user_out.types.H4"
		, "H5=>list.user_out.types.H5"
		, "H6=>list.user_out.types.H6"
		, "H7=>list.user_out.types.H7"
		, "ETC=>list.user_out.types.ETC"
	};

	public UserOutDao() {
		this.table = "TB_USER_OUT";
		this.PK = "user_id";
	}
}