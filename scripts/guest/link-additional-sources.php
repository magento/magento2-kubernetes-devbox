<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
$options = getopt('', ['command:', 'ce-source:', 'additional-source:', 'help', 'exclude:']);

$command = !empty($options['command']) ? $options['command'] : 'link';
$ceSource = !empty($options['ce-source'])
    ? realpath($options['ce-source'])
    : realpath(
        __DIR__
        . DIRECTORY_SEPARATOR
        . '..' . DIRECTORY_SEPARATOR
        . '..' . DIRECTORY_SEPARATOR
        . '..' . DIRECTORY_SEPARATOR
        . 'magento'
    );
$additionalSource = !empty($options['additional-source'])
    ? realpath($options['additional-source'])
    : realpath(__DIR__ . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR);
$isExclude = !empty($options['exclude']) ? (boolean)$options['exclude'] : false;
$excludeFile = $ceSource . DIRECTORY_SEPARATOR . '.git' . DIRECTORY_SEPARATOR . 'info' . DIRECTORY_SEPARATOR . 'exclude';

if (isset($options['help'])) {
    echo "Usage: Magento 2 Build Additional Code script allows you to link Additional code repository to your CE repository.

 --command <link>|<unlink>\tLink or Unlink Additional code\t\tDefault: link
 --ce-source <path/to/ce>\tPath to CE clone\t\tDefault: $ceSource
 --additional-source <path/to/additional-source>\tPath to Additional source code\t\tDefault: $additionalSource
 --exclude <true>|<false>\tExclude Additional files from CE\tDefault: false
 --help\t\t\t\tThis help
";
    exit(0);
}

if (!file_exists($ceSource)) {
    echo "Expected $ceSource folder not found" . PHP_EOL;
    exit(1);
}

if (!file_exists($additionalSource)) {
    echo "Expected $additionalSource folder not found" . PHP_EOL;
    exit(1);
}

$excludePaths = [];
$unusedPaths = [];

switch ($command) {
    case 'link':
        foreach (scanFiles($additionalSource) as $filename) {
            $target = preg_replace('#^' . preg_quote($additionalSource) . "#", '', $filename);

            if (!file_exists(dirname($ceSource . $target))) {
                @symlink(dirname($filename), dirname($ceSource . $target));
                $excludePaths[] = resolvePath(dirname($target));
            } else if (!file_exists($ceSource . $target)) {
                if (is_link(dirname($ceSource . $target))) {
                    continue;
                }
                @symlink($filename, $ceSource . $target);
                $excludePaths[] = resolvePath($target);
            } else {
                continue;
            }
        }
        /* unlink broken links */
        foreach (scanFiles($ceSource) as $filename) {
            if (is_link($filename) && !file_exists($filename)) {
                $unusedPaths[] = resolvePath(preg_replace('#^' . preg_quote($ceSource) . "#", '', $filename));
                unlinkFile($filename);
            }
        }

        //link sample data media if relevant
        $filename = '/media';
        $target = '/vendor/magento/sample-data-media';
        if (file_exists($additionalSource . $filename)) {
            if (!file_exists(dirname($ceSource . $target))) {
                mkdir(dirname($ceSource . $target), 0755, true);
                @symlink($additionalSource . $filename, $ceSource . $target);
                $excludePaths[] = resolvePath($target);
            } else if (!file_exists($ceSource . $target)) {
                @symlink($additionalSource . $filename, $ceSource . $target);
                $excludePaths[] = resolvePath($target);
            }
        }

        setExcludePaths($excludePaths, $unusedPaths, ($isExclude)?$excludeFile:false);

        break;

    case 'unlink':
        foreach (scanFiles($ceSource) as $filename) {
            if (is_link($filename)) {
                $unusedPaths[] = resolvePath(preg_replace('#^' . preg_quote($ceSource) . "#", '', $filename));
                unlinkFile($filename);
            }
        }
        setExcludePaths($excludePaths, $unusedPaths, ($isExclude)?$excludeFile:false);
        break;
}

/**
 * Create exclude file based on $newPaths and $oldPaths
 *
 * @param array $newPaths
 * @param array $oldPaths
 * @param bool $writeToFile
 * @return void
 */
function setExcludePaths($newPaths, $oldPaths, $writeToFile = false)
{
    if (false != $writeToFile && file_exists($writeToFile)) {
        $content = file($writeToFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($content as $lineNum => $line) {

            $newKey = array_search($line, $newPaths);
            if (false !== $newKey) {
                unset($newPaths[$newKey]);
            }

            $oldKey = array_search($line, $oldPaths);
            if (false !== $oldKey) {
                unset($content[$lineNum]);
            }
        }
        $content = array_merge($content, $newPaths);
        formatContent($content);
        file_put_contents($writeToFile, $content);
    }
    formatContent($newPaths);
}

/**
 * Format content before write to file
 *
 * @param array $content
 * @return void
 */
function formatContent(&$content)
{
    array_walk(
        $content,
        function (&$value) {
            $value = resolvePath($value) . PHP_EOL;
        }
    );
}

/**
 * Scan all files from Magento root
 *
 * @param $path
 * @param array $ignorePath
 * @return array
 */
function scanFiles($path, $ignorePath = [])
{
    global $additionalSource;

    $results = [];
    foreach (glob($path . DIRECTORY_SEPARATOR . '*') as $filename) {
        $target = preg_replace('#^' . preg_quote($additionalSource) . "#", '', $filename);
        if (!in_array(resolvePath($target), $ignorePath)) {
            $results[] = $filename;
            if (is_dir($filename)) {
                $results = array_merge($results, scanFiles($filename, $ignorePath));
            }
        }
    }
    return $results;
}

/**
 * OS depends unlink
 *
 * @param string $filename
 * @return void
 */
function unlinkFile($filename)
{
    strtoupper(substr(PHP_OS, 0, 3)) === 'WIN' && is_dir($filename) ? @rmdir($filename) : @unlink($filename);
}

/**
 * Resolve path to Unix format
 *
 * @param string $path
 * @return string
 */
function resolvePath($path)
{
    return ltrim(str_replace('\\', '/', $path), '/');
}
