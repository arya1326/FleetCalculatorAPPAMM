<?php
require_once '../config/database.php';

// Cek login dan dapatkan user_id dari token
$userId = checkLogin();

$database = new Database();
$db = $database->getConnection();

// Ambil data user lengkap termasuk NRP
$userQuery = "SELECT id, nrp, name FROM users WHERE id = :user_id";
$userStmt = $db->prepare($userQuery);
$userStmt->bindParam(':user_id', $userId);
$userStmt->execute();
$userData = $userStmt->fetch(PDO::FETCH_ASSOC);

if (!$userData) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'User not found']);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

// Validasi data
if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON data']);
    exit();
}

$query = "INSERT INTO calculations 
          (id, user_id, user_nrp, material, distance, actual_hauler, loader_prod, loader_name, 
           hauler_cap, hauler_name, loading_speed, speed, loading_time, spotting_time, dumping_time, cycle_time, 
           recommended_hauler, match_factor, status, timestamp) 
          VALUES 
          (:id, :user_id, :user_nrp, :material, :distance, :actual_hauler, :loader_prod, :loader_name,
           :hauler_cap, :hauler_name, :loading_speed, :speed, :loading_time, :spotting_time, :dumping_time, :cycle_time,
           :recommended_hauler, :match_factor, :status, :timestamp)";

$stmt = $db->prepare($query);

// Ambil NRP dari data user
$userNrp = $userData['nrp'];

$stmt->bindParam(':id', $data->id);
$stmt->bindParam(':user_id', $userId);
$stmt->bindParam(':user_nrp', $userNrp);  // <-- Tambahkan ini!
$stmt->bindParam(':material', $data->material);
$stmt->bindParam(':distance', $data->distance);
$stmt->bindParam(':actual_hauler', $data->actualHauler);
$stmt->bindParam(':loader_prod', $data->loaderProd);
$stmt->bindParam(':loader_name', $data->loaderName);
$stmt->bindParam(':hauler_cap', $data->haulerCap);
$stmt->bindParam(':hauler_name', $data->haulerName);
$loadingSpeed = $data->loadingSpeed ?? 19;
$stmt->bindParam(':loading_speed', $loadingSpeed);
$stmt->bindParam(':speed', $data->speed);
$stmt->bindParam(':loading_time', $data->loadingTime);
$stmt->bindParam(':spotting_time', $data->spottingTime);
$stmt->bindParam(':dumping_time', $data->dumpingTime);
$stmt->bindParam(':cycle_time', $data->cycleTime);
$stmt->bindParam(':recommended_hauler', $data->recommendedHauler);
$stmt->bindParam(':match_factor', $data->matchFactor);
$stmt->bindParam(':status', $data->status);
$stmt->bindParam(':timestamp', $data->timestamp);

if ($stmt->execute()) {
    http_response_code(201);
    echo json_encode(['success' => true, 'message' => 'Calculation saved']);
} else {
    $error = $stmt->errorInfo();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to save calculation: ' . $error[2]]);
}
?>