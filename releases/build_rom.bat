@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof
#==============================================================
$zip0="wboy2u.zip"
$zip1="wboy.zip"
$ifiles=`
    "ic129_02.bin","ic130_03.bin","ic131_04.bin","ic132_05.bin",`
    "epr-7591.133","epr-7592.134",`
    "epr7498a.3",`
    "epr7498a.3",`
    "epr-7485.117","epr-7487.04",`
    "epr-7486.110","epr-7488.05",`
    "epr-7497.62","epr-7495.64","epr-7493.66",`
    "epr-7496.61","epr-7494.63","epr-7492.65",`
    "pr-5317.76"

$ofile="a.wonderboy.rom"
$ofileMd5sumValid="a4d870950b164555f1df9899cabb0356"

if (!((Test-Path "./$zip0") -And (Test-Path "./$zip1"))) {
    echo "Error: Cannot find zip files."
	echo ""
	echo "Put $zip0 and $zip1 into the same directory."
}
else {
    Expand-Archive -Path "./$zip0" -Destination ./tmp/ -Force
    Expand-Archive -Path "./$zip1" -Destination ./tmp/ -Force

    cd tmp
    Get-Content $ifiles -Enc Byte -Read 512 | Set-Content "../$ofile" -Enc Byte
    cd ..
    Remove-Item ./tmp -Recurse -Force

    $ofileMD5sumCurrent=(Get-FileHash -Algorithm md5 "./$ofile").Hash.toLower()
    if ($ofileMD5sumCurrent -ne $ofileMd5sumValid) {
        echo "Expected checksum: $ofileMd5sumValid"
        echo "  Actual checksum: $ofileMd5sumCurrent"
        echo ""
        echo "Error: Generated $ofile is invalid."
        echo ""
        echo "This is more likely due to incorrect $zip0 or $zip1 content."
    }
    else {
        echo "Checksum verification passed."
        echo ""
        echo "Copy $ofile into root of SD card along with the rbf file."
    }
}
echo ""
echo ""
pause

