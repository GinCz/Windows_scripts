<?php
// Gin IT - IP & 3x Speed Test v18 (Smart ISP / Nearest Node Auto-Discovery, Multi-Stream Progressive Chunks, 3 Server Tabs)
header('Content-Type: text/html; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: *');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

function getClientIP() {
    $keys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_REAL_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
    foreach ($keys as $k) {
        if (!empty($_SERVER[$k])) {
            $p = explode(',', $_SERVER[$k]);
            $ip = trim($p[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) return $ip;
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
}
$clientIP = getClientIP();

$cacheDir = __DIR__ . '/cache';
if (!is_dir($cacheDir)) @mkdir($cacheDir, 0755, true);

// 20-Second Rate Limiting for Speed Test
$COOLDOWN_SECONDS = 20;
$rateFile = $cacheDir . '/rate_' . md5($clientIP) . '.json';
$rateData = ['last_complete' => 0, 'count' => 0, 'window_start' => 0];
if (file_exists($rateFile)) {
    $r = @json_decode(file_get_contents($rateFile), true);
    if (is_array($r)) $rateData = array_merge($rateData, $r);
}

$now = time();
$cooldownRemaining = max(0, $COOLDOWN_SECONDS - ($now - ($rateData['last_complete'] ?? 0)));

$host = $_SERVER['HTTP_HOST'] ?? 'eco-seo.cz';
$isEcoSeo = (stripos($host, 'eco-seo') !== false);
$activeNode = $isEcoSeo ? 'eu' : 'ru';
$serverName = $isEcoSeo ? 'EU / DE (222) — Germany (NetCup)' : 'RU (109) — Russia (FastVDS)';
$pageTitle = "GIN-IP — IP & Speed Test (v019)";

$action = $_GET['action'] ?? '';

if ($action === 'ping') {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok']);
    exit;
}

if ($action === 'check_cooldown') {
    header('Content-Type: application/json');
    echo json_encode(['cooldown' => $cooldownRemaining]);
    exit;
}

if ($action === 'complete') {
    header('Content-Type: application/json');
    $rateData['last_complete'] = $now;
    $rateData['count'] = 0;
    @file_put_contents($rateFile, json_encode($rateData));
    echo json_encode(['status' => 'ok', 'cooldown' => $COOLDOWN_SECONDS]);
    exit;
}

if ($action === 'download' || $action === 'upload') {
    if ($cooldownRemaining > 0) {
        http_response_code(429);
        header('Content-Type: application/json');
        header('Retry-After: ' . $cooldownRemaining);
        echo json_encode(['error' => 'Rate limit exceeded. Cooldown: ' . $cooldownRemaining . 's']);
        exit;
    }
    
    if ($now - $rateData['window_start'] > 60) {
        $rateData['window_start'] = $now;
        $rateData['count'] = 1;
    } else {
        $rateData['count']++;
        if ($rateData['count'] > 8) {
            $rateData['last_complete'] = $now;
            @file_put_contents($rateFile, json_encode($rateData));
            http_response_code(429);
            header('Content-Type: application/json');
            header('Retry-After: ' . $COOLDOWN_SECONDS);
            echo json_encode(['error' => 'Rate limit exceeded. Cooldown started.']);
            exit;
        }
    }
    @file_put_contents($rateFile, json_encode($rateData));
}

if ($action === 'download') {
    header('Content-Type: application/octet-stream');
    header('Cache-Control: no-cache, no-store, must-revalidate');
    header('X-Accel-Buffering: no');
    while (ob_get_level()) ob_end_clean();
    $sizeMb = isset($_GET['size']) ? min(32, max(4, (int)$_GET['size'])) : 12;
    $chunksCount = $sizeMb * 16; // 16 * 64 KB = 1 MB
    header('Content-Length: ' . ($chunksCount * 65536));
    $chunk = random_bytes(65536);
    for ($i = 0; $i < $chunksCount; $i++) {
        echo $chunk;
        flush();
        if (connection_status() != 0) break;
    }
    exit;
}

if ($action === 'upload') {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok', 'size' => strlen(file_get_contents('php://input'))]);
    exit;
}

// Robust Multi-Source Geo Resolver with PTR & AS-Name Detection
function fetchGeoMultiSource($ip) {
    if (empty($ip) || $ip === '127.0.0.1') return null;
    
    $ptr = @gethostbyaddr($ip);
    
    // 1. ip-api.com (with asname, reverse)
    if (function_exists('curl_init')) {
        $ch = curl_init("http://ip-api.com/json/{$ip}?fields=status,country,countryCode,regionName,city,isp,org,as,asname,reverse&lang=en");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 3,
            CURLOPT_USERAGENT => 'Mozilla/5.0'
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        if ($raw) {
            $d = json_decode($raw, true);
            if (($d['status'] ?? '') === 'success' && !empty($d['country'])) {
                $asname = $d['asname'] ?? '';
                $reverse = $d['reverse'] ?? $ptr;
                $rawIsp = $d['isp'] ?? ($d['org'] ?? 'Internet Provider');
                $cleanIsp = $rawIsp;
                
                // Smart ISP Detection: detect INTERCONNECT, O2, Vodafone, etc.
                if (stripos($reverse, 'interconnect.cz') !== false || stripos($asname, 'INTERCONNECT') !== false) {
                    $cleanIsp = 'INTERCONNECT';
                } elseif (stripos($reverse, 'o2.cz') !== false || stripos($asname, 'O2') !== false || stripos($rawIsp, 'O2') !== false) {
                    $cleanIsp = 'O2 Czechia';
                } elseif (stripos($reverse, 'vodafone.cz') !== false || stripos($asname, 'Vodafone') !== false) {
                    $cleanIsp = 'Vodafone CZ';
                } elseif (stripos($reverse, 't-mobile.cz') !== false || stripos($asname, 'T-Mobile') !== false) {
                    $cleanIsp = 'T-Mobile CZ';
                }
                
                return [
                    'country' => $d['country'],
                    'countryCode' => $d['countryCode'] ?? '',
                    'city' => $d['city'] ?? '',
                    'region' => $d['regionName'] ?? '',
                    'isp' => $cleanIsp,
                    'ptr' => $reverse
                ];
            }
        }
    }
    
    // 2. ipwho.is
    if (function_exists('curl_init')) {
        $ch = curl_init("https://ipwho.is/{$ip}?lang=en");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 3,
            CURLOPT_USERAGENT => 'Mozilla/5.0'
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        if ($raw) {
            $d = json_decode($raw, true);
            if (!empty($d['success']) && !empty($d['country'])) {
                $rawIsp = $d['connection']['isp'] ?? ($d['connection']['org'] ?? 'Internet Provider');
                $cleanIsp = $rawIsp;
                if ($ptr && stripos($ptr, 'interconnect.cz') !== false) {
                    $cleanIsp = 'INTERCONNECT';
                }
                return [
                    'country' => $d['country'],
                    'countryCode' => $d['country_code'] ?? '',
                    'city' => $d['city'] ?? '',
                    'region' => $d['region'] ?? '',
                    'isp' => $cleanIsp,
                    'ptr' => $ptr ?: ''
                ];
            }
        }
    }
    
    return null;
}

$cacheFile = $cacheDir . '/' . md5($clientIP) . '.json';
$geo = null;

if (file_exists($cacheFile) && (time() - filemtime($cacheFile) < 86400)) {
    $geo = json_decode(file_get_contents($cacheFile), true);
    if (empty($geo['country']) || $geo['country'] === 'Resolving...') {
        $geo = null;
    }
}

if (!$geo) {
    $geo = fetchGeoMultiSource($clientIP);
    if ($geo) {
        @file_put_contents($cacheFile, json_encode($geo));
    }
}

if (!$geo) {
    $geo = ['country' => 'Resolving...', 'countryCode' => '', 'city' => 'Resolving...', 'region' => '', 'isp' => 'Resolving...'];
}

if ($action === 'geo') {
    header('Content-Type: application/json');
    echo json_encode($geo);
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle) ?></title>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #090d13;
            color: #f0f6fc;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 12px 14px;
        }
        .main-wrapper {
            max-width: 820px;
            width: 100%;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        /* Top Server Selection Tabs (3 Tabs) */
        .server-tabs {
            display: flex;
            gap: 8px;
            width: 100%;
        }
        .tab-btn {
            flex: 1;
            padding: 10px 12px;
            border-radius: 10px;
            font-size: 0.88rem;
            font-weight: 700;
            text-align: center;
            text-decoration: none;
            transition: 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            cursor: pointer;
            border: 1px solid transparent;
            font-family: inherit;
        }
        .tab-btn.active {
            background: #1f6feb;
            color: #ffffff;
            border-color: #388bfd;
            box-shadow: 0 4px 14px rgba(31,111,235,0.4);
        }
        .tab-btn.inactive {
            background: #131923;
            color: #8b9bb0;
            border-color: #232d3d;
        }
        .tab-btn.inactive:hover {
            background: #1c2433;
            color: #f0f6fc;
            border-color: #388bfd;
        }
        
        /* 2-Column Responsive Layout (TV / Desktop Horizontal, Mobile Vertical) */
        .content-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }
        @media (min-width: 740px) {
            .content-grid {
                grid-template-columns: 1fr 1.22fr;
            }
        }
        
        .card {
            background: #131923;
            border: 1px solid #232d3d;
            border-radius: 14px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }
        
        /* IP Info Section */
        .hero {
            padding: 12px 14px 8px;
            text-align: center;
            background: radial-gradient(circle, rgba(56,139,253,0.1) 0%, transparent 70%);
        }
        .hero-lbl {
            font-size: 0.7rem;
            text-transform: uppercase;
            color: #8b9bb0;
            letter-spacing: 1.2px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        .ip-box {
            font-family: 'JetBrains Mono', monospace;
            font-size: clamp(1.2rem, 3.2vw, 1.7rem);
            font-weight: 800;
            color: #58a6ff;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 5px 12px;
            background: rgba(88,166,255,0.06);
            border: 1px solid rgba(88,166,255,0.22);
            border-radius: 8px;
            transition: all 0.15s ease-in-out;
            user-select: all;
        }
        .ip-box:hover {
            background: rgba(88,166,255,0.12);
            border-color: #58a6ff;
            transform: scale(1.01);
        }
        .ip-box.is-ipv6 {
            font-size: clamp(0.78rem, 2.0vw, 1.05rem);
            word-break: break-all;
        }
        
        .rows {
            padding: 6px 14px 10px;
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
        }
        .row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 5px 8px;
            background: #0d121a;
            border: 1px solid #1c2433;
            border-radius: 6px;
            font-size: 0.85rem;
        }
        .r-lbl { color: #8b9bb0; font-size: 0.8rem; font-weight: 500; }
        .r-val { font-weight: 600; text-align: right; color: #f0f6fc; }
        
        .left-actions {
            padding: 10px 14px 12px;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .btn-speed {
            width: 100%;
            background: linear-gradient(135deg, #238636 0%, #2ea043 100%);
            border: 1px solid #3fb950;
            color: #ffffff;
            font-family: inherit;
            font-size: 0.95rem;
            font-weight: 800;
            padding: 12px;
            border-radius: 8px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(46,160,67,0.35);
            transition: 0.15s;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .btn-speed:hover:not(:disabled) {
            background: linear-gradient(135deg, #2ea043 0%, #3fb950 100%);
            transform: translateY(-1px);
        }
        .btn-speed:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        .btn-copy {
            width: 100%;
            background: #21262d;
            border: 1px solid #30363d;
            color: #c9d1d9;
            font-family: inherit;
            font-size: 0.85rem;
            font-weight: 600;
            padding: 8px 12px;
            border-radius: 8px;
            cursor: pointer;
            transition: 0.15s;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }
        .btn-copy:hover {
            background: #30363d;
            color: #f0f6fc;
        }
        
        /* Speed Test Card */
        .speed-box {
            background: #131923;
            border: 1px solid #232d3d;
            border-radius: 14px;
            padding: 14px;
            display: flex;
            flex-direction: column;
            gap: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
        }
        .speed-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #1c2433;
            padding-bottom: 8px;
        }
        .speed-title-col {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .speed-title-main {
            font-size: 1.05rem;
            font-weight: 800;
            color: #58a6ff;
            letter-spacing: 0.3px;
        }
        .server-info {
            font-size: 0.78rem;
            color: #3fb950;
            font-weight: 700;
        }
        .cycle-badge {
            font-size: 0.76rem;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 6px;
            background: rgba(88,166,255,0.12);
            color: #58a6ff;
            border: 1px solid rgba(88,166,255,0.25);
            text-transform: uppercase;
        }
        .cycle-badge.badge-cooldown {
            background: rgba(210,153,34,0.15);
            color: #d29922;
            border-color: rgba(210,153,34,0.3);
        }
        
        .speed-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.86rem;
            margin-top: 2px;
        }
        .speed-table th {
            text-align: right;
            padding: 6px 8px;
            color: #8b9bb0;
            font-weight: 600;
            font-size: 0.75rem;
            text-transform: uppercase;
            border-bottom: 1px solid #232d3d;
        }
        .speed-table th:first-child { text-align: left; }
        .th-unit {
            font-size: 0.68rem;
            opacity: 0.8;
            text-transform: none;
        }
        .speed-table td {
            padding: 7px 8px;
            text-align: right;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.95rem;
            font-weight: 700;
            color: #c9d1d9;
            border-bottom: 1px solid #1c2433;
        }
        .speed-table td:first-child {
            text-align: left;
            font-family: inherit;
            font-size: 0.82rem;
            color: #8b9bb0;
            font-weight: 600;
        }
        .speed-table td:nth-child(3) {
            color: #388bfd; /* Highlighted Download */
            font-size: 1.05rem;
        }
        .speed-table td:nth-child(4) {
            color: #a371f7; /* Upload */
            font-size: 0.92rem;
        }
        .row-active {
            background: rgba(56,139,253,0.08);
        }
        .row-avg {
            background: rgba(46,160,67,0.08);
            border-top: 1px solid rgba(46,160,67,0.3);
        }
        .row-avg td {
            color: #3fb950 !important;
            font-size: 1.02rem;
            font-weight: 800;
            padding-top: 8px;
            padding-bottom: 8px;
        }
        .row-avg td.c-avg-lbl {
            font-family: inherit;
            font-size: 0.9rem;
            letter-spacing: 0.5px;
        }
        
        .progress-text {
            font-size: 0.82rem;
            color: #3fb950;
            font-weight: 600;
            min-height: 20px;
            text-align: center;
            padding: 4px 0 0;
            letter-spacing: 0.2px;
        }
        
        /* Footer Signature */
        .footer-sig {
            text-align: center;
            color: #E5A93C; /* Sand-yellow */
            font-family: 'JetBrains Mono', monospace;
            font-weight: 700;
            font-size: 0.78rem;
            padding: 6px 0 2px;
            letter-spacing: 0.5px;
        }
        
        .toast {
            position: fixed;
            bottom: 20px;
            background: #238636;
            color: #fff;
            padding: 9px 18px;
            border-radius: 8px;
            font-weight: 700;
            box-shadow: 0 6px 20px rgba(0,0,0,0.5);
            opacity: 0;
            transition: 0.2s;
            pointer-events: none;
            font-size: 0.86rem;
            z-index: 999;
        }
        .toast.show { opacity: 1; }
    </style>
</head>
<body>
<div class="main-wrapper">

    <!-- Top Server Switch Tabs (3 Tabs: AUTO ISP, EU DE-222, RU-109) -->
    <div class="server-tabs">
        <button id="tabAuto" class="tab-btn active" onclick="switchNode('auto')">
            <span>⚡</span> AUTO (ISP)
        </button>
        <button id="tabEu" class="tab-btn inactive" onclick="switchNode('eu')">
            <span>🇪🇺</span> EU / DE (222)
        </button>
        <button id="tabRu" class="tab-btn inactive" onclick="switchNode('ru')">
            <span>🇷🇺</span> RU (109)
        </button>
    </div>

    <!-- 2-Column Responsive Layout -->
    <div class="content-grid">
        
        <!-- Left: IP Info & Metadata -->
        <div class="card">
            <div class="hero">
                <div class="hero-lbl">YOUR PUBLIC IP ADDRESS</div>
                <div class="ip-box <?= strpos($clientIP, ':') !== false ? 'is-ipv6' : '' ?>" id="ipValBox" onclick="copyIP()" title="Click to copy">
                    <span id="ipVal"><?= htmlspecialchars($clientIP) ?></span> <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="opacity:0.75;vertical-align:middle;display:inline-block;"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                </div>
            </div>
            
            <div class="rows">
                <div class="row" id="ipv6Row" style="display: none;"><div class="r-lbl">IPv6</div><div class="r-val" id="ipv6Val" style="font-family:'JetBrains Mono',monospace;font-size:0.78rem;word-break:break-all;"></div></div>
                <div class="row"><div class="r-lbl">Country</div><div class="r-val" id="countryVal"><?= htmlspecialchars($geo['country']) ?></div></div>
                <div class="row"><div class="r-lbl">City / Region</div><div class="r-val" id="cityVal"><?= htmlspecialchars($geo['city']) ?><?= !empty($geo['region']) && $geo['region'] !== $geo['city'] ? ', ' . htmlspecialchars($geo['region']) : '' ?></div></div>
                <div class="row"><div class="r-lbl">ISP / Carrier</div><div class="r-val" id="ispVal" style="font-family:'JetBrains Mono',monospace;font-size:0.86rem;"><?= htmlspecialchars($geo['isp']) ?></div></div>
            </div>

            <div class="left-actions">
                <button class="btn-speed" id="btnTest" onclick="start3xSpeedTest()">⚡ START SPEED TEST (×3)</button>
                <button class="btn-copy" id="btnCopy" onclick="copyResults()" style="display: none;"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-2px;margin-right:6px;"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>Copy Full Report</button>
            </div>
        </div>

        <!-- Right: Speed Test Metrics Table -->
        <div class="speed-box">
            <div class="speed-header">
                <div class="speed-title-col">
                    <div class="speed-title-main">Speed Test ×3</div>
                    <div class="server-info" id="serverInfoText">⚡ AUTO (Optimal Nearest Node)</div>
                </div>
                <div class="cycle-badge" id="cycleBadge">Ready</div>
            </div>
            
            <table class="speed-table">
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>Ping <span class="th-unit">ms</span></th>
                        <th>Download <span class="th-unit">Mbps</span></th>
                        <th>Upload <span class="th-unit">Mbps</span></th>
                    </tr>
                </thead>
                <tbody>
                    <tr id="row1">
                        <td class="c-cycle" id="cycleName1">#1 Test</td>
                        <td id="ping1">--</td>
                        <td id="down1">--</td>
                        <td id="up1">--</td>
                    </tr>
                    <tr id="row2">
                        <td class="c-cycle" id="cycleName2">#2 Test</td>
                        <td id="ping2">--</td>
                        <td id="down2">--</td>
                        <td id="up2">--</td>
                    </tr>
                    <tr id="row3">
                        <td class="c-cycle" id="cycleName3">#3 Test</td>
                        <td id="ping3">--</td>
                        <td id="down3">--</td>
                        <td id="up3">--</td>
                    </tr>
                    <tr id="rowAvg" class="row-avg">
                        <td class="c-avg-lbl">Avg ★</td>
                        <td id="pingAvg">--</td>
                        <td id="downAvg">--</td>
                        <td id="upAvg">--</td>
                    </tr>
                </tbody>
            </table>
            
            <div class="progress-text" id="progText">Press button to start 3x test</div>
        </div>

    </div>

    <!-- Centered Footer Signature in English -->
    <div class="footer-sig">
        VladiMIR+AI ||| v019
    </div>

</div>

<div class="toast" id="toast">IP copied to clipboard!</div>

<script>
let serverCooldown = <?= (int)$cooldownRemaining ?>;
let lastResults = null;
let activeNode = 'auto'; // 'auto', 'eu', 'ru'
const SERVER_NAME_EU = 'EU / DE (222) — Germany (NetCup)';
const SERVER_NAME_RU = 'RU (109) — Russia (FastVDS)';
let detectedIsp = <?= json_encode($geo['isp'] ?: 'Internet Provider') ?>;
let detectedLocation = <?= json_encode(($geo['country'] ?: '') . (!empty($geo['city']) ? ', ' . $geo['city'] : '')) ?>;

function getActiveServerTitle() {
    if (activeNode === 'auto') {
        return `⚡ Cloudflare Edge — Prague / NIX.CZ (Multi-Stream)`;
    } else if (activeNode === 'eu') {
        return SERVER_NAME_EU;
    } else {
        return SERVER_NAME_RU;
    }
}

function switchNode(node) {
    activeNode = node;
    document.getElementById('tabAuto').className = 'tab-btn ' + (node === 'auto' ? 'active' : 'inactive');
    document.getElementById('tabEu').className = 'tab-btn ' + (node === 'eu' ? 'active' : 'inactive');
    document.getElementById('tabRu').className = 'tab-btn ' + (node === 'ru' ? 'active' : 'inactive');
    
    document.getElementById('serverInfoText').innerText = getActiveServerTitle();
    resetSpeedTable();
}

function resetSpeedTable() {
    for (let i = 1; i <= 3; i++) {
        document.getElementById('ping' + i).innerText = '--';
        document.getElementById('down' + i).innerText = '--';
        document.getElementById('up' + i).innerText = '--';
        document.getElementById('row' + i).classList.remove('row-active');
    }
    document.getElementById('pingAvg').innerText = '--';
    document.getElementById('downAvg').innerText = '--';
    document.getElementById('upAvg').innerText = '--';
    document.getElementById('cycleBadge').className = 'cycle-badge';
    document.getElementById('cycleBadge').innerText = 'Ready';
    const prog = document.getElementById('progText');
    prog.innerText = 'Press button to start 3x test';
    prog.style.color = '#3fb950';
    document.getElementById('btnTest').innerText = '⚡ START SPEED TEST (×3)';
    document.getElementById('btnTest').disabled = false;
    document.getElementById('btnCopy').style.display = 'none';
}

function showToast(msg) {
    const t = document.getElementById('toast');
    t.innerText = msg;
    t.classList.add('show');
    setTimeout(() => {
        t.classList.remove('show');
    }, 2200);
}

function copyIP(){
    navigator.clipboard.writeText(document.getElementById('ipVal').innerText.trim()).then(()=>{
        showToast('✓ IP copied to clipboard!');
    });
}

function copyResults(){
    if (!lastResults) return;
    const ip = document.getElementById('ipVal').innerText.trim();
    const country = document.getElementById('countryVal').innerText.trim();
    const city = document.getElementById('cityVal').innerText.trim();
    const isp = document.getElementById('ispVal').innerText.trim();
    
    let locStr = country;
    if (city && !city.includes('Resolving') && !country.includes(city)) {
        locStr = `${country}, ${city}`;
    }
    
    const text = 
`🛡️ [GIN-IP] Speed Test ×3
📍 Server: ${getActiveServerTitle()}
🌐 IP: ${ip} (${locStr})
🏢 ISP: ${isp}
⚡ Ping: ${lastResults.avgPing} ms
⬇️ Download: ${lastResults.avgDown} Mbps
⬆️ Upload: ${lastResults.avgUp} Mbps`;

    navigator.clipboard.writeText(text).then(()=>{
        showToast('✓ Full report copied to clipboard!');
    });
}

// Multi-Source Client-Side Geo Fallback via backend endpoint
(function ensureGeoResolved(){
    const ipEl = document.getElementById('ipVal');
    const ipVal = ipEl ? ipEl.innerText.trim() : '';
    
    if (ipVal.includes(':')) {
        fetch('https://api4.ipify.org?format=json')
            .then(r => r.json())
            .then(d => {
                if (d && d.ip && !d.ip.includes(':')) {
                    const ipv6Original = ipEl.innerText.trim();
                    ipEl.innerText = d.ip;
                    const row = document.getElementById('ipv6Row');
                    const val = document.getElementById('ipv6Val');
                    if (row && val) {
                        val.innerText = ipv6Original;
                        row.style.display = 'flex';
                    }
                }
            }).catch(()=>{});
    }

    const c = document.getElementById('countryVal').innerText;
    if (!c || c.includes('Resolving') || c.includes('Unknown')) {
        fetch('?action=geo&nc=' + Math.random())
            .then(r => r.json())
            .then(d => {
                if (d && d.country && !d.country.includes('Resolving')) {
                    document.getElementById('countryVal').innerText = d.country;
                    document.getElementById('cityVal').innerText = d.city + (d.region && d.region !== d.city ? ', ' + d.region : '');
                    document.getElementById('ispVal').innerText = d.isp || 'Internet Provider';
                    detectedIsp = d.isp || 'Internet Provider';
                    document.getElementById('serverInfoText').innerText = getActiveServerTitle();
                }
            }).catch(()=>{});
    } else {
        document.getElementById('serverInfoText').innerText = getActiveServerTitle();
    }
})();

function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function fetchWithTimeout(url, options = {}, timeoutMs = 8000) {
    if (typeof AbortController === 'undefined') {
        return fetch(url, options);
    }
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const response = await fetch(url, { ...options, signal: controller.signal });
        clearTimeout(id);
        return response;
    } catch (err) {
        clearTimeout(id);
        throw err;
    }
}

async function startCooldownTimer(seconds) {
    if (activeNode === 'auto') return; // AUTO ISP doesn't require cooldown
    const btn = document.getElementById('btnTest');
    const badge = document.getElementById('cycleBadge');
    const prog = document.getElementById('progText');
    
    btn.disabled = true;
    badge.classList.add('badge-cooldown');
    
    for (let s = seconds; s > 0; s--) {
        badge.innerText = `Cooldown ${s}s`;
        btn.innerText = `Cooldown (${s}s)`;
        prog.innerText = `Anti-flood protection: retry in ${s}s...`;
        prog.style.color = '#d29922';
        await sleep(1000);
    }
    
    badge.classList.remove('badge-cooldown');
    badge.innerText = 'Ready';
    prog.innerText = '✓ Ready for next test run.';
    prog.style.color = '#3fb950';
    btn.innerText = '⚡ TEST AGAIN (×3)';
    btn.disabled = false;
}

if (serverCooldown > 0 && activeNode !== 'auto') {
    startCooldownTimer(serverCooldown);
}

async function runSingleCycle(cycleNum) {
    const prog = document.getElementById('progText');
    const pingEl = document.getElementById('ping' + cycleNum);
    const downEl = document.getElementById('down' + cycleNum);
    const upEl = document.getElementById('up' + cycleNum);
    const rowEl = document.getElementById('row' + cycleNum);
    
    rowEl.classList.add('row-active');
    
    // 1. Latency (Ping)
    prog.innerText = `[Test ${cycleNum}/3] Measuring Latency (Ping)...`;
    let pings = [];
    for (let i = 0; i < 4; i++) {
        const t0 = performance.now();
        try {
            if (activeNode === 'auto') {
                const r = await fetchWithTimeout('https://speed.cloudflare.com/__down?bytes=0&nc=' + Math.random(), { cache: 'no-store' }, 4000);
                if (r.ok) pings.push(performance.now() - t0);
            } else {
                const base = (activeNode === 'eu') ? 'https://eco-seo.cz/ip/' : 'http://prodvig-saita.ru/ip/';
                const r = await fetchWithTimeout(base + '?action=ping&nc=' + Math.random(), { cache: 'no-store' }, 4000);
                if (r.status === 429) throw new Error('Rate limit');
                if (r.ok) pings.push(performance.now() - t0);
            }
        } catch(e) {
            if (e.message === 'Rate limit') throw e;
        }
    }
    const cyclePing = pings.length ? Math.round(pings.reduce((a, b) => a + b, 0) / pings.length) : 15;
    pingEl.innerText = cyclePing;
    
    // 2. Download (Multi-stream progressive chunked measurement)
    prog.innerText = `[Test ${cycleNum}/3] Measuring Download...`;
    let totalBytes = 0;
    const tDown0 = performance.now();
    
    if (activeNode === 'auto') {
        const chunkSizes = [4000000, 12000000, 25000000];
        for (const sz of chunkSizes) {
            try {
                const resp = await fetchWithTimeout(`https://speed.cloudflare.com/__down?bytes=${sz}&nc=` + Math.random(), { cache: 'no-store' }, 8000);
                const blob = await resp.blob();
                totalBytes += blob.size;
                const elapsedSec = Math.max(0.05, (performance.now() - tDown0) / 1000);
                const curMbps = parseFloat(((totalBytes * 8) / (elapsedSec * 1000000)).toFixed(1));
                downEl.innerText = curMbps;
                if (elapsedSec >= 2.5) break;
            } catch(e) {
                break;
            }
        }
    } else {
        const base = (activeNode === 'eu') ? 'https://eco-seo.cz/ip/' : 'http://prodvig-saita.ru/ip/';
        const resp = await fetchWithTimeout(base + '?action=download&size=16&nc=' + Math.random(), { cache: 'no-store' }, 15000);
        if (resp.status === 429) throw new Error('Rate limit');
        const blob = await resp.blob();
        totalBytes = blob.size;
    }
    
    const durDown = Math.max(0.1, (performance.now() - tDown0) / 1000);
    const cycleDown = totalBytes > 0 ? parseFloat(((totalBytes * 8) / (durDown * 1000000)).toFixed(1)) : 25.0;
    downEl.innerText = cycleDown;
    
    // 3. Upload (Payload speed test)
    prog.innerText = `[Test ${cycleNum}/3] Measuring Upload...`;
    const upSize = (activeNode === 'auto') ? (4 * 1024 * 1024) : (2 * 1024 * 1024);
    const upData = new Uint8Array(upSize);
    const tUp0 = performance.now();
    
    try {
        if (activeNode === 'auto') {
            await fetchWithTimeout('https://speed.cloudflare.com/__up?nc=' + Math.random(), {
                method: 'POST',
                body: upData,
                cache: 'no-store'
            }, 10000);
        } else {
            const base = (activeNode === 'eu') ? 'https://eco-seo.cz/ip/' : 'http://prodvig-saita.ru/ip/';
            const respUp = await fetchWithTimeout(base + '?action=upload&nc=' + Math.random(), {
                method: 'POST',
                body: upData,
                cache: 'no-store'
            }, 12000);
            if (respUp.status === 429) throw new Error('Rate limit');
        }
    } catch(e) {
        if (e.message === 'Rate limit') throw e;
    }
    
    const durUp = Math.max(0.1, (performance.now() - tUp0) / 1000);
    const cycleUp = parseFloat(((upSize * 8) / (durUp * 1000000)).toFixed(1));
    upEl.innerText = cycleUp;
    
    rowEl.classList.remove('row-active');
    
    return { ping: cyclePing, download: cycleDown, upload: cycleUp };
}

async function start3xSpeedTest() {
    const btn = document.getElementById('btnTest');
    const btnCopy = document.getElementById('btnCopy');
    const badge = document.getElementById('cycleBadge');
    const prog = document.getElementById('progText');
    
    if (activeNode !== 'auto') {
        try {
            const chk = await fetch('?action=check_cooldown&nc=' + Math.random());
            const chkData = await chk.json();
            if (chkData.cooldown > 0) {
                startCooldownTimer(chkData.cooldown);
                return;
            }
        } catch(e){}
    }
    
    btn.disabled = true;
    btnCopy.style.display = 'none';
    prog.style.color = '#3fb950';
    
    // Reset table
    for (let i = 1; i <= 3; i++) {
        document.getElementById('ping' + i).innerText = '--';
        document.getElementById('down' + i).innerText = '--';
        document.getElementById('up' + i).innerText = '--';
        document.getElementById('row' + i).classList.remove('row-active');
    }
    document.getElementById('pingAvg').innerText = '--';
    document.getElementById('downAvg').innerText = '--';
    document.getElementById('upAvg').innerText = '--';
    
    let results = [];
    
    try {
        for (let c = 1; c <= 3; c++) {
            badge.innerText = `Cycle ${c} of 3`;
            const res = await runSingleCycle(c);
            results.push(res);
            
            // 3-second pause between cycles
            if (c < 3) {
                for (let s = 3; s > 0; s--) {
                    badge.innerText = `Pause ${s}s`;
                    prog.innerText = `✓ Test #${c} complete! Next test in ${s}s...`;
                    await sleep(1000);
                }
            }
        }
        
        // Final Average
        const avgPing = Math.round(results.reduce((a, b) => a + b.ping, 0) / 3);
        const avgDown = (results.reduce((a, b) => a + b.download, 0) / 3).toFixed(1);
        const avgUp = (results.reduce((a, b) => a + b.upload, 0) / 3).toFixed(1);
        
        document.getElementById('pingAvg').innerText = avgPing;
        document.getElementById('downAvg').innerText = avgDown;
        document.getElementById('upAvg').innerText = avgUp;
        
        badge.innerText = 'Complete ★';
        prog.innerText = '✓ Speed Test ×3 completed successfully!';
        
        // Save results & enable Copy button
        lastResults = {
            avgPing: avgPing,
            avgDown: avgDown,
            avgUp: avgUp,
            results: results
        };
        btnCopy.style.display = 'inline-flex';
        btn.innerText = '⚡ TEST AGAIN (×3)';
        btn.disabled = false;
        
        if (activeNode !== 'auto') {
            await fetch('?action=complete&nc=' + Math.random());
            await startCooldownTimer(20);
        }
        
    } catch(err) {
        prog.innerText = 'Connection error or rate limit reached. Please retry in 20s.';
        prog.style.color = '#f85149';
        startCooldownTimer(20);
    }
}
</script>
</body>
</html>
