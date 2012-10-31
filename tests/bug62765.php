<?php
$filename = dirname(__FILE__) . '/bug62765_file.php';
$bin_filename = dirname(__FILE__)  . "/bug62765.bin";
$file_contents = '<?php
function dummy ($a) {
    if ($a) {
        echo 1;
    } else {
        echo 2;
    }
    goto ret;
ret:
    return 2;
}
';
file_put_contents($filename, $file_contents);
apc_compile_file($filename);
apc_bin_dumpfile(array($filename), null, $bin_filename);
apc_bin_loadfile($bin_filename);
include $filename;

echo dummy(0) . "\n";
echo "okey\n";
?>
