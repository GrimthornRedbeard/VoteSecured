#!/bin/bash

echo "🔗 Footer Links Permission Test"
echo "================================"
echo ""

WEB_DIR="/var/www/vhosts/vote-secured.net/httpdocs"

echo "📋 Testing Footer Links from Index Page:"
echo ""

# Footer links from the main page
declare -a FOOTER_LINKS=(
    "/demo.html"
    "/demo-security.html" 
    "/demo-verification.html"
    "/demo-analytics.html"
    "/states/georgia.html"
    "/states/florida.html"
    "/states/texas.html"
    "/states/california.html"
    "/states/federal.html"
    "/compliance/eac-vvsg.html"
    "/compliance/ieee-1622.html"
    "/compliance/common-criteria.html"
    "/compliance/nist.html"
    "/compliance/nist-800-53.html"
    "/pilot-programs.html"
    "/demo-rcv.html"
    "/demo-official.html"
)

for link in "${FOOTER_LINKS[@]}"; do
    file_path="$WEB_DIR$link"
    if sudo test -r "$file_path"; then
        # Check if file is readable by web server
        perms=$(sudo stat -c "%a" "$file_path")
        owner=$(sudo stat -c "%U:%G" "$file_path")
        echo "✅ $link - Readable (perms: $perms, owner: $owner)"
    else
        echo "❌ $link - NOT READABLE or MISSING"
    fi
done

echo ""
echo "🗂️ Directory Permissions Check:"

declare -a DIRECTORIES=(
    "/compliance"
    "/states" 
    "/docs"  
    "/images"
)

for dir in "${DIRECTORIES[@]}"; do
    dir_path="$WEB_DIR$dir"
    if sudo test -d "$dir_path"; then
        perms=$(sudo stat -c "%a" "$dir_path")
        owner=$(sudo stat -c "%U:%G" "$dir_path")
        if [[ "$perms" == "755" ]]; then
            echo "✅ $dir - Correct permissions ($perms, owner: $owner)"
        else
            echo "⚠️ $dir - Permission issue ($perms, owner: $owner)"
        fi
    else
        echo "❌ $dir - Directory missing"
    fi
done

echo ""
echo "🌐 Web Server Access Test:"
echo "The following should be accessible via web browser:"
echo ""

for link in "${FOOTER_LINKS[@]}"; do
    echo "http://vote-secured.net$link"
done

echo ""
echo "🏁 Footer Links Test Complete!"
echo "Report generated: $(date)"