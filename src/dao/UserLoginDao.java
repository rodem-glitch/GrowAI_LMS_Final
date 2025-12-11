package dao;

import malgnsoft.db.*;

public class UserLoginDao extends DataObject {

	public String[] adminYnList = { "N=>사용자단", "Y=>관리자단" };
	public String[] loginTypeList = { "I=>로그인", "O=>로그아웃", "S=>세션만료" };
	
	public String[] adminYnListMsg = { "N=>list.user_login.admin_yn_list.N", "Y=>list.user_login.admin_yn_list.Y" };
	public String[] loginTypeListMsg = { "I=>list.user_login.login_type_list.I", "O=>list.user_login.login_type_list.O", "S=>list.user_login.login_type_list.S" };
	
	public UserLoginDao() {
		this.table = "TB_USER_LOGIN";
	}

	public boolean isMobile(String agent) {
		boolean isMobile = false;
		if(null != agent) {
			String[] mobileKeyWords = {
				"iPhone", "iPod", "iPad"
				, "BlackBerry", "Android", "Windows CE"
				, "LG", "MOT", "SAMSUNG", "SonyEricsson"
			};
			for(int i=0; i<mobileKeyWords.length; i++) {
				if(agent.indexOf(mobileKeyWords[i]) != -1) {
					isMobile = true;
					break;
				}
			}
		}
		return isMobile;
	}

	public String getDeviceType(String agent) {
		if(this.isMobile(agent)) return "Mobile";
		else return "PC";
	}
}