package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class CouponUserDao extends DataObject {

	public String[] useTypes = { "Y=>사용", "N=>미사용" };

	public String[] useTypesMsg = { "Y=>list.coupon_user.use_types.Y", "N=>list.coupon_user.use_types.N" };

	public CouponUserDao() {
		this.table = "TB_COUPON_USER";
	}
	
	/*
	** 쿠폰적용여부
	** 쿠폰 유효기간일때
	** 과정 - 전체/과정 이고 과정전체 이거나 해당 과정인 경우
	** 교재 - 전체/교재
	** 금액 - 최소금액이상일 경우
	*/
	public boolean isValid(DataSet couponInfo, DataSet itemInfo) {
		String today = Malgn.time("yyyyMMdd");
		return  ( 0 <= Malgn.diffDate("D", couponInfo.s("start_date"), today)
					&& 0 <= Malgn.diffDate("D", today, couponInfo.s("end_date"))
				) && ( 
				( "course".equals(itemInfo.s("product_type"))
					&& ("A".equals(couponInfo.s("coupon_type")) || "C".equals(couponInfo.s("coupon_type")))
					&& ( couponInfo.i("course_id") == 0
						|| couponInfo.i("course_id") > 0 && itemInfo.i("course_id") == couponInfo.i("course_id"))
				) || ( "book".equals(itemInfo.s("product_type"))
					&& ("A".equals(couponInfo.s("coupon_type")) || "B".equals(couponInfo.s("coupon_type")))
//				) || ( "freepass".equals(itemInfo.s("product_type")) && "F".equals(couponInfo.s("coupon_type"))
				)) && (
					("course".equals(itemInfo.s("product_type")) && (itemInfo.i("c_price") * itemInfo.i("quantity"))  >= couponInfo.i("min_price"))
					|| ("book".equals(itemInfo.s("product_type")) && (itemInfo.i("book_price") * itemInfo.i("quantity")) >= couponInfo.i("min_price"))
//					|| ("freepass".equals(itemInfo.s("product_type")) && itemInfo.i("freepass_price") >= couponInfo.i("min_price"))
				);
	}
	
	/*
	** 할인금액
	** 정량(P) - 정가와 할인금액 비교하여 낮은금액으로 산출
	** 정률(R) - 할인율로 할인액을 산출한 후 할인액과 정가그리고 최대할인금액을 비교하여 낮은금액으로 산출 
	*/
	public int getDiscountPrice(DataSet couponInfo, DataSet itemInfo) {
		
		int dcPrice = 0;
		if("P".equals(couponInfo.s("disc_type"))) {
			dcPrice = itemInfo.i("price") < couponInfo.i("disc_value") ? itemInfo.i("price") : couponInfo.i("disc_value");
		} else if("R".equals(couponInfo.s("disc_type"))) {
			//int dcRate = couponInfo.i("disc_value") < 100 ? couponInfo.i("disc_value") : 100;
			//dcPrice = (int) Malgn.round((itemInfo.i("price") * dcRate / 100), -2); //100단위 절삭
			int dcRate = couponInfo.i("disc_value");
			dcPrice = (int) ((itemInfo.i("price") - itemInfo.i("disc_group_price")) * dcRate / 100);
			dcPrice = couponInfo.i("limit_price") > 0 && dcPrice > couponInfo.i("limit_price") ? couponInfo.i("limit_price") : dcPrice;
		}

		return dcPrice;
	}
}