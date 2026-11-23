<?php
require_once '../config/database.php';

$userId = checkLogin();

$database = new Database();
$db = $database->getConnection();

$id = basename($_SERVER['REQUEST_URI']);

$query = "DELETE FROM calculations WHERE id = :id AND user_id = :user_id";
$stmt = $db->prepare($query);
$stmt->bindParam(':id', $id);
$stmt->bindParam(':user_id', $userId);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Calculation deleted']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Delete failed']);
}
?>