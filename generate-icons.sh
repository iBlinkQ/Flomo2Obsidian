#!/bin/bash

# 图标生成脚本
# 将 SVG 转换为 macOS 应用所需的所有尺寸

SVG_FILE="app-icon.svg"
OUTPUT_DIR="Flomo2Obsidian/Flomo2Obsidian/Assets.xcassets/AppIcon.appiconset"

# 检查 SVG 文件是否存在
if [ ! -f "$SVG_FILE" ]; then
    echo "错误: 找不到 $SVG_FILE"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "开始生成图标..."

# 定义需要的尺寸
declare -a sizes=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png"
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
)

# 使用 sips (macOS 内置工具) 转换
for item in "${sizes[@]}" ; do
    SIZE="${item%%:*}"
    FILENAME="${item##*:}"

    echo "生成 ${SIZE}x${SIZE} -> $FILENAME"

    # 先转换 SVG 为 PNG (1024x1024)
    qlmanage -t -s 1024 -o . "$SVG_FILE" 2>/dev/null

    # 调整大小
    sips -z $SIZE $SIZE "${SVG_FILE}.png" --out "$OUTPUT_DIR/$FILENAME" >/dev/null 2>&1
done

# 清理临时文件
rm -f "${SVG_FILE}.png"

echo "✅ 图标生成完成！"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""
echo "下一步："
echo "1. 在 Xcode 中打开项目"
echo "2. 选择 Assets.xcassets -> AppIcon"
echo "3. 图标应该已经自动显示"
echo "4. 重新构建项目"
