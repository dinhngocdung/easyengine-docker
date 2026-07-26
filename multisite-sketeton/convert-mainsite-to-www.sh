#!/bin/bash
###########################################################
# Script: Đổi Main Site từ domain.com -> www.domain.com
# Áp dụng cho WordPress Multisite (blog_id=1 = Main Site)
#
# Usage:
#   ./convert-mainsite-to-www.sh <domain.com>
###########################################################

set -e

# ====== CONFIG ======
DOMAIN="${1:-}"
TEMPLATE_URL="https://raw.githubusercontent.com/dinhngocdung/easyengine-docker/main/multisite-sketeton/nginx-redirect-override.conf.template"
TEMPLATE_FILE="/tmp/nginx-redirect-override.conf.template"
NGINX_CONF_DIR="/var/lib/docker/volumes/global-nginx-proxy_confd/_data"
SITE_ROOT="/opt/easyengine/sites"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'

log()     { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
error()   { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}" >&2; }

# ====== ROOT CHECK ======
[[ $EUID -ne 0 ]] && error "Script cần chạy với quyền root (sudo)."

# ====== VALIDATE DOMAIN ======
[[ -z "$DOMAIN" ]] && error "Usage: $0 <domain.com>"
if ! [[ "$DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
    error "Domain không hợp lệ: $DOMAIN"
fi

WWW_DOMAIN="www.$DOMAIN"
success "Domain gốc: $DOMAIN  →  Main Site mới: $WWW_DOMAIN"

WP_CONFIG_PATH="$SITE_ROOT/$DOMAIN/app/htdocs/wp-config.php"
if [[ ! -f "$WP_CONFIG_PATH" ]]; then
    error "Không tìm thấy wp-config.php tại: $WP_CONFIG_PATH"
fi

# ====== XÁC NHẬN TRƯỚC KHI CHẠY ======
echo ""
echo "Sẽ thực hiện các bước sau:"
echo "  1. UPDATE wp_site / wp_blogs -> đổi domain Main Site sang $WWW_DOMAIN"
echo "  2. Sửa DOMAIN_CURRENT_SITE trong wp-config.php"
echo "  3. Tải template + tạo file override Nginx redirect (00-$DOMAIN-override.conf)"
echo "  4. ee site clean $DOMAIN && ee site reload $DOMAIN"
echo ""
read -p "Tiếp tục? [y/N]: " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { echo "Đã huỷ."; exit 0; }

# ====== 1. UPDATE wp_site / wp_blogs (qua ee shell) ======
log "Cập nhật wp_site.domain và wp_blogs.domain (blog_id=1)..."

ee shell "$DOMAIN" --command="wp db query \"UPDATE wp_site SET domain = '$WWW_DOMAIN' WHERE domain = '$DOMAIN';\" --allow-root" \
    || error "Update wp_site thất bại."

ee shell "$DOMAIN" --command="wp db query \"UPDATE wp_blogs SET domain = '$WWW_DOMAIN' WHERE blog_id = 1;\" --allow-root" \
    || error "Update wp_blogs thất bại."

success "Đã cập nhật wp_site / wp_blogs."

# ====== 2. SỬA wp-config.php ======
log "Cập nhật DOMAIN_CURRENT_SITE trong wp-config.php..."

if grep -q "DOMAIN_CURRENT_SITE" "$WP_CONFIG_PATH"; then
    sed -i "s|define(\s*'DOMAIN_CURRENT_SITE'\s*,\s*'[^']*'\s*);|define('DOMAIN_CURRENT_SITE', '$WWW_DOMAIN');|" "$WP_CONFIG_PATH"
else
    sed -i "/\/\* That's all, stop editing/i define('DOMAIN_CURRENT_SITE', '$WWW_DOMAIN');" "$WP_CONFIG_PATH"
fi
success "Đã cập nhật wp-config.php"

# ====== 3. TẢI TEMPLATE + TẠO FILE OVERRIDE NGINX ======
log "Tải template từ GitHub..."
if curl -fsSL "$TEMPLATE_URL" -o "$TEMPLATE_FILE"; then
    success "Đã tải template: $TEMPLATE_FILE"

    BACKEND_CONTAINER="$(echo "$DOMAIN" | tr -d '.-')-nginx-1"
    VAR_NAME="$(echo "$DOMAIN" | tr -d '.-')"
    OUTPUT_FILE="$NGINX_CONF_DIR/00-${DOMAIN}-override.conf"

    sed \
        -e "s/{{BARE_DOMAIN}}/$DOMAIN/g" \
        -e "s/{{WWW_DOMAIN}}/$WWW_DOMAIN/g" \
        -e "s/{{CERT_NAME}}/$DOMAIN/g" \
        -e "s/{{BACKEND_CONTAINER}}/$BACKEND_CONTAINER/g" \
        -e "s/{{VAR_NAME}}/$VAR_NAME/g" \
        "$TEMPLATE_FILE" > "$OUTPUT_FILE"

    success "Đã tạo: $OUTPUT_FILE"
else
    warning "Không tải được template từ GitHub — bỏ qua bước tạo file override. Tự tạo thủ công nếu cần."
fi

# ====== 4. CLEAN + RELOAD SITE ======
log "Chạy ee site clean và ee site reload..."
ee site clean "$DOMAIN" || warning "ee site clean gặp lỗi, kiểm tra thủ công."
ee site reload "$DOMAIN" || warning "ee site reload gặp lỗi, kiểm tra thủ công."
success "Đã clean + reload site."

# ====== RELOAD NGINX-PROXY ĐỂ ÁP DỤNG FILE OVERRIDE ======
log "Reload nginx-proxy để áp dụng file override..."
ee service reload nginx-proxy || warning "Reload nginx-proxy thất bại, kiểm tra thủ công."

# ====== TỔNG KẾT ======
echo ""
echo "=========================================="
success "Hoàn tất chuyển Main Site: $DOMAIN -> $WWW_DOMAIN"
echo "=========================================="
cat << EOF

${GREEN}Kiểm tra lại:${NC}
  ee shell $DOMAIN --command='wp site list --allow-root'
  ee shell $DOMAIN --command='wp option get siteurl --allow-root'
  ee shell $DOMAIN --command='wp option get home --allow-root'
  curl -IL https://$DOMAIN/
  curl -IL https://$WWW_DOMAIN/

EOF