package dao;

import java.net.HttpURLConnection;
import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;
import java.sql.*;
import malgnsoft.db.*;
import malgnsoft.util.*;

public class OrderDao extends DataObject {

	public String[] statusList = { "-99=>주문대기", "1=>결제완료", "2=>입금대기", "-2=>결제취소", "3=>부분환불", "4=>전액환불" };
	public String[] deliveryStatusList = { "0=>배송대기", "2=>배송준비중", "3=>배송중", "4=>배송완료", "1=>구매확정" };
	public String[] deliveryTypeList = { "A=>착불", "B=>선불", "N=>배송안함" };
	public String[] deliveryTypeList2 = { "A=>착불", "B=>선불" };
	public String[] methods = { "01=>신용카드", "02=>실시간이체", "03=>가상계좌", "04=>휴대폰결제", "05=>해외카드", "10=>Payment via Pay-Gate", "90=>자체계좌", "91=>여민동락" , "99=>무과금" };
	
	public String[] statusListMsg = { "-99=>list.order.status_list.-99", "1=>list.order.status_list.1", "2=>list.order.status_list.2", "-2=>list.order.status_list.-2", "3=>list.order.status_list.3", "4=>list.order.status_list.4" };
	public String[] deliveryStatusListMsg = { "0=>list.order.delivery_status_list.0", "2=>list.order.delivery_status_list.2", "3=>list.order.delivery_status_list.3", "4=>list.order.delivery_status_list.4", "1=>list.order.delivery_status_list.1" };
	public String[] deliveryTypeListMsg = { "A=>list.order.delivery_type_list.A", "B=>list.order.delivery_type_list.B", "N=>list.order.delivery_type_list.N" };
	public String[] deliveryTypeList2Msg = { "A=>list.order.delivery_type_list2.A", "B=>list.order.delivery_type_list2.B" };
	public String[] methodsMsg = { "01=>list.order.methods.01", "02=>list.order.methods.02", "03=>list.order.methods.03", "04=>list.order.methods.04", "05=>list.order.methods.05", "10=>list.order.methods.10", "90=>list.order.methods.90", "91=>list.order.methods.91" , "99=>list.order.methods.99" };

	public String errorCode = "";
	public int failedCourseId = 0;
	private int siteId = 0;

	private Message message;

	public OrderDao() {
		this.table = "TB_ORDER";
	}

	public OrderDao(int sid) {
		this.table = "TB_ORDER";
		this.siteId = sid;
	}

	public void setMessage(Message msg) {
		this.message = msg;
	}

	public String getOrderEk(int oid, int userId) {
		return Malgn.encrypt(oid + userId + "__LMS2014");
	}

	public String[] getDeliveryInfo(DataSet list) {
		int deliveryPrice = 100000000;
		String deliveryType = "A";

		list.first();
		while(list.next()) {
			//가장 낮은 배송료 책정, 선불이 하나라도 있으면 선불배송
			if("B".equals(list.s("delivery_type")) && deliveryPrice > list.i("delivery_price")) {
				deliveryPrice = list.i("delivery_price");
				deliveryType = "B";
			}
		}
		if(deliveryPrice == 100000000) deliveryPrice = 0;
		return new String[] {deliveryType, "" + deliveryPrice};
	}

	public boolean process(int oid) throws Exception {
		if(oid < 1) return false;

		//객체
		Malgn m = new Malgn();
		UserDao user = new UserDao();
		
		CourseDao course = new CourseDao();
		CourseUserDao courseUser = new CourseUserDao();
		CourseRenewDao courseRenew = new CourseRenewDao();
		CoursePackageDao coursePackage = new CoursePackageDao();
		
		BookDao book = new BookDao();
		BookUserDao bookUser = new BookUserDao();
		BookPackageDao bookPackage = new BookPackageDao();

		FreepassDao freepass = new FreepassDao();
		FreepassUserDao freepassUser = new FreepassUserDao();

		TutorDao tutor = new TutorDao();
		CourseTutorDao courseTutor = new CourseTutorDao();

		OrderItemDao orderItem = new OrderItemDao();
		PaymentDao payment = new PaymentDao();

		//변수
		String today = m.time("yyyyMMdd");
		boolean isDBOK = true;

		//정보=주문
		DataSet info = this.find("id = " + oid + " AND status IN (1, 2)");
		if(!info.next()) {
			errorCode = "[ERR01] 주문 정보가 없습니다.<br />\n";
			return false;
		}

		int status = info.i("status");

		DataSet courses = new DataSet();
		DataSet renewCourses = new DataSet();
		DataSet books = new DataSet();
		DataSet freepasses = new DataSet();

		DataSet items = orderItem.query(
			"SELECT a.*"
			+ ", c.id course_id, c.course_type, c.onoff_type, c.lesson_day, c.lesson_day renew_lesson_day, c.request_sdate, c.request_edate, c.step "
			+ ", c.study_sdate, c.study_edate, c.auto_approve_yn, c.class_member, c.credit, c.limit_people_yn, c.limit_people "
			+ ", b.id book_id, b.book_type, b.rental_day "
			+ ", f.id freepass_id, f.freepass_nm, f.price freepass_price, f.freepass_day "
			+ ", fu.end_date freepass_end_date "
			+ " FROM " + orderItem.table + " a "
			+ " LEFT JOIN " + course.table + " c ON a.product_id = c.id AND a.product_type IN ('course', 'c_renew') "
			+ " LEFT JOIN " + book.table + " b ON a.product_id = b.id AND a.product_type = 'book' "
			+ " LEFT JOIN " + freepass.table + " f ON a.product_id = f.id AND a.product_type = 'freepass' "
			+ " LEFT JOIN " + freepassUser.table + " fu ON a.freepass_user_id = fu.id "
			+ " WHERE a.order_id = " + oid
			+ " ORDER BY a.id ASC "
		);

		while(items.next()) {
			if("course".equals(items.s("product_type"))) {
				courses.addRow(items.getRow());
			} else if("c_renew".equals(items.s("product_type"))) {
				if(status == 1) renewCourses.addRow(items.getRow());
			} else if("book".equals(items.s("product_type"))) {
				if(!"R".equals(items.s("book_type"))) books.addRow(items.getRow());
			} else if("freepass".equals(items.s("product_type"))) {
				freepasses.addRow(items.getRow());
			}
		}

		//수강정보갱신
		courses.sort("limit_people_yn");
		courses.first();
		while(courses.next()) {
			boolean isPackage = "P".equals(courses.s("onoff_type"));
			String courseField = !isPackage ? "course_id" : "package_id";
			if(!courses.b("auto_approve_yn")) status = 0;
			int orderItemId = courses.i("id");

			//수강신청
			courses.put("id", courses.i("course_id"));
			if(!isPackage) {
				courses.put("order_item_id", orderItemId);
				courses.put("order_id", oid);
//				if(!courseUser.addUser(courses, info.i("user_id"), status)) {
//					errorCode += "[ERR33] 과정을 신청하는 중 오류가 발생했습니다.<br />\n";
//					isDBOK = false;
//				}
				if(!courseUser.addUser(courses, info.i("user_id"), status)) {
					failedCourseId = courses.i(courseField);
					return false;
				}
			} else {
				DataSet sub = coursePackage.getCourses(courses.i("id"));
				while(sub.next()) {
					sub.put("order_item_id", orderItemId);
					sub.put("order_id", oid);
					sub.put("freepass_end_date", courses.s("freepass_end_date"));
					if(!courseUser.addUser(sub, info.i("user_id"), status, courses)) {
						errorCode += "[ERR33-1] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
						isDBOK = false;
					}
				}
			}
		} // courseUser

		//수강기간연장
		renewCourses.first();
		while(renewCourses.next()) {
			DataSet cuinfo = courseUser.find("id = " + renewCourses.i("renew_id") + " AND status IN (1, 3)");
			if(!cuinfo.next()) {
				errorCode += "[ERR-CRN1] 연장처리를 위한 수강 정보가 없습니다.\nid = " + renewCourses.i("renew_id") + " AND status IN (1, 3)\n";
				isDBOK = false;
			}

			if(0 == courseRenew.findCount("site_id = " + renewCourses.i("site_id") + " AND order_item_id = " + renewCourses.i("id"))) {
				renewCourses.put("end_date", cuinfo.s("end_date"));
				renewCourses.put("renew_cnt", cuinfo.s("renew_cnt"));
				String renewEndDate = courseUser.renewStudyDate(renewCourses.getRow());

				if("".equals(renewEndDate)) {
					errorCode += "[ERR-CRN2] 연장 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
					isDBOK = false;
				} else {
					courseRenew.item("site_id", cuinfo.i("site_id"));
					courseRenew.item("course_user_id", cuinfo.i("id"));
					courseRenew.item("renew_type", "R");
					courseRenew.item("start_date", cuinfo.s("start_date"));
					courseRenew.item("end_date", renewEndDate);
					courseRenew.item("user_id", cuinfo.i("user_id"));
					courseRenew.item("order_item_id", renewCourses.i("id"));
					courseRenew.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
					courseRenew.item("status", 1);
					if(!courseRenew.insert()) {
						errorCode += "[ERR-CRN3] 연장 정보를 등록하는 중 오류가 발생했습니다.<br />\n";
						isDBOK = false;
					}
				}
			}
		} //renewCourses

		//대여정보갱신
		books.first();
		while(books.next()) {
			boolean isPackage = "P".equals(books.s("book_type"));
			String courseField = !isPackage ? "book_id" : "package_id";
			int orderItemId = books.i("id");

			//대여신청
			books.put("id", books.i("book_id"));
			if(!isPackage) {
				books.put("order_item_id", orderItemId);
				books.put("order_id", oid);
				if(!bookUser.addUser(books, info.i("user_id"), status)) {
					errorCode += "[ERR53] 대여하는 중 오류가 발생했습니다.<br />\n";
					isDBOK = false;
				}
			} else {
				DataSet sub = bookPackage.getBooks(books.i("id"));
				while(sub.next()) {
					sub.put("order_item_id", orderItemId);
					sub.put("order_id", oid);
					if(!bookUser.addUser(sub, info.i("user_id"), status, books.i("id"))) {
						errorCode += "[ERR54] 패키지를 신청하는 중 오류가 발생했습니다.<br />\n";
						isDBOK = false;
					}
				}
			}
		}

		//프리패스정보갱신
		freepasses.first();
		while(freepasses.next()) {
			int orderItemId = freepasses.i("id");

			//프리패스신청
			freepasses.put("id", freepasses.i("freepass_id"));
			freepasses.put("order_item_id", orderItemId);
			freepasses.put("order_id", oid);
			if(!freepassUser.addUser(freepasses, info.i("user_id"), status)) {
				errorCode += "[ERR-F2] 프리패스를 신청하는 중 오류가 발생했습니다.<br />\n";
				isDBOK = false;
			}
		} // freepassUser

		if(!isDBOK) {
			StringBuffer sb = new StringBuffer();
			sb.append("오류코드:" + errorCode + "<br>");
			sb.append("OID:" + oid + "<br>");
			m.mail("yhs@malgnsoft.com", "주문처리하는 중 오류가 발생하였습니다.", sb.toString());
		}

		return true;
	}

	//주문처리 중 오류가 발생할 경우 결제취소 상태로 변경
	public boolean rollback(int oid, DataSet orderItems) {
		OrderItemDao orderItem = new OrderItemDao();
		CourseUserDao courseUser = new CourseUserDao();

		DataSet courses = new DataSet();

		orderItems.first();
		while(orderItems.next()) {
			orderItem.item("status", ("course".equals(orderItems.s("product_type")) && orderItems.i("product_id") == failedCourseId) ? -2 : 10); //주문항목 중 과정입과 실패한 항목은 결제취소 아닌 경우 장바구니로 이동
			orderItem.update("id = " + orderItems.i("id") + "");

			if("course".equals(orderItems.s("product_type"))) courses.addRow(orderItems.getRow());
		}

		//수강생 삭제 처리
		courses.first();
		while(courses.next()) {
			courseUser.item("status", -1);
			courseUser.item("change_date", Malgn.time("yyyyMMddHHmmss"));
			courseUser.update("course_id = " + courses.i("course_id") + " AND user_id = " + courses.i("user_id") + " AND order_item_id = " + courses.i("id"));
		}

		this.item("status", -2); //주문 결제취소

		return this.update("id = " + oid + "");
	}

	public boolean confirmDeposit(String oid, DataSet siteinfo) throws Exception {
		return this.confirmDeposit(oid, siteinfo, null);
	}

	public boolean confirmDeposit(String oid, DataSet siteinfo, DataSet pinfo) throws Exception {
		if("".equals(oid) || null == oid || null == siteinfo) return false;
		if(null == pinfo) {
			pinfo = new DataSet();
			pinfo.addRow();
		}

		//객체
		Malgn m = new Malgn();
		Page p = new Page();
		//Page p = new Page(siteinfo.s("doc_root") + "/html");
		//p.setRoot(siteinfo.s("doc_root") + "/html");
		//p.setLayout("mail");
		//p.setVar("SITE_INFO", siteinfo);
		
		CourseDao course = new CourseDao();
		CourseUserDao courseUser = new CourseUserDao();
		CourseRenewDao courseRenew = new CourseRenewDao();
		CoursePackageDao coursePackage = new CoursePackageDao();
		
		BookDao book = new BookDao();
		BookUserDao bookUser = new BookUserDao();
		BookPackageDao bookPackage = new BookPackageDao();

		FreepassDao freepass = new FreepassDao();
		FreepassUserDao freepassUser = new FreepassUserDao();

		TutorDao tutor = new TutorDao();
		CourseTutorDao courseTutor = new CourseTutorDao();

		OrderItemDao orderItem = new OrderItemDao();
		PaymentDao payment = new PaymentDao();

		UserDao user = new UserDao();
		MailDao mail = new MailDao();
		SmsTemplateDao smsTemplate = new SmsTemplateDao(siteinfo.i("id"));

		//변수
		String errorCode = "";
		String today = m.time("yyyyMMdd");
		String now = m.time("yyyyMMddHHmmss");
		int siteId = siteinfo.i("id");
		boolean isDBOK = true;

		//정보=주문
		DataSet info = this.find("id = " + oid);
		DataSet items = new DataSet();
		if(!info.next()) {
			errorCode += "[ERR01] 주문 정보가 없습니다.<br />\n";
			isDBOK = false;
		} else {

			this.item("pay_date", now);
			this.item("status", 1);
			if(!this.update("id = " + oid)) {
				errorCode += "[ERR02] 입금 정보를 주문에 등록하는 중 오류가 발생했습니다.<br />\n";
				isDBOK = false;
			} else {
				orderItem.item("status", 1); // 무통장입금은 2
				if(!orderItem.update("order_id = " + oid)) {
					errorCode += "[ERR03] 입금 정보를 주문 항목에 등록하는 중 오류가 발생했습니다.<br />\n";
					isDBOK = false;
				} else {

					DataSet courses = new DataSet();
					DataSet renewCourses = new DataSet();
					DataSet books = new DataSet();
					DataSet freepasses = new DataSet();

					items = orderItem.query(
						"SELECT a.*"
						+ ", c.id course_id, c.course_type, c.onoff_type, c.lesson_day, c.request_sdate, c.request_edate, c.step "
						+ ", c.study_sdate, c.study_edate, c.auto_approve_yn, c.class_member, c.credit "
						+ ", cr.id renew_course_id, cr.course_nm renew_course_nm, cr.lesson_day renew_lesson_day, cr.renew_price, cr.renew_max_cnt, cr.renew_yn "
						+ ", b.id book_id, b.book_type, b.rental_day "
						+ ", f.id freepass_id, f.freepass_nm, f.price freepass_price, f.freepass_day "
						+ ", IFNULL(cu.id, cup.id) course_user_id, COUNT(cup.id) course_package_cnt "
						+ ", IFNULL(bu.id, bup.id) book_user_id, COUNT(bup.id) book_package_cnt "
						+ ", fu.id freepass_user_id "
						+ ", fucp.end_date freepass_end_date "
						+ " FROM " + orderItem.table + " a "
						+ " LEFT JOIN " + course.table + " c ON a.product_id = c.id AND a.product_type = 'course' "
						+ " LEFT JOIN " + course.table + " cr ON a.product_type = 'c_renew' AND a.product_id = cr.id "
						+ " LEFT JOIN " + courseUser.table + " cu ON a.product_id = cu.course_id AND a.id = cu.order_item_id "
						+ " LEFT JOIN " + courseUser.table + " cup ON a.product_id = cup.package_id AND a.id = cup.order_item_id "
						+ " LEFT JOIN " + book.table + " b ON a.product_id = b.id AND a.product_type = 'book' "
						+ " LEFT JOIN " + bookUser.table + " bu ON a.product_id = bu.book_id AND a.id = bu.order_item_id "
						+ " LEFT JOIN " + bookUser.table + " bup ON a.product_id = bup.package_id AND a.id = bup.order_item_id "
						+ " LEFT JOIN " + freepass.table + " f ON a.product_id = f.id AND a.product_type = 'freepass' "
						+ " LEFT JOIN " + freepassUser.table + " fu ON a.product_id = fu.freepass_id AND a.id = fu.order_item_id "
						+ " LEFT JOIN " + freepassUser.table + " fucp ON a.freepass_user_id = fucp.id "
						+ " WHERE a.order_id = " + oid // + " AND a.product_type = 'course' "
						+ " GROUP BY a.product_id "
						+ " ORDER BY a.id ASC "
					);

					while(items.next()) {
						items.put("quantity_conv", m.nf(items.i("quantity")));
						items.put("pay_price_conv", m.nf(items.i("pay_price")));

						if("course".equals(items.s("product_type"))) {
							courses.addRow(items.getRow());
						} else if("c_renew".equals(items.s("product_type"))) {
							renewCourses.addRow(items.getRow());
						} else if("book".equals(items.s("product_type"))) {
							if(!"R".equals(items.s("book_type"))) books.addRow(items.getRow());
						} else if("freepass".equals(items.s("product_type"))) {
							freepasses.addRow(items.getRow());
						}
					}

					//수강정보갱신
					courses.first();
					while(courses.next()) {
						boolean isPackage = "P".equals(courses.s("onoff_type"));
						String courseField = !isPackage ? "course_id" : "package_id";
						int status = courses.b("auto_approve_yn") ? 1 : 0;
						int orderItemId = courses.i("id");

						if(0 < courses.i("course_user_id")) {
							if(!isPackage) {
								if(!courseUser.updateStudyDate(courses.getRow(), status, "D")) {
									//if(!courseUser.delete("order_id = " + oid)) { }
									errorCode += "[ERR31] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							} else {
								try {
									DataSet sub = courseUser.query(
											" SELECT a.id course_user_id, a.user_id, a.order_id, a.order_item_id, c.* "
													+ " FROM " + courseUser.table + " a "
													+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
													+ " WHERE a.order_item_id = " + courses.s("id") + " AND a.package_id = " + courses.s("product_id")
									);
									if (1 > sub.size() || sub == null) {
										errorCode += "[ERR31-1] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
										isDBOK = false;
									}
									if(null == sub) throw new NullPointerException();
									while (sub.next()) {
										sub.put("lesson_day", courses.i("lesson_day"));
										sub.put("freepass_end_date", courses.s("freepass_end_date"));
									}
									if (!courseUser.updateStudyDate(sub, status, "D")) {
										//if(!courseUser.delete("order_id = " + oid)) { }
										errorCode += "[ERR32] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
										isDBOK = false;
									}
								} catch (NullPointerException npe) {
									Malgn.errorLog("NullPointerException : OrderDao.confirmDeposit() : " + npe.getMessage(), npe);
									errorCode += "[ERR31-2] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							}

						} else {
							//수강신청
							courses.put("id", courses.i("course_id"));
							if(!isPackage) {
								courses.put("order_item_id", orderItemId);
								courses.put("order_id", oid);
								if(!courseUser.addUser(courses, info.i("user_id"), status)) {
									//if(!courseUser.delete("order_id = " + oid)) { }
									errorCode += "[ERR33] 과정을 신청하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							} else {
								DataSet sub = coursePackage.query(
									"SELECT a.*, c.* "
									+ " FROM " + coursePackage.table + " a "
									+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
										+ " AND c.onoff_type != 'P' AND c.status = 1 "
									+ " WHERE a.package_id = " + courses.s("id") + " "
									+ " ORDER BY a.sort ASC"
								);
								if(!sub.next()) {
									errorCode += "[ERR33-1] 과정 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
								//DataSet sub = coursePackage.getCourses(courses.i("id"));
								while(sub.next()) {
									sub.put("order_item_id", orderItemId);
									sub.put("order_id", oid);
									sub.put("freepass_end_date", courses.s("freepass_end_date"));
									//if(!courseUser.addUser(sub, info.i("user_id"), status, courses.i("id"))) {
									if(!courseUser.addUser(sub, info.i("user_id"), status, courses)) {
										//if(!courseUser.delete("order_id = " + oid)) { }
										errorCode += "[ERR34] 패키지 과정을 신청하는 중 오류가 발생했습니다.<br />\n";
										isDBOK = false;
									}
								}
							}
						}

					} // courseUser
					
					//수강기간연장
					renewCourses.first();
					while(renewCourses.next()) {
						DataSet cuinfo = courseUser.find("id = " + renewCourses.i("renew_id") + " AND site_id = " + siteId + " AND status IN (1, 3)");
						if(!cuinfo.next()) {
							errorCode += "[ERR-CRN1] 연장처리를 위한 수강 정보가 없습니다.";
							isDBOK = false;
						}
						
						if(0 == courseRenew.findCount("site_id = " + renewCourses.i("site_id") + " AND order_item_id = " + renewCourses.i("id"))) {
							renewCourses.put("end_date", cuinfo.s("end_date"));
							renewCourses.put("renew_cnt", cuinfo.s("renew_cnt"));
							String renewEndDate = courseUser.renewStudyDate(renewCourses.getRow());

							if("".equals(renewEndDate)) {
								errorCode += "[ERR-CRN2] 연장 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
								isDBOK = false;
							} else {
								courseRenew.item("site_id", cuinfo.i("site_id"));
								courseRenew.item("course_user_id", cuinfo.i("id"));
								courseRenew.item("renew_type", "R");
								courseRenew.item("start_date", cuinfo.s("start_date"));
								courseRenew.item("end_date", renewEndDate);
								courseRenew.item("user_id", cuinfo.i("user_id"));
								courseRenew.item("order_item_id", renewCourses.i("id"));
								courseRenew.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
								courseRenew.item("status", 1);
								if(!courseRenew.insert()) {
									errorCode += "[ERR-CRN3] 연장 정보를 등록하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							}
						}
					}

					//대여정보갱신
					books.first();
					while(books.next()) {
						boolean isPackage = "P".equals(books.s("book_type"));
						String courseField = !isPackage ? "book_id" : "package_id";
						int orderItemId = books.i("id");

						if(0 < books.i("book_user_id")) {
							if(!isPackage) {
								if(!bookUser.updateRentalDate(books.getRow(), 1)) {
									//if(!bookUser.delete("order_id = " + oid)) { }
									errorCode += "[ERR51] 대여 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							} else {
								DataSet sub = bookUser.query(
									" SELECT a.id book_user_id, a.order_id, a.order_item_id, b.* "
									+ " FROM " + bookUser.table + " a "
									+ " LEFT JOIN " + book.table + " b ON a.book_id = b.id AND b.site_id = " + siteId + " "
									+ " WHERE a.order_item_id = " + books.s("id") + " AND a.package_id = " + books.s("product_id")
								);
								if(!bookUser.updateRentalDate(sub, 1)) {
									//if(!bookUser.delete("order_id = " + oid)) { }
									errorCode += "[ERR52] 대여 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							}

						} else {
							//대여신청
							books.put("id", books.i("book_id"));
							if(!isPackage) {
								books.put("order_item_id", orderItemId);
								books.put("order_id", oid);
								if(!bookUser.addUser(books, info.i("user_id"), 1)) {
									//if(!bookUser.delete("order_id = " + oid)) { }
									errorCode += "[ERR53] 대여하는 중 오류가 발생했습니다.<br />\n";
									isDBOK = false;
								}
							} else {
								DataSet sub = bookPackage.query(
									"SELECT a.*, b.* "
									+ " FROM " + bookPackage.table + " a "
									+ " INNER JOIN " + book.table + " b ON a.book_id = b.id AND b.site_id = " + siteId + " AND b.book_type != 'P' AND b.status = 1 "
									+ " WHERE a.package_id = " + books.s("id") + " "
									+ " ORDER BY a.sort ASC"
								);
								//DataSet sub = bookPackage.getBooks(books.i("id"));
								while(sub.next()) {
									sub.put("order_item_id", orderItemId);
									sub.put("order_id", oid);
									if(!bookUser.addUser(sub, info.i("user_id"), 1, books.i("id"))) {
										//if(!bookUser.delete("order_id = " + oid)) { }
										errorCode += "[ERR54] 패키지를 신청하는 중 오류가 발생했습니다.<br />\n";
										isDBOK = false;
									}
								}
							}
						}

					} // bookUser

					//프리패스정보갱신
					freepasses.first();
					while(freepasses.next()) {
						int orderItemId = books.i("id");

						if(0 < freepasses.i("freepass_user_id")) {
							if(!freepassUser.updateDate(freepasses.getRow(), 1)) {
								//if(!freepassUser.delete("order_id = " + oid)) { }
								errorCode += "[ERR-F1] 프리패스 상태를 변경하는 중 오류가 발생했습니다.<br />\n";
								isDBOK = false;
							}

						} else {
							//프리패스신청
							freepasses.put("id", freepasses.i("freepass_id"));
							freepasses.put("order_item_id", orderItemId);
							freepasses.put("order_id", oid);
							if(!freepassUser.addUser(freepasses, info.i("user_id"), 1)) {
								//if(!freepassUser.delete("order_id = " + oid)) { }
								errorCode += "[ERR-F2] 프리패스를 신청하는 중 오류가 발생했습니다.<br />\n";
								isDBOK = false;
							}
						}

					} // freepassUser

				} // orderItem.update
			} // this.update
		} // this.info

		if(!isDBOK) { //최종결제요청 결과 성공 DB처리 실패시 Rollback 처리

			//DB rollback
			//주문
			/*
			this.clear();
			this.item("pay_date", "");
			this.item("status", 0);
			if(!this.update("id = " + oid)) { }

			orderItem.item("status", 0);
			if(!orderItem.update("order_id = " + oid)) { }
			*/

			StringBuffer sb = new StringBuffer();
			sb.append("오류코드:" + errorCode + "<br>");
			sb.append("TYPE:" + pinfo.s("casflag") + "<br>");
			//sb.append("OID:" + pinfo.s("oid") + "<br>");
			sb.append("OID:" + oid + "<br>");
			sb.append("TID:" + pinfo.s("tid") + "<br>");
			sb.append("CODE:" + pinfo.s("code") + "<br>");
			sb.append("MSG:" + pinfo.s("msg") + "<br>");
			sb.append("BUYER:" + pinfo.s("buyer") + "<br>");
			sb.append("BUYERID:" + pinfo.s("buyerid") + "<br>");
			sb.append("PRODUCT:" + pinfo.s("productinfo") + "<br>");
			//m.mail("hopegiver@malgnsoft.com", "[" + siteinfo.s("site_nm") + "] " + msg, sb.toString());
			m.mail("yhs@malgnsoft.com", "[" + siteinfo.s("site_nm") + "] 결제완료 처리하는 중 오류가 발생하였습니다.", sb.toString());

		} else {
			//결제정보 갱신
			if(!"".equals(pinfo.s("tid"))) {
				payment.item("respmsg", "결제성공");
				if(!payment.update("tid = '" + pinfo.s("tid") + "'")) { }
			}

			DataSet uinfo = user.find("id = " + info.i("user_id") + "");
			if(!uinfo.next()) {}

			info.put("pay_price_conv", m.nf(info.i("pay_price")));
			info.put("order_date_conv", m.time(message != null ? message.get("format.date.dot") : "yyyy.MM.dd", info.s("order_date")));
			info.put("paymethod_conv", m.getItem(info.s("paymethod"), this.methods));

			p.setVar("order", info);
			p.setLoop("order_items", items);

			mail.send(siteinfo, uinfo, "payment", p);
			smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");
		}

		return isDBOK;
	}

	public boolean setUplusDeliveryInfo(DataSet siteinfo, DataSet orderinfo, String deliveryCd, String deliveryNo) throws Exception {
		return setUplusDeliveryInfo(siteinfo, orderinfo, deliveryCd, deliveryNo, false);
	}

	public boolean setUplusDeliveryInfo(DataSet siteinfo, DataSet orderinfo, String deliveryCd, String deliveryNo, boolean isDev) throws Exception {
		String serviceUrl = "";
		if(isDev) serviceUrl = "http://pgweb.uplus.co.kr:7085/pg/wmp/mertadmin/jsp/escrow/rcvdlvinfo.jsp"; 
		else serviceUrl = "https://pgweb.uplus.co.kr/pg/wmp/mertadmin/jsp/escrow/rcvdlvinfo.jsp"; 

		//변수
		boolean result = false;
		String mid = (isDev ? "t" : "") + siteinfo.s("pg_id");
		String oid = orderinfo.s("id");
		String dlvdate = Malgn.time("yyyyMMddHHmm");
		String dlvcompcode = deliveryCd;
		String dlvno = deliveryNo;
		String mertkey = siteinfo.s("pg_key");
		String hashdata = Malgn.encrypt(mid + oid + dlvdate + dlvcompcode + dlvno + mertkey);

		//데이터
		String msg = "";
		StringBuffer sb = new StringBuffer();
		sb.append("mid=" + mid + "&");
		sb.append("oid=" + oid + "&");
		sb.append("dlvtype=03&");
		sb.append("dlvdate=" + dlvdate + "&");
		sb.append("dlvcompcode=" + dlvcompcode + "&");
		sb.append("dlvno=" + dlvno + "&");
		sb.append("hashdata=" + hashdata);
		msg = sb.toString();

		//전송
		StringBuffer sbErr = new StringBuffer();
		URL url = new URL(serviceUrl);
		result = this.sendRCVInfo(msg, url, sbErr);

		return result;
	}

	//*************************************************
	// 아래부분 절대 수정하지 말것 - UPLUS
	//*************************************************
	private boolean sendRCVInfo(String sendMsg, URL url, StringBuffer errmsg) throws Exception{
        OutputStreamWriter wr = null;
        BufferedReader br = null;
        HttpURLConnection conn = null;
        boolean result = false;
		String errormsg = null;

        try {
            conn = (HttpURLConnection)url.openConnection();
            conn.setDoOutput(true);
            wr = new OutputStreamWriter(conn.getOutputStream());
            wr.write(sendMsg);
            wr.flush();
            for (int i=0; ; i++) {
                String headerName = conn.getHeaderFieldKey(i);
                String headerValue = conn.getHeaderField(i);

                if (headerName == null && headerValue == null) {
                    break;
                }
                if (headerName == null) {
                    headerName = "Version";
                }

                errmsg.append(headerName + ":" + headerValue + "\n");
            }


            br = new BufferedReader(new InputStreamReader(conn.getInputStream ()));

            String in;
            StringBuffer sb = new StringBuffer();
            while(((in = br.readLine ()) != null )){
                sb.append(in);
            }

            errmsg.append(sb.toString().trim());
            if (sb.toString().trim().equals("OK")){
                result = true;
            } else{
				errormsg = sb.toString().trim();
			}

        } catch (IOException ioe) {
        	Malgn.errorLog("IOException : OrderDao.sendRCVInfo() : " + ioe.getMessage(), ioe);
            errmsg.append("IOException : " + ioe.getMessage());
        } catch (Exception ex) {
			Malgn.errorLog("Exception : OrderDao.sendRCVInfo() : " + ex.getMessage(), ex);
			errmsg.append("Exception : " + ex.getMessage());
        } finally {
            try {
                if (wr != null) wr.close();
                if (br != null) br.close();
            } catch(IOException ioe){
				Malgn.errorLog( "IOException : OrderDao.sendRCVInfo() : " + ioe.getMessage(), ioe);
            } catch(Exception e){
				Malgn.errorLog( "Exception : OrderDao.sendRCVInfo() : " + e.getMessage(), e);
            }
        }
        return result;

    }
}