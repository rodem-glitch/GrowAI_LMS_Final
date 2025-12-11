package dao;

import java.util.*;
import java.security.*;
import malgnsoft.db.*;

public class CouponDao extends DataObject {

	public String[] couponTypes = { "A=>과정/도서", "C=>과정", "B=>도서" };
	public String[] ucouponTypes = { "A=>전체", "C=>과정", "B=>도서", "T=>장바구니" };
	public String[] discTypes = { "P=>정액", "R=>정률" };
	public String[] publicTypes = { "Y=>공용", "N=>개별" };
	public String[] statusList = { "1=>정상", "0=>중지" };

	public String[] couponTypesMsg = { "A=>list.coupon.coupon_types.A", "C=>list.coupon.coupon_types.C", "B=>list.coupon.coupon_types.B" };
	public String[] ucouponTypesMsg = { "A=>list.coupon.ucoupon_types.A", "C=>list.coupon.ucoupon_types.C", "B=>list.coupon.ucoupon_types.B", "T=>list.coupon.ucoupon_types.T" };
	public String[] discTypesMsg = { "P=>list.coupon.disc_types.P", "R=>list.coupon.disc_types.R" };
	public String[] publicTypesMsg = { "Y=>list.coupon.public_types.Y", "N=>list.coupon.public_types.N" };
	public String[] statusListMsg = { "1=>list.coupon.status_list.1", "0=>list.coupon.status_list.0" };

	public CouponDao() {
		this.table = "TB_COUPON";
	}

    public String getCouponNo() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        SecureRandom r = new SecureRandom();
        char[] buf = new char[12];
        for (int i = 0; i < buf.length; i++) {
            buf[i] = chars.charAt(r.nextInt(chars.length()));
        }
        return new String(buf);
    }

	public int updateCouponCnt(int id) {
		int cnt = new CouponUserDao().findCount("coupon_id = " + id);
		return this.execute("UPDATE " + this.table + " SET coupon_cnt = " + cnt + " WHERE id = " + id);
	}

	public String addHyphen(String couponNo) {
		if("".equals(couponNo)) return "";
		if(couponNo.length() < 12) return "";
		return couponNo.substring(0, 4) + "-" + couponNo.substring(4, 8) + "-" + couponNo.substring(8);
	}
}