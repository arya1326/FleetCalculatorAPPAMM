<?php
require_once '../config/database.php';

$userId = checkLogin();

$database = new Database();
$db = $database->getConnection();

$query = "SELECT id, nrp, email, name, created_at FROM users WHERE id = :id";
$stmt = $db->prepare($query);
$stmt->bindParam(':id', $userId);
$stmt->execute();

if ($stmt->rowCount() > 0) {
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    echo json_encode(['success' => true, 'user' => $user]);
} else {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'User not found']);
}
?>