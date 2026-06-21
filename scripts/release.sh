#!/usr/bin/env bash
# OpenP2P Magisk Module 一键发布脚本
# 用法: ./scripts/release.sh v3.25.11
# 作用:
#   1. 从上游 openp2p 下载指定版本的 android-arm64 二进制
#   2. 替换仓库内的 openp2p 二进制
#   3. 更新 module.prop / update.json / CHANGELOG.md
#   4. 重新打 zip 包

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "用法: $0 <version, e.g. v3.25.11>"
    exit 1
fi

# 去掉可能的 v 前缀
VERSION_NUM="${VERSION#v}"
# versionCode 用版本号去掉点的整数(不够6位补0)
VERSION_CODE=$(printf "%05d" "$(echo "$VERSION_NUM" | tr -d '.')")

# 计算 6 位 versionCode: 3.25.11 -> 32511
MAJOR=$(echo "$VERSION_NUM" | cut -d. -f1)
MINOR=$(echo "$VERSION_NUM" | cut -d. -f2)
PATCH=$(echo "$VERSION_NUM" | cut -d. -f3)
VERSION_CODE="${MAJOR}${MINOR}${PATCH}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# 镜像源
UPSTREAM_URL_PRIMARY="https://github.com/openp2p-cn/openp2p/releases/download/${VERSION}/openp2p-${VERSION_NUM}.android-arm64.tar.gz"
UPSTREAM_URL_MIRROR="https://gh-proxy.com/https://github.com/openp2p-cn/openp2p/releases/download/${VERSION}/openp2p-${VERSION_NUM}.android-arm64.tar.gz"

echo "==> 下载上游 ${VERSION} ..."
TARBALL="$TMPDIR/openp2p.tar.gz"
if curl -sSLf --max-time 120 -o "$TARBALL" "$UPSTREAM_URL_PRIMARY"; then
    echo "    从 GitHub 直连下载成功"
elif curl -sSLf --max-time 180 -o "$TARBALL" "$UPSTREAM_URL_MIRROR"; then
    echo "    通过 gh-proxy 镜像下载成功"
else
    echo "    错误: 下载失败, 请检查网络或版本号" >&2
    exit 1
fi

echo "==> 解压 ..."
tar -xzf "$TARBALL" -C "$TMPDIR"

if [ ! -f "$TMPDIR/openp2p" ]; then
    echo "    错误: 解压后未找到 openp2p 二进制" >&2
    exit 1
fi

echo "==> 替换 openp2p 二进制 ..."
chmod +x "$TMPDIR/openp2p"
cp "$TMPDIR/openp2p" "$REPO_ROOT/openp2p"

echo "==> 更新 module.prop ..."
sed -i "s|^version=.*|version=${VERSION}|" "$REPO_ROOT/module.prop"
sed -i "s|^versionCode=.*|versionCode=${VERSION_CODE}|" "$REPO_ROOT/module.prop"
# 用 # 作为分隔符避免 description 里的 | 与 sed 冲突
sed -i "s#^description=.*#description=OpenP2P内网穿透服务 | 官方${VERSION} | Token未配置#" "$REPO_ROOT/module.prop"

echo "==> 更新 update.json ..."
cat > "$REPO_ROOT/update.json" <<EOF
{
  "version": "${VERSION}",
  "versionCode": ${VERSION_CODE},
  "zipUrl": "https://github.com/232252/openp2p-magisk/releases/download/${VERSION}/openp2p-magisk-${VERSION}.zip",
  "changelog": "https://github.com/232252/openp2p-magisk/blob/main/CHANGELOG.md"
}
EOF

echo "==> 重新打包 ..."
OUTPUT="$REPO_ROOT/openp2p-magisk-${VERSION}.zip"
# 清理旧文件
rm -f "$REPO_ROOT"/openp2p-magisk-v*.zip
# 打 zip(从仓库根目录打)
cd "$REPO_ROOT"
zip -r "$OUTPUT" \
    action.sh \
    openp2p \
    openp2p_core.sh \
    post-fs-data.sh \
    service.sh \
    uninstall.sh \
    module.prop \
    update.json \
    config/ \
    CHANGELOG.md \
    LICENSE \
    README.md \
    -x "*.git*" "openp2p-magisk-v*.zip" "scripts/*"

echo ""
echo "==> 完毕!"
echo "    二进制: $REPO_ROOT/openp2p"
echo "    打包:   $OUTPUT"
echo "    版本:   ${VERSION} (versionCode ${VERSION_CODE})"
echo ""
echo "下一步:"
echo "    git add -A && git commit -m \"release: ${VERSION}\""
echo "    git tag ${VERSION} && git push --tags"
