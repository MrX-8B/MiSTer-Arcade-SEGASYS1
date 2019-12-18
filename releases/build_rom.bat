@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof
#==============================================================
$zip="wboy.zip"
$ifiles=`
    "epr-7489.116","epr-7490.109",`
    "epr-7491.96",`
    "epr-7498.120",`
    "epr-7498.120",`
    "epr-7485.117","epr-7487.04",`
    "epr-7486.110","epr-7488.05",`
    "epr-7497.62","epr-7495.64","epr-7493.66",`
    "epr-7496.61","epr-7494.63","epr-7492.65",`
    "pr-5317.76",
    "../dectbl_315_3177.bin"

$ofile="a.wonderboy.rom"
$ofileMd5sumValid="807e48e44a0c5813b3b28f89a6f8a4ad"

if (!(Test-Path "./$zip")) {
    echo "Error: Cannot find $zip file."
	echo ""
	echo "Put $zip into the same directory."
}
else {
    Expand-Archive -Path "./$zip" -Destination ./tmp/ -Force

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
        echo "This is more likely due to incorrect $zip content."
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
