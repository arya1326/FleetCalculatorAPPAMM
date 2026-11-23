<?php
require_once '../config/database.php';

// Cek login (tanpa token)
$userId = checkLogin();

$database = new Database();
$db = $database->getConnection();

$query = "SELECT * FROM calculations 
          WHERE user_id = :user_id 
          AND timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)
          ORDER BY timestamp DESC";

$stmt = $db->prepare($query);
$stmt->bindParam(':user_id', $userId);
$stmt->execute();

$calculations = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $calculations[] = [
        'id' => $row['id'],
        'material' => $row['material'],
        'distance' => (double)$row['distance'],
        'actualHauler' => (int)$row['actual_hauler'],
        'loaderProd' => (double)$row['loader_prod'],
        'loaderName' => $row['loader_name'],
        'haulerCap' => (double)$row['hauler_cap'],
        'haulerName' => $row['hauler_name'],
        'loadingSpeed' => (double)$row['loading_speed'],
        'speed' => (double)$row['speed'],
        'loadingTime' => (double)$row['loading_time'],
        'spottingTime' => (double)$row['spotting_time'],
        'dumpingTime' => (double)$row['dumping_time'],
        'cycleTime' => (double)$row['cycle_time'],
        'recommendedHauler' => (int)$row['recommended_hauler'],
        'matchFactor' => (double)$row['match_factor'],
        'status' => $row['status'],
        'timestamp' => $row['timestamp']
    ];
}

echo json_encode(['success' => true, 'calculations' => $calculations]);
?>