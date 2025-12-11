package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class ClCommentDao extends DataObject {

	private int siteId = 0;

	private boolean maskYn = false;
	public ClCommentDao() {
		this.table = "CL_COMMENT";
	}

	public ClCommentDao(int siteId) {
		this.table = "CL_COMMENT";
		this.siteId = siteId;
	}

	public void setMaskYn(boolean maskYn) {
		this.maskYn = maskYn;
	}

	public DataSet getInfo(int commentId) {
		DataSet info = this.query(
			"SELECT c.id comment_id, c.user_id, c.mod_date, c.reg_date, c.content "
			+ ", u.user_nm, u.login_id, u.user_kind "
			+ ", (CASE WHEN c.user_id = p.user_id THEN 'Y' ELSE 'N' END) writer_yn "
			+ ", (CASE WHEN c.mod_date != '' THEN 'Y' ELSE 'N' END) modify_yn "
			+ " FROM " + this.table + " c "
			+ " INNER JOIN " + new UserDao().table + " u ON u.id = c.user_id AND u.status NOT IN (-1, 31) AND u.site_id = " + siteId + ""
			+ " INNER JOIN " + new ClPostDao().table + " p ON p.id = c.module_id AND p.depth = 'A' AND p.status > -1 "
			+ " WHERE c.id = " + commentId + " AND c.status > 0"
		); info.next();
		info.put("date_conv", Malgn.time("yyyy-MM-dd HH:mm:ss", !"".equals(info.s("mod_date")) ? info.s("mod_date") :  info.s("reg_date")));
		info.put("content_conv", Malgn.nl2br(Malgn.htt(info.s("content"))));
		info.put("reply_cnt", 0);
		info.put("user_nm", this.maskYn && !"S".equals(info.s("user_kind")) ? this.masking(info.s("user_nm")) : info.s("user_nm"));
		return info;
	}

	public DataSet getList(int moduleId, String module) {
		DataSet list = this.query(
			"SELECT c.id comment_id, c.user_id, c.mod_date, c.reg_date, c.content "
			+ ", u.user_nm, u.login_id, u.user_kind "
			+ ", (CASE WHEN c.user_id = p.user_id THEN 'Y' ELSE 'N' END) writer_yn "
			+ ", (CASE WHEN c.mod_date != '' THEN 'Y' ELSE 'N' END) modify_yn "
			+ ", (SELECT COUNT(*) FROM " + this.table + " WHERE parent_id = c.id AND status > 0) reply_cnt "
			+ " FROM " + this.table + " c "
			+ " INNER JOIN " + new UserDao().table + " u ON u.id = c.user_id AND u.status NOT IN (-1, 31) AND u.site_id = " + siteId + ""
			+ " INNER JOIN " + new ClPostDao().table + " p ON p.id = c.module_id AND p.depth = 'A' AND p.status > -1 "
			+ " WHERE c.parent_id = 0 AND c.module_id = " + moduleId + " AND c.module = '" + module + "' AND c.status > 0"
			+ " ORDER BY c.reg_date DESC, c.id DESC"
		);
		while(list.next()) {
			list.put("date_conv", Malgn.time("yyyy-MM-dd HH:mm:ss", !"".equals(list.s("mod_date")) ? list.s("mod_date") :  list.s("reg_date")));
			list.put("content_conv", Malgn.nl2br(Malgn.htt(list.s("content"))));
			list.put("reply_list", getReplyList(list.i("comment_id")));
			list.put("user_nm", this.maskYn && !"S".equals(list.s("user_kind")) ? this.masking(list.s("user_nm")) : list.s("user_nm"));
		}

		return list;
	}

	public DataSet getReplyInfo(int commentId) {
		DataSet info = this.query(
			"SELECT c.id comment_id, c.user_id, c.mod_date, c.reg_date, c.content, c.parent_id, c.reply_user_id "
			+ ", u.user_nm, u.login_id, u.user_kind "
			+ ", ru.user_nm reply_user_nm, ru.login_id reply_user_login_id, ru.user_kind reply_user_kind "
			+ ", (CASE WHEN c.user_id = p.user_id THEN 'Y' ELSE 'N' END) writer_yn "
			+ ", (CASE WHEN c.mod_date != '' THEN 'Y' ELSE 'N' END) modify_yn "
			+ " FROM " + this.table + " c "
			+ " INNER JOIN " + new UserDao().table + " u ON u.id = c.user_id AND u.status NOT IN (-1, 31) AND u.site_id = " + siteId + ""
			+ " INNER JOIN " + new UserDao().table + " ru ON ru.id = c.reply_user_id AND ru.status NOT IN (-1, 31) AND ru.site_id = " + siteId + ""
			+ " INNER JOIN " + new ClPostDao().table + " p ON p.id = c.module_id AND p.depth = 'A' AND p.status > -1 "
			+ " WHERE c.id = " + commentId + " AND c.status > 0"
		); info.next();
		info.put("date_conv", Malgn.time("yyyy-MM-dd HH:mm:ss", !"".equals(info.s("mod_date")) ? info.s("mod_date") :  info.s("reg_date")));
		info.put("content_conv", Malgn.nl2br(Malgn.htt(info.s("content"))));
		info.put("reply_cnt", 0);
		info.put("user_nm", this.maskYn && !"S".equals(info.s("user_kind")) ? this.masking(info.s("user_nm")) : info.s("user_nm"));
		info.put("reply_user_nm", this.maskYn && !"S".equals(info.s("reply_user_kind")) ? this.masking(info.s("reply_user_nm")) : info.s("reply_user_nm"));

		return info;
	}

	public DataSet getReplyList(int parentId) {
		DataSet list = this.query(
			"SELECT c.id comment_id, c.user_id, c.mod_date, c.reg_date, c.content, c.parent_id, c.reply_user_id "
			+ ", u.user_nm, u.login_id, u.user_kind "
			+ ", ru.user_nm reply_user_nm, ru.login_id reply_user_login_id, ru.user_kind reply_user_kind "
			+ ", (CASE WHEN c.user_id = p.user_id THEN 'Y' ELSE 'N' END) writer_yn "
			+ ", (CASE WHEN c.mod_date != '' THEN 'Y' ELSE 'N' END) modify_yn "
			+ " FROM " + this.table + " c "
			+ " INNER JOIN " + new UserDao().table + " u ON u.id = c.user_id AND u.status NOT IN (-1, 31) AND u.site_id = " + siteId + ""
			+ " INNER JOIN " + new UserDao().table + " ru ON ru.id = c.reply_user_id AND ru.status NOT IN (-1, 31) AND ru.site_id = " + siteId + ""
			+ " INNER JOIN " + new ClPostDao().table + " p ON p.id = c.module_id AND p.depth = 'A' AND p.status > -1 "
			+ " WHERE c.parent_id = " + parentId + " AND c.status > 0"
			+ " ORDER BY c.reg_date DESC, c.id DESC"
		);
		while(list.next()) {
			list.put("date_conv", Malgn.time("yyyy-MM-dd HH:mm:ss", !"".equals(list.s("mod_date")) ? list.s("mod_date") : list.s("reg_date")));
			list.put("content_conv", Malgn.nl2br(Malgn.htt(list.s("content"))));
			list.put("user_nm", this.maskYn && !"S".equals(list.s("user_kind")) ? this.masking(list.s("user_nm")) : list.s("user_nm"));
			list.put("reply_user_nm", this.maskYn && !"S".equals(list.s("reply_user_kind")) ? this.masking(list.s("reply_user_nm")) : list.s("reply_user_nm"));
		}

		return list;
	}

	public int getCommentCount(String module, int moduleId) {
		return this.getOneInt(
			"SELECT COUNT(*) "
			+ " FROM " + this.table + " c "
			+ " INNER JOIN " + new UserDao().table + " u ON u.id = c.user_id AND u.status NOT IN (-1, 31) "
			+ " WHERE c.status = 1 AND module_id = ? AND module = ? AND parent_id = 0"
			, new Object[] { moduleId, module }
		);
	}

	public String masking(String v) {
		int len = v.length();
		if(len < 1) {
			return "";
		} else if(len < 3) {
			return v.charAt(0) + new String(new char[len - 1]).replace("\0", "*");
		} else {
			return v.charAt(0) + new String(new char[len - 2]).replace("\0", "*") + v.charAt(len - 1);
		}
	}
}