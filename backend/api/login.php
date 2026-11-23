<?php
require_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->nrp)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'NRP wajib diisi']);
    exit();
}

$nrp = $data->nrp;

// VALIDASI NRP MINIMAL 8 DIGIT
if (strlen($nrp) < 8) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'NRP minimal 8 digit']);
    exit();
}

// Login menggunakan NRP
$query = "SELECT id, nrp, name, email FROM users WHERE nrp = :nrp";
$stmt  = $db->prepare($query);
$stmt->bindParam(':nrp', $nrp);
$stmt->execute();

if ($stmt->rowCount() > 0) {
    $user  = $stmt->fetch(PDO::FETCH_ASSOC);
    $token = generateToken((int) $user['id']);

    echo json_encode([
        'success' => true,
        'token'   => $token,
        'user'    => [
            'id'    => $user['id'],
            'nrp'   => $user['nrp'],
            'name'  => $user['name'],
            'email' => $user['email']
        ]
    ]);
} else {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'NRP tidak terdaftar']);
}
?>