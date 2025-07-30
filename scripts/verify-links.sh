#!/bin/bash

echo "🔍 Vote-Secured.net Link Verification Report"
echo "==========================================="
echo ""

WEB_DIR="/var/www/vhosts/vote-secured.net/httpdocs"

echo "📊 Site Structure Overview:"
echo "Main pages: $(sudo find $WEB_DIR -maxdepth 1 -name "*.html" | wc -l) files"
echo "State pages: $(sudo find $WEB_DIR/states -name "*.html" 2>/dev/null | wc -l) files"
echo "Compliance pages: $(sudo find $WEB_DIR/compliance -name "*.html" 2>/dev/null | wc -l) files"
echo "Demo pages: $(sudo find $WEB_DIR -name "demo*.html" | wc -l) files"
echo ""

echo "🔗 Key Navigation Links Status:"

# Check main navigation targets
declare -a MAIN_LINKS=(
    "/demo.html"
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
    "/demo-security.html"
    "/docs/index.html"
)

for link in "${MAIN_LINKS[@]}"; do
    file_path="$WEB_DIR$link"
    if sudo test -f "$file_path"; then
        echo "✅ $link - EXISTS"
    else
        echo "❌ $link - MISSING"
    fi
done

echo ""
echo "🎯 Demo Pages Links:"
demo_pages=($(sudo find $WEB_DIR -name "demo*.html" -exec basename {} \;))
for page in "${demo_pages[@]}"; do
    if sudo test -f "$WEB_DIR/$page"; then
        echo "✅ /$page - EXISTS"
    else
        echo "❌ /$page - MISSING"
    fi
done

echo ""
echo "📁 Assets Check:"
if sudo test -f "$WEB_DIR/images/favicon.svg"; then
    echo "✅ /images/favicon.svg - EXISTS"
else
    echo "❌ /images/favicon.svg - MISSING"
fi

echo ""
echo "🏁 Link Verification Complete!"
echo "Total files scanned: $(sudo find $WEB_DIR -name "*.html" | wc -l)"
echo "Report generated: $(date)"