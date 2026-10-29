package android.database.sqlite;
import java.sql.*;
public final class SQLiteDatabase {
  public static final int OPEN_READONLY=1;
  final Connection c;
  SQLiteDatabase(Connection c){this.c=c;}
  public static SQLiteDatabase openDatabase(String p, CursorFactory f, int flags){ try { return new SQLiteDatabase(DriverManager.getConnection("jdbc:sqlite:" + p)); } catch (Exception e) { throw new RuntimeException(e); } }
  public android.database.Cursor rawQuery(String s, String[] a){
    try { final Statement st = c.createStatement(); final ResultSet rs = st.executeQuery(s);
      return new android.database.Cursor(){
        public boolean moveToNext(){ try { return rs.next(); } catch (SQLException e){ throw new RuntimeException(e);} }
        public long getLong(int i){ try { return rs.getLong(i+1);} catch (SQLException e){ throw new RuntimeException(e);} }
        public String getString(int i){ try { return rs.getString(i+1);} catch (SQLException e){ throw new RuntimeException(e);} }
        public boolean isNull(int i){ try { rs.getObject(i+1); return rs.wasNull(); } catch (SQLException e){ throw new RuntimeException(e);} }
        public void close(){ try { rs.close(); st.close(); } catch (SQLException e){} }
      }; } catch (SQLException e) { throw new RuntimeException(e); }
  }
  public void close(){ try { c.close(); } catch (SQLException e){} }
  public interface CursorFactory {}
}
