class DatabaseInfo
  def get
    data = "db_database template1\n" +
           "db_host #{DB_DIR}\n" 
    return data
  end
end
