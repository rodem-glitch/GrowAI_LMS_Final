package dao;

import malgnsoft.db.*;

public class SmsAutoDao extends DataObject {

	public String[] weekList = { "1=>월", "2=>화", "3=>수", "4=>목", "5=>금", "6=>토", "7=>일" };
	public String[] nameList = { "A=>이름", "B=>학습시작일", "C=>학습종료일", "D=>학습일로부터 며칠", "E=>학습종료일 전 며칠"
									,"F=>과정명", "G=>진도율", "H=>진도점수", "I=>과제점수", "J=>시험점수", "K=>토론점수", "L=>수료 여부(수료/미수료)" };
	public String[] userTypeList = { "1=>모두", "2=>진도 미진자", "3=>수료 기준 미달자", "4=>미수료자", "5=>수료자", "6=>개강전" };
	public String[] statusList = { "1=>사용", "0=>미사용" };
	public String[] cycleList = { "D=>매일", "W=>매주", "M=>매월" };

	public SmsAutoDao() {
		this.table = "TB_SMS_AUTO";
	}
}