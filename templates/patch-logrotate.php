<?php
// Patch EasyEngine logrotate: copytruncate + ghi thông báo vào ee.log thay cho docker kill/reopen.
$file = 'php/EE/Logrotate/Utils.php';
$c = file_get_contents($file);
if ($c === false) {
    fwrite(STDERR, "Cannot read $file\n");
    exit(1);
}

$rules = [
    [
        'site logs',
        '/^([ \t]*)postrotate\R'
        . '[ \t]*docker ps -q -f label=io\.easyengine\.site -f label=com\.docker\.compose\.service=nginx[^\r\n]*\R'
        . '[ \t]*docker ps -q -f label=io\.easyengine\.site -f label=com\.docker\.compose\.service=php[^\r\n]*\R/m',
    ],
    [
        'nginx-proxy logs',
        '/^([ \t]*)postrotate\R'
        . '[ \t]*docker ps -q -f label=com\.docker\.compose\.service=global-nginx-proxy[^\r\n]*\R/m',
    ],
];

foreach ($rules as [$label, $regex]) {
    $count = 0;
    $c = preg_replace_callback($regex, function ($m) use ($label) {
        $i = $m[1];
        return $i . "copytruncate\n"
            . $i . "postrotate\n"
            . $i . '    echo "$(date \'+[%d/%m/%Y %H:%M:%S]\') LogRotate.INFO: Daily rotate ' . $label . '" >> {$root_dir}/logs/ee.log || true' . "\n";
    }, $c, -1, $count);

    if ($count !== 1) {
        fwrite(STDERR, "Logrotate patch: block '$label' matched $count times (expected 1)\n");
        exit(1);
    }
}

file_put_contents($file, $c);
echo "Logrotate patch applied.\n";