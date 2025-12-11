package dao;

import malgnsoft.util.*;
import malgnsoft.db.*;
import java.util.*;

public class QuestionDao extends DataObject {

	public String[] types = {"1=>단일선택", "2=>다중선택", "3=>단답형", "4=>서술형"};
	public String[] grades = {"1=>A", "2=>B", "3=>C", "4=>D", "5=>E", "6=>F"};
	public String[] statusList = { "1=>사용", "0=>중지"};
	
	public String[] typesMsg = {"1=>list.question.types.1", "2=>list.question.types.2", "3=>list.question.types.3", "4=>list.question.types.4"};
	public String[] statusListMsg = { "1=>list.question.status_list.1", "0=>list.question.status_list.0" };

	public QuestionDao() {
		this.table = "LM_QUESTION";
	}

	public String randomQuery(String sql, int limit) {
		String dbType = this.getDBType();
		if("oracle".equals(dbType)) {
			sql = "SELECT * FROM (" + sql + " ORDER BY dbms_random.value) WHERE rownum  <= " + limit;
		} else if("mssql".equals(dbType)) {
			sql = sql.replaceAll("(?i)^(SELECT)", "SELECT TOP(" + limit + ")") + " ORDER BY NEWID()";
		} else if("db2".equals(dbType)) {
			sql = sql.replaceAll("(?i)^(SELECT)", "SELECT RAND() as IDXX, ") + " ORDER BY IDXX FETCH FIRST " + limit + " ROWS ONLY";
		} else {
			sql += " ORDER BY RAND() LIMIT " + limit;
		}
		return sql;
	}
}