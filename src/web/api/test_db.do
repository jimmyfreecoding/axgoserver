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
    
    // 发送 UTF-8 头部，防止浏览器乱码
    header('Content-Type: text/html; charset=utf-8');

    // 获取 axgo_book 表的前 10 条数据
    $stmt = $pdo->query("SELECT * FROM axgo_book LIMIT 10");
    $books = $stmt->fetchAll();

    echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Axgo Book List</title></head><body>";
    echo "<h1>Axgo Book List (Top 10)</h1>";
    echo "<p>File: index.do</p>";

    if (empty($books)) {
        echo "<p>No data found in table 'axgo_book'.</p>";
    } else {
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
        echo "<thead><tr>
                <th>ID</th>
                <th>Room Name</th>
                <th>Subject</th>
                <th>Booker</th>
                <th>Start Time</th>
                <th>Create Time</th>
              </tr></thead>";
        echo "<tbody>";
        foreach ($books as $book) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($book['id']) . "</td>";
            echo "<td>" . htmlspecialchars($book['mroom_name']) . "</td>";
            echo "<td>" . htmlspecialchars($book['subject']) . "</td>";
            echo "<td>" . htmlspecialchars($book['booker_name']) . "</td>";
            echo "<td>" . date('Y-m-d H:i:s', $book['time_start']) . "</td>";
            echo "<td>" . date('Y-m-d H:i:s', $book['createtime']) . "</td>";
            echo "</tr>";
        }
        echo "</tbody></table>";
    }
    echo "</body></html>";

} catch (\PDOException $e) {
    echo "<h1>Database Connection Failed</h1>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}
