<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

class Database {
    private $host     = "localhost";
    private $db_name  = "simz6788_fleetcalculator";
    private $username = "simz6788_fleetcalculator";
    private $password = "fleetcalculator";
    public  $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username, $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->exec("set names utf8");
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Connection error: ' . $e->getMessage()]);
            exit();
        }
        return $this->conn;
    }
}

// ─── JWT (sederhana, tanpa library eksternal) ──────────────────────────────
define('JWT_SECRET', 'GANTI_DENGAN_STRING_RAHASIA_PANJANG_ANDA');
define('JWT_EXPIRY', 60 * 60 * 24 * 30); // 30 hari

function base64UrlEncode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64UrlDecode(string $data): string {
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($data)) % 4));
}

function generateToken(int $userId): string {
    $header  = base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64UrlEncode(json_encode([
        'sub' => $userId,
        'iat' => time(),
        'exp' => time() + JWT_EXPIRY
    ]));
    $signature = base64UrlEncode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$signature";
}

function verifyToken(string $token): ?int {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;

    [$header, $payload, $signature] = $parts;
    $expected = base64UrlEncode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    if (!hash_equals($expected, $signature)) return null;

    $data = json_decode(base64UrlDecode($payload), true);
    if (!$data || $data['exp'] < time()) return null;

    return (int) $data['sub'];
}

// Ambil user_id dari Authorization header; exit 401 jika tidak valid.
function checkLogin(): int {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (strpos($auth, 'Bearer ') === 0) {
        $token  = substr($auth, 7);
        $userId = verifyToken($token);
        if ($userId) return $userId;
    }

    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}
?>