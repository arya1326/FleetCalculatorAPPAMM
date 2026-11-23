<?php
require_once '../config/database.php';

$userId = checkLogin();

$database = new Database();
$db = $database->getConnection();

$query = "DELETE FROM calculations WHERE user_id = :user_id";
$stmt = $db->prepare($query);
$stmt->bindParam(':user_id', $userId);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'History cleared']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Clear history failed']);
}
?>