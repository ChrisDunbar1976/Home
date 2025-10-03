const sql = require('mssql');

(async () => {
  try {
    const pool = await sql.connect({
      server: process.env.SERVER_NAME,
      user: process.env.USER_NAME,
      password: process.env.PASSWORD,
      database: process.env.DATABASE_NAME,
      options: {
        encrypt: true
      },
      connectionTimeout: 30000
    });

    const result = await pool.request().query('SELECT TOP 5 name FROM sys.tables ORDER BY name');
    console.log(JSON.stringify(result.recordset, null, 2));
    await pool.close();
    process.exit(0);
  } catch (err) {
    console.error('Connection failed:', err);
    process.exit(1);
  }
})();
