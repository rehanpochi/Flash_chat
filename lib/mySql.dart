import 'package:mysql1/mysql1.dart';

class MySql {
  static String host = '10.0.2.2',
      user = 'root',
      db = 'test',
      password = 'Hello@123';
  static int port = 3306;

  MySql();

  Future<MySqlConnection> getConnection() async {
    print('trying to connect to database');
    var settings = new ConnectionSettings(
        host: host, port: port, user: user, db: db, password: password);
    final conn = await MySqlConnection.connect(settings);

    await conn.query('create database check');

    return conn;
    //var conn = await MySqlConnection.connect(settings);
  }
}
