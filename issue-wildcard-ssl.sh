#!/bin/bash
###########################################################
# Script: Issue Wildcard SSL (*.domain.com) via acme.sh
# Dùng cho: ee site create www.domain.com --ssl=custom --wpsubdom
# Lấy credentials từ: ee config get le-mail / cloudflare-api-key
# Auto-renewal: dùng crontab hệ thống (không dùng ee cron)
###########################################################

set -e

# ====== CONFIG ======
DOMAIN="${1:-}"
ACME_HOME="/root/.acme.sh"
CERT_DIR="/opt/easyengine/services/nginx-proxy/certs"
ACME_CMD="$ACME_HOME/acme.sh"
EE_BIN=$(command -v ee || echo "/usr/local/bin/ee")
CRON_SCHEDULE="30 0 * * *"   # 00:30 hàng ngày

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'

log()     { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
error()   { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}" >&2; }

# ====== ROOT CHECK ======
[[ $EUID -ne 0 ]] && error "Script cần chạy với quyền root (sudo)."

# ====== DOMAIN ======
if [ -z "$DOMAIN" ]; then
    read -p "Nhập domain gốc (ví dụ: domain.com): " DOMAIN
fi
DOMAIN=$(echo "$DOMAIN" | tr '[:upper:]' '[:lower:]' | xargs)
[[ -z "$DOMAIN" ]] && error "Domain không được để trống."
success "Domain: $DOMAIN (sẽ cấp cho: $DOMAIN, *.$DOMAIN)"

# ====== LẤY CREDENTIALS TỪ EE CONFIG ======
log "Đọc cấu hình từ ee config..."

LE_MAIL=$("$EE_BIN" config get le-mail 2>/dev/null || echo "")
CF_API_KEY=$("$EE_BIN" config get cloudflare-api-key 2>/dev/null || echo "")

if [ -z "$LE_MAIL" ]; then
    read -p "ee config chưa có le-mail. Nhập email Let's Encrypt: " LE_MAIL
fi
if [ -z "$CF_API_KEY" ]; then
    read -sp "ee config chưa có cloudflare-api-key. Nhập Cloudflare Global API Key: " CF_API_KEY
    echo
fi
[[ -z "$LE_MAIL" || -z "$CF_API_KEY" ]] && error "Thiếu email hoặc Cloudflare API Key."

success "Email: $LE_MAIL"
success "Cloudflare API Key: ${CF_API_KEY:0:5}****${CF_API_KEY: -5}"

export CF_Email="$LE_MAIL"
export CF_Key="$CF_API_KEY"

# ====== CÀI ĐẶT ACME.SH NẾU CHƯA CÓ ======
if [ ! -f "$ACME_CMD" ]; then
    log "Cài đặt acme.sh..."
    curl -s https://get.acme.sh | sh -s email="$LE_MAIL" > /dev/null 2>&1 \
        || error "Cài đặt acme.sh thất bại."
    success "Đã cài đặt acme.sh tại $ACME_HOME"
else
    success "acme.sh đã có sẵn tại $ACME_HOME"
fi

# ====== CẤP CHỨNG CHỈ WILDCARD ======
log "Đang cấp chứng chỉ cho $DOMAIN và *.$DOMAIN (DNS-01 qua Cloudflare)..."

if ! "$ACME_CMD" --issue \
    --dns dns_cf \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --server letsencrypt \
    --force; then
    error "Cấp chứng chỉ thất bại. Kiểm tra lại Cloudflare API Key / quyền Zone.DNS."
fi
success "Cấp chứng chỉ thành công."

# ====== CÀI ĐẶT CERT VÀO ĐÚNG PATH CỦA EASYENGINE ======
mkdir -p "$CERT_DIR"

log "Cài đặt cert vào $CERT_DIR/$DOMAIN.crt / .key ..."

"$ACME_CMD" --install-cert \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --key-file       "$CERT_DIR/$DOMAIN.key" \
    --fullchain-file "$CERT_DIR/$DOMAIN.crt" \
    --reloadcmd      "$EE_BIN service reload nginx-proxy" \
    || error "Cài đặt cert vào EasyEngine thất bại."

chmod 600 "$CERT_DIR/$DOMAIN.key"
chmod 644 "$CERT_DIR/$DOMAIN.crt"
success "Đã cài đặt cert vào EasyEngine certs directory."

# ====== KIỂM TRA CERT ======
log "Kiểm tra chứng chỉ..."
openssl x509 -in "$CERT_DIR/$DOMAIN.crt" -noout -dates -subject -ext subjectAltName | sed 's/^/  /'

# ====== CHUẨN HOÁ LỊCH CRON HỆ THỐNG (không dùng ee cron) ======
log "Chuẩn hoá lịch renew trong crontab hệ thống..."

# Xoá mọi dòng cron cũ do acme.sh tự thêm (mặc định 4 lần/ngày), tránh trùng lặp
crontab -l 2>/dev/null | grep -v "acme.sh --cron" > /tmp/current_cron_$$ || true

# Thêm lại đúng 1 dòng, chạy 1 lần/ngày lúc 03:30
echo "$CRON_SCHEDULE \"$ACME_HOME\"/acme.sh --cron --home \"$ACME_HOME\" > /dev/null" >> /tmp/current_cron_$$

crontab /tmp/current_cron_$$
rm -f /tmp/current_cron_$$

success "Đã chuẩn hoá cron: chạy 1 lần/ngày lúc 03:30 (thay vì 4 lần/ngày mặc định)"

# ====== TỔNG KẾT ======
log ""
log "=========================================="
success "Hoàn tất!"
log "=========================================="
cat << EOF

${GREEN}Chứng chỉ cover:${NC}
  ✓ $DOMAIN
  ✓ *.$DOMAIN  (www., en., zh., mu., ... bất kỳ subdomain cấp 1 nào)

${GREEN}File cert:${NC}
  Key:  $CERT_DIR/$DOMAIN.key
  Cert: $CERT_DIR/$DOMAIN.crt

${GREEN}Dùng cho site MỚI (ee site create):${NC}
  ee site create www.$DOMAIN --wpsubdom \\
    --ssl=custom \\
    --ssl-key=$CERT_DIR/$DOMAIN.key \\
    --ssl-crt=$CERT_DIR/$DOMAIN.crt

${GREEN}Dùng cho site ĐÃ TỒN TẠI (copy cert sang đúng tên site):${NC}
  cp $CERT_DIR/$DOMAIN.crt $CERT_DIR/www.$DOMAIN.crt
  cp $CERT_DIR/$DOMAIN.key $CERT_DIR/www.$DOMAIN.key
  ee service reload nginx-proxy

${GREEN}Auto-renewal:${NC}
  Quản lý qua crontab hệ thống (KHÔNG dùng ee cron)
  Lịch: $CRON_SCHEDULE (1 lần/ngày, 00:30)
  Kiểm tra: crontab -l | grep acme.sh

${GREEN}Kiểm tra thủ công:${NC}
  $ACME_CMD --list
  crontab -l
  ee service reload nginx-proxy

EOF