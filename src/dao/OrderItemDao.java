package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class OrderItemDao extends DataObject {

	public String[] typeList = {"D=>수강신청", "G=>장바구니"};
	public String[] ptypes = {"course=>과정", "book=>교재", "freepass=>프리패스", "c_renew=>연장", "package=>패키지"};
	public String[] statusList = { "-99=>주문대기", "1=>결제완료", "2=>입금대기", "3=>환불요청", "-2=>결제취소" };

	public String[] typeListMsg = {"D=>list.order_item.type_list.D", "G=>list.order_item.type_list.G"};
	public String[] ptypesMsg = {"course=>list.order_item.ptypes_msg.course", "book=>list.order_item.ptypes_msg.book", "freepass=>list.order_item.ptypes_msg.freepass", "c_renew=>list.order_item.ptypes_msg.c_renew"};
	public String[] statusListMsg = { "-99=>list.order_item.status_list.-99", "1=>list.order_item.status_list.1", "2=>list.order_item.status_list.2", "3=>list.order_item.status_list.3", "-2=>list.order_item.status_list.-2" };

	public String[] items = null;
	public String productName = "";
	public String goCartMessage = "";
	public int groupDisc = 0; //그룹할인률
	public int courseNo = 0;
	public int price = 0;
	public int discPrice = 0;
	public int discGroupPrice = 0; //그룹할인합산금액
	public int couponPrice = 0;
	public int payPrice = 0;
	public int taxfreeTarget = 0;
	public boolean goCart = false;
	public boolean isDelivery = false;
	public boolean verifyDiscount = true;
	public boolean memoBlock = false;
	public boolean isUserLimit = false; //수강신청제한
	public DataSet courses = new DataSet();
	public DataSet renewCourses = new DataSet();
	public DataSet ebooks = new DataSet();
	public DataSet freepasses = new DataSet();
	public DataSet useFreepasses = new DataSet();
	public DataSet escrows = new DataSet();

	private int siteId = 0;

	public OrderItemDao() {
		this.table = "TB_ORDER_ITEM";
	}

	public OrderItemDao(int siteId) {
		this.table = "TB_ORDER_ITEM";
		this.siteId = siteId;
	}

	public void setSite(int siteId) {
		this.siteId = siteId;
	}

	public void setGroupDisc(int groupDisc) {
		this.groupDisc = groupDisc;
	}
	
	public boolean applyCoupon(int id, int couponPrice, int couponUserId) {
		boolean ret = true;
		this.item("coupon_user_id", couponUserId);
		this.item("coupon_price", couponPrice);
		this.item("pay_price", "" + couponPrice, "price - disc_group_price - ?");
		ret = this.update("id = " + id + "");

		if(ret) {
			if(-1 == this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'Y', use_date = '" + Malgn.time("yyyyMMddHHmmss") + "' WHERE id = " + couponUserId + "")) {
				this.item("coupon_user_id", 0);
				this.item("coupon_price", 0);
				this.item("pay_price", "0", "price - disc_group_price - ?");
				this.update("id = " + id + "");
				ret = false;
			}
		}
		return ret;
	}

	public boolean applyFreepass(int id, int freepassPrice, int freepassUserId) {
		boolean ret = true;
		this.item("freepass_user_id", freepassUserId);
		this.item("coupon_price", freepassPrice);
		this.item("pay_price", "" + freepassPrice, "price - disc_group_price - ?");
		ret = this.update("id = " + id + "");

		if(ret) {
			if(-1 == this.execute(
				" UPDATE " + new FreepassUserDao().table + " "
				+ " SET use_cnt = (SELECT COUNT(*) FROM " + this.table + " WHERE freepass_user_id = " + freepassUserId + ") "
				+ " WHERE id = " + freepassUserId + ""
			)) {
				this.item("freepass_user_id", 0);
				this.item("coupon_price", 0);
				this.item("pay_price", "0", "price - disc_group_price - ?");
				this.update("id = " + id + "");
				ret = false;
			}
		}
		return ret;
	}

	public boolean cancelCoupon(int id, int couponUserId) {
		/*
		boolean ret = -1 != this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'N', use_date = '' WHERE id = " + couponUserId +"");
		
		if(ret) {
			this.item("coupon_user_id", 0);
			this.item("coupon_price", 0);
			this.item("pay_price", "0", "price - ?");
			if(!this.update("id = " + id + "")) {
				this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'Y', use_date = '" + Malgn.time("yyyyMMddHHmmss") + "' WHERE id = " + couponUserId +"");
				ret = false;
			}	
		}
		return ret;
		*/
		return cancelDiscount(id, couponUserId);
	}

	public boolean cancelDiscount(int id, int couponUserId) {
		boolean ret = true;

		if(0 < couponUserId) ret = -1 != this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'N', use_date = '' WHERE id = " + couponUserId +"");

		this.clear();
		this.item("freepass_user_id", 0);
		this.item("coupon_user_id", 0);
		this.item("coupon_price", 0);
		this.item("pay_price", "0", "price - disc_group_price - ?");
		if(!this.update("id = " + id + "")) {
			if(0 < couponUserId) this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'Y', use_date = '" + Malgn.time("yyyyMMddHHmmss") + "' WHERE id = " + couponUserId +"");
			ret = false;
		}
		return ret;
	}

	public boolean deleteCartItem(int id, int couponUserId) {
		boolean ret = false;
		//if(this.delete("status IN (10,20) AND id = " + id + " ")) {

		this.clear();
		this.item("id", id);
		this.item("status", -1);
		if(this.update("status IN (10,20,-99) AND id = " + id + " ")) {
			if(couponUserId > 0) {
				this.execute("UPDATE " + new CouponUserDao().table + " SET use_yn = 'N', use_date = '' WHERE id = " + couponUserId +"");
			}
			ret = true;
		}
		return ret;
	}

	public DataSet getOrderItems(int userId, DataSet clist, int orderId) {
		DataSet list = new DataSet();
		if(0 == userId) return list;

		CourseDao course = new CourseDao();
		CourseUserDao courseUser = new CourseUserDao();
		BookDao book = new BookDao();
		FreepassDao freepass = new FreepassDao(siteId);
		FreepassUserDao freepassUser = new FreepassUserDao(siteId);

		CouponDao coupon = new CouponDao();
		CouponUserDao couponUser = new CouponUserDao();

		items = null;
		productName = "";
		goCartMessage = "";
		courseNo = 0;
		price = 0;
		discPrice = 0;
		discGroupPrice = 0;
		couponPrice = 0;
		payPrice = 0;
		taxfreeTarget = 0;
		goCart = false;
		isDelivery = false;
		verifyDiscount = true;
		memoBlock = false;
		courses = new DataSet();
		renewCourses = new DataSet();
		ebooks = new DataSet();
		freepasses = new DataSet();
		useFreepasses = new DataSet();
		escrows = new DataSet();
		String today = Malgn.time("yyyyMMdd");

		list = this.query(
			"SELECT a.*"
			+ ", c.id course_id, c.course_type, c.onoff_type, c.lesson_day, c.request_sdate, c.request_edate, c.step, c.course_nm, c.category_id course_category_id "
			+ ", c.study_sdate, c.study_edate, c.auto_approve_yn, c.limit_people_yn, c.limit_people, c.disc_group_yn course_disc_group_yn "
			+ ", c.class_member, c.credit, c.close_yn, c.sale_yn, c.price c_price, c.taxfree_yn c_taxfree_yn, c.memo_yn c_memo_yn "
			+ ", cr.id renew_course_id, cr.course_nm renew_course_nm, cr.lesson_day renew_lesson_day, cr.renew_price, cr.taxfree_yn cr_taxfree_yn, cr.renew_max_cnt, cr.renew_yn, cr.disc_group_yn renew_disc_group_yn "
			+ ", b.id book_id, b.book_type, b.book_nm, b.taxfree_yn, b.book_price, b.delivery_type, b.delivery_price, b.rental_day, b.disc_group_yn book_disc_group_yn "
			+ ", pf.id product_freepass_id, pf.freepass_nm, pf.price freepass_price, pf.freepass_day, pf.limit_cnt, pf.disc_group_yn freepass_disc_group_yn "
			+ ", p.coupon_type, p.disc_type, p.disc_value, p.min_price, p.limit_price "
			+ ", p.start_date coupon_sdate, p.end_date coupon_edate "
			+ ", p.course_id coupon_course_id "
			+ ", pu.use_yn coupon_user_yn, pu.use_date coupon_use_date "
			+ ", fu.freepass_id, fu.user_id fu_user_id, fu.limit_cnt freepass_limit_cnt, fu.use_cnt freepass_use_cnt, fu.start_date freepass_sdate, fu.end_date freepass_edate "
			+ " FROM " + this.table + " a "
			+ " LEFT JOIN " + course.table + " c ON a.product_type = 'course' AND a.product_id = c.id AND c.status = 1 "
			+ " LEFT JOIN " + course.table + " cr ON a.product_type = 'c_renew' AND a.product_id = cr.id AND cr.status = 1 "
			+ " LEFT JOIN " + book.table + " b ON a.product_type = 'book' AND a.product_id = b.id AND b.sale_yn = 'Y' AND b.status = 1 "
			+ " LEFT JOIN " + freepass.table + " pf ON a.product_type = 'freepass' AND a.product_id = pf.id AND pf.status = 1 "
			+ " LEFT JOIN " + freepassUser.table + " fu ON a.product_type = 'course' AND a.freepass_user_id = fu.id AND fu.status = 1 "
			+ " LEFT JOIN " + couponUser.table + " pu ON a.coupon_user_id = pu.id AND pu.user_id = " + userId + " "
			+ " LEFT JOIN " + coupon.table + " p ON pu.coupon_id = p.id "
			//+ " WHERE a.user_id = " + userId + " AND a.order_id = -99 AND a.status = 20 "
			+ " WHERE a.user_id = " + userId + " AND a.status IN (-99, 20) AND a.order_id = " + orderId
			+ " ORDER BY a.id ASC "
		);
		items = new String[list.size()];
		while(list.next()) {
			if(list.i("__ord") == 1) productName = list.s("product_nm");
			list.put("__idx", list.i("__ord") - 1);
			list.put("course_block", false);
			list.put("use_block", true);
			list.put("unit_price_conv", Malgn.nf(list.i("unit_price")));
			list.put("quantity_conv", Malgn.nf(list.i("quantity")));
			list.put("price_conv", Malgn.nf(list.i("price")));
			list.put("disc_price_conv", Malgn.nf(list.i("disc_price")));
			list.put("disc_group_price_conv", Malgn.nf(list.i("disc_group_price")));
			list.put("pay_price_conv", Malgn.nf(list.i("pay_price")));
			list.put("product_type_conv", Malgn.getItem(list.s("product_type"), this.ptypes));
			price += list.i("price");
			discPrice += list.i("disc_price");
			discGroupPrice += list.i("disc_group_price");
			couponPrice += list.i("coupon_price");
			payPrice += list.i("pay_price");

			list.put("ek", Malgn.encrypt(list.s("id") + userId));
			list.put("discount_block", !"freepass".equals(list.s("product_type")) && !"c_renew".equals(list.s("product_type")) && 0 < list.i("price"));
			list.put("discount_apply_block", list.i("coupon_user_id") > 0 || list.i("freepass_user_id") > 0);
			list.put("discount_group_block", 0 < list.i("disc_group_price"));
			list.put("coupon_price_conv", Malgn.nf(list.i("coupon_price")));

			list.put("end_date", "");
			list.put("renew_cnt", "");
		
			items[list.i("__idx")] = list.s("id");

			if("course".equals(list.s("product_type"))) {
				if(list.b("c_taxfree_yn")) taxfreeTarget += list.i("pay_price");

				list.put("course_no", ++courseNo);
				list.put("course_block", true);

				list.put("request_date", "-");
				if("R".equals(list.s("course_type"))) {
					list.put("request_date", Malgn.time("yyyy.MM.dd", list.s("request_sdate")) + " - " + Malgn.time("yyyy.MM.dd", list.s("request_edate")));

					//삭제-기간이 지난 경우/금액틀림
					if(	0 > Malgn.diffDate("D", list.s("request_sdate"), today)
						|| 0 > Malgn.diffDate("D", today, list.s("request_edate"))
						|| list.b("close_yn")
						|| list.i("price") != list.i("c_price")
					) {
						this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
						goCart = true;
						goCartMessage = "alert.course.noperiod_or_price";
					}

				} else if("A".equals(list.s("course_type"))) {
					list.put("request_date", "상시");

					//삭제-금액틀림
					if(list.i("price") != list.i("c_price") || list.b("close_yn")) {
						this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
						goCart = true;
						goCartMessage = "alert.order_item.change_price";
					}
				}

				//삭제-판매마감
				if(!list.b("sale_yn")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.course.closed";
				}
				
				//삭제-그룹할인금액검사
				if(list.b("course_disc_group_yn") && 0 < this.groupDisc) {
					int discGroupPrice = list.i("price") * this.groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
					if(discGroupPrice != list.i("disc_group_price")) {
						goCart = true;
						goCartMessage = "alert.order_item.canceled_by_group_disc";
					}
				} else if(0 < list.i("disc_group_price")) {
					goCart = true;
					goCartMessage = "alert.order_item.canceled_by_group_disc";
				}
				
				//주문메모
				if(list.b("c_memo_yn")) {
					memoBlock = true;
				}

				//제한-최대수강수검사
				if(list.b("limit_people_yn")) {
					int userCnt = courseUser.findCount("course_id = " + list.i("course_id") + " AND status NOT IN (-1, -4)");
//					int orderItemCnt = this.findCount("course_id = " + list.i("course_id") + " AND status = 20 AND user_id != " + userId);
					int limitCnt = list.i("limit_people");
//					if((userCnt + orderItemCnt) >= limitCnt) {
					if(userCnt >= limitCnt) {
						this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
						goCart = true;
						goCartMessage = "alert.course.noquantity";
						isUserLimit = true;
					}
				}

				courses.addRow(list.getRow());
			} else if("c_renew".equals(list.s("product_type"))) {
				if(list.b("cr_taxfree_yn")) taxfreeTarget += list.i("pay_price");

				DataSet cuinfo = courseUser.find("id = " + list.i("renew_id") + " AND site_id = " + siteId + " AND status IN (1, 3)");
				if(!cuinfo.next()) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.course_user.noextend";
				}

				list.put("course_renew_block", true);

				//삭제-연장입금대기있음
				if(0 < this.findCount("renew_id = " + cuinfo.i("id") + " AND status = 2")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.order_item.extend_progress";
				}

				//삭제-금액틀림
				if(list.i("price") != list.i("renew_price") || list.b("close_yn")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.order_item.change_price";
				}

				//삭제-연장판매안함
				if(!list.b("renew_yn")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.course.noextend";
				}

				//삭제-연장횟수초과
				if(0 < list.i("renew_max_cnt") && list.i("renew_max_cnt") <= cuinfo.i("renew_cnt")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.course.over_extend";
				}

				//삭제-결제기간초과
				if(0 > Malgn.diffDate("D", today, cuinfo.s("end_date"))) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.course.noextendperiod";
				}
				
				//삭제-그룹할인금액검사
				if(list.b("renew_disc_group_yn") && 0 < this.groupDisc) {
					int discGroupPrice = list.i("price") * this.groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
					if(discGroupPrice != list.i("disc_group_price")) {
						goCart = true;
						goCartMessage = "alert.order_item.canceled_by_group_disc";
					}
				} else if(0 < list.i("disc_group_price")) {
					goCart = true;
					goCartMessage = "alert.order_item.canceled_by_group_disc";
				}
				
				//연장기간산정
				list.put("end_date", cuinfo.s("end_date"));
				list.put("renew_cnt", cuinfo.s("renew_cnt"));

				renewCourses.addRow(list.getRow());
			} else if("book".equals(list.s("product_type"))) {
				if(list.b("taxfree_yn")) taxfreeTarget += list.i("pay_price");

				//삭제-금액틀림
				if(list.i("unit_price") != list.i("book_price")) {
					this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.order_item.change_price";
				}
				
				//삭제-그룹할인금액검사
				if(list.b("book_disc_group_yn") && 0 < this.groupDisc) {
					int discGroupPrice = list.i("price") * this.groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
					if(discGroupPrice != list.i("disc_group_price")) {
						goCart = true;
						goCartMessage = "alert.order_item.canceled_by_group_disc";
					}
				} else if(0 < list.i("disc_group_price")) {
					goCart = true;
					goCartMessage = "alert.order_item.canceled_by_group_disc";
				}
				
				if("R".equals(list.s("book_type"))) {
					isDelivery = true;
					memoBlock = true;
					escrows.addRow(list.getRow());
				} else {
					ebooks.addRow(list.getRow());
				}
			} else if("freepass".equals(list.s("product_type"))) {
				//삭제-금액틀림
				if(list.i("unit_price") != list.i("freepass_price")) {
					//this.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
					goCart = true;
					goCartMessage = "alert.order_item.change_price";
				}
				
				//삭제-그룹할인금액검사
				if(list.b("freepass_disc_group_yn") && 0 < this.groupDisc) {
					int discGroupPrice = list.i("price") * this.groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
					if(discGroupPrice != list.i("disc_group_price")) {
						goCart = true;
						goCartMessage = "alert.order_item.canceled_by_group_disc";
					}
				} else if(0 < list.i("disc_group_price")) {
					goCart = true;
					goCartMessage = "alert.order_item.canceled_by_group_disc";
				}
				
				freepasses.addRow(list.getRow());
			}

			//검증-쿠폰,프리패스
			DataSet temp = new DataSet();
			if(list.i("coupon_user_id") > 0) {
				DataSet ctemp = new DataSet(); ctemp.addRow();
				ctemp.put("start_date", list.s("coupon_sdate"));
				ctemp.put("end_date", list.s("coupon_edate"));
				ctemp.put("coupon_type", list.s("coupon_type"));
				ctemp.put("course_id", list.s("coupon_course_id"));
				ctemp.put("min_price", list.s("min_price"));

				if(!couponUser.isValid(ctemp, list)) {
					if(!this.cancelDiscount(list.i("id"), list.i("coupon_user_id"))) { }
					verifyDiscount = false;
				}
			} else if(list.i("freepass_user_id") > 0) {
				//+ ", fu.freepass_id, fu.limit_cnt freepass_limit_cnt, fu.use_cnt freepass_use_cnt, fu.start_date freepass_sdate, fu.end_date freepass_edate "

				DataSet ftemp = new DataSet(); ftemp.addRow();
				ftemp.put("freepass_id", list.s("freepass_id"));
				ftemp.put("user_id", list.s("fu_user_id"));
				ftemp.put("start_date", list.s("freepass_sdate"));
				ftemp.put("end_date", list.s("freepass_edate"));
				ftemp.put("limit_cnt", list.s("freepass_limit_cnt"));
				ftemp.put("use_cnt", list.s("freepass_use_cnt"));

				if(!freepassUser.isValid(ftemp, list)) {
					if(!this.cancelDiscount(list.i("id"), list.i("coupon_user_id"))) { }
					verifyDiscount = false;
				}

				useFreepasses.addRow(list.getRow());
			} else if(null != clist) {
				clist.first();
				while(clist.next()) {
					if(couponUser.isValid(clist, list)) temp.addRow(clist.getRow());
				}
				list.put(".sub", temp);
			}

		}

		return list;
	}
}