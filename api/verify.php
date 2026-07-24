<?php
header('Content-Type: application/json');

// Get the license key from the incoming request
$provided_key = isset($_GET['key']) ? $_GET['key'] : '';

// Temporary static database for testing
$valid_keys = [
    "AITECH-ADMIN-777" => ["status" => "active", "expiry" => "2027-01-01"],
    "AITECH-TEST-000" => ["status" => "expired", "expiry" => "2026-01-01"]
];

// Verify the key
if (array_key_exists($provided_key, $valid_keys)) {
    if ($valid_keys[$provided_key]['status'] == 'active') {
        echo json_encode([
            "status" => "success", 
            "message" => "License Active",
            "expiry" => $valid_keys[$provided_key]['expiry']
        ]);
    } else {
        echo json_encode([
            "status" => "error", 
            "message" => "SYSTEM LOCKDOWN: LICENSE EXPIRED"
        ]);
    }
} else {
    echo json_encode([
        "status" => "error", 
        "message" => "Invalid License Key"
    ]);
}
?>
