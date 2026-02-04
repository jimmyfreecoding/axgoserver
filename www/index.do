<?php
$host = 'mysql';
$db   = 'axgo';
$user = 'axgo_user';
$pass = 'axgo_password';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
     $pdo = new PDO($dsn, $user, $pass, $options);
     
     // 创建测试表（如果不存在）
     $pdo->exec("CREATE TABLE IF NOT EXISTS test_table (
         id INT AUTO_INCREMENT PRIMARY KEY,
         content VARCHAR(255) NOT NULL,
         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )");

     // 检查是否有数据，没有则插入一条
     $stmt = $pdo->query("SELECT COUNT(*) FROM test_table");
     if ($stmt->fetchColumn() == 0) {
         $pdo->prepare("INSERT INTO test_table (content) VALUES (?)")->execute(['Hello from MySQL! This is a .do file testing database connection.']);
     }

     // 读取数据
     $stmt = $pdo->query("SELECT * FROM test_table ORDER BY id DESC LIMIT 1");
     $row = $stmt->fetch();

     echo "<h1>Database Connection Success!</h1>";
     echo "<p>File: index.do</p>";
     echo "<p>Content from Database: <strong>" . htmlspecialchars($row['content']) . "</strong></p>";
     echo "<p>Time: " . $row['created_at'] . "</p>";

} catch (\PDOException $e) {
     echo "<h1>Database Connection Failed</h1>";
     echo "<p>Error: " . $e->getMessage() . "</p>";
}
