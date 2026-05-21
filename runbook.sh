#!/usr/bin/env bash
# runbook.sh — CG-DETR 独立再現 Phase 0→1→2 実行スクリプト
# 作成: Sonnet (Phase 0), 2026-05-20
# 実行者: Codex (Phase 1/2)
#
# 使い方:
#   bash runbook.sh check         # 前提条件チェック
#   bash runbook.sh phase1_eval   # Phase 1: QVH eval
#   bash runbook.sh phase2_smoke  # Phase 2: smoke (10 epoch)
#   bash runbook.sh phase2_full   # Phase 2: full (200 epoch)
#
# 全コマンドはこのスクリプトから実行することでログを一元管理する。

set -euo pipefail

REPO=/home/menserve/CG-DETR/lighthouse
PYTHON=/home/menserve/CG-DETR/.venv/bin/python
LOGS=/home/menserve/CG-DETR/logs
DOWNLOADS=/home/menserve/CG-DETR/downloads

cd "$REPO"
export PYTHONPATH="$REPO:${PYTHONPATH:-}"
# WSL2 CUDA stub libs may not be in ldconfig depending on session context
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
mkdir -p "$LOGS"

# ============================================================
check() {
    echo "=== 前提条件チェック ==="

    echo "[GPU]"
    echo "  LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "  libcuda.so.1: $(ldconfig -p 2>/dev/null | grep -m1 'libcuda.so.1' || echo 'NOT FOUND')"
    "$PYTHON" -c "
import torch
print('  torch:', torch.__version__)
print('  cuda:', torch.cuda.is_available())
print('  device_count:', torch.cuda.device_count())
if torch.cuda.is_available():
    print('  gpu:', torch.cuda.get_device_name(0))
    print('  vram:', round(torch.cuda.get_device_properties(0).total_memory/1e9, 1), 'GB')
else:
    print('  FAIL: cuda not available — check LD_LIBRARY_PATH and /usr/lib/wsl/lib/')
"

    echo ""
    echo "[lighthouse import]"
    "$PYTHON" -c "import lighthouse; print('lighthouse: OK')"

    echo ""
    echo "[CASTELLA features]"
    CLAP_N=$(ls "$REPO/features/castella/clap/" | wc -l)
    CLAP_TEXT_N=$(ls "$REPO/features/castella/clap_text/" | wc -l)
    echo "  castella/clap: $CLAP_N files (expected: 1862)"
    echo "  castella/clap_text: $CLAP_TEXT_N files (expected: 3881)"

    echo ""
    echo "[Clotho-moment features]"
    CLO_CLAP_N=$(ls "$REPO/features/clotho-moment/clap/" | wc -l)
    CLO_TEXT_N=$(ls "$REPO/features/clotho-moment/clap_text/" | wc -l)
    echo "  clotho-moment/clap: $CLO_CLAP_N files (expected: 51240)"
    echo "  clotho-moment/clap_text: $CLO_TEXT_N files (expected: 44261)"

    echo ""
    echo "[pretrained_weights.zip]"
    if ls "$DOWNLOADS/pretrained_weights.zip" 2>/dev/null; then
        echo "  OK: $(du -sh $DOWNLOADS/pretrained_weights.zip | cut -f1)"
    elif ls "$DOWNLOADS/pretrained_weights.zip"*.part 2>/dev/null; then
        echo "  PARTIAL: $(du -sh $DOWNLOADS/pretrained_weights.zip*.part | cut -f1) (ダウンロード中)"
    else
        echo "  MISSING: gdown 1jxs_bvwttXTF9Lk3aKLohkqfYOonLyrO でダウンロード"
    fi

    echo ""
    echo "[QVH features]"
    if ls "$REPO/features/qvhighlight/" 2>/dev/null; then
        echo "  OK: features/qvhighlight/ 存在"
    else
        echo "  MISSING: ブラウザから手動 DL が必要"
        echo "  URL: https://drive.google.com/file/d/1-ALnsXkA4csKh71sRndMwybxEDqa-dM4/view"
        echo "  保存先: $DOWNLOADS/qvhighlights_features.tar.gz"
        echo "  解凍: tar -xzf $DOWNLOADS/qvhighlights_features.tar.gz -C features/"
    fi

    echo ""
    echo "[Phase 1 CG-DETR ckpt]"
    CG_CKPT=$(find "$REPO/results" -path "*cg_detr*qvhighlight*" -name "best.ckpt" 2>/dev/null | head -1 || true)
    if [ -n "$CG_CKPT" ]; then
        echo "  OK: $CG_CKPT"
    else
        echo "  MISSING: pretrained_weights.zip の解凍が必要"
    fi
}

# ============================================================
setup_qvh() {
    echo "=== QVH セットアップ ==="

    # pretrained_weights.zip 解凍
    if [ ! -f "$DOWNLOADS/pretrained_weights.zip" ]; then
        echo "ERROR: $DOWNLOADS/pretrained_weights.zip が存在しない"
        exit 1
    fi
    echo "pretrained_weights.zip を解凍中..."
    unzip -q "$DOWNLOADS/pretrained_weights.zip" -d "$REPO"
    echo "解凍完了。CG-DETR ckpt パス:"
    find "$REPO" -path "*cg_detr*qvhighlight*" -name "best.ckpt" | head -5

    # QVH features 解凍 (zip 形式、上ケースは QVHighlight/ で解凍される)
    if [ -d "$REPO/features/QVHighlight" ] || [ -d "$REPO/features/qvhighlight" ]; then
        echo "QVH features は既に解凍済み。スキップ"
    elif [ -f "$DOWNLOADS/QVHighlight.zip" ]; then
        echo "QVHighlight.zip を解凍中..."
        cd "$REPO/features" && unzip -q "$DOWNLOADS/QVHighlight.zip"
        cd "$REPO"
    elif [ -f "$DOWNLOADS/qvhighlights_features.tar.gz" ]; then
        echo "qvhighlights_features.tar.gz を解凍中..."
        tar -xzf "$DOWNLOADS/qvhighlights_features.tar.gz" -C "$REPO/features/"
    else
        echo "ERROR: QVH features アーカイブが見つからない"
        echo "ブラウザから手動 DL: https://drive.google.com/file/d/1-ALnsXkA4csKh71sRndMwybxEDqa-dM4/view"
        exit 1
    fi
    # config.py は小文字 qvhighlight/ を要求するので symlink
    if [ -d "$REPO/features/QVHighlight" ] && [ ! -e "$REPO/features/qvhighlight" ]; then
        ln -s QVHighlight "$REPO/features/qvhighlight"
    fi
    echo "解凍完了。features/qvhighlight:"
    ls "$REPO/features/qvhighlight/"
}

# ============================================================
phase1_eval() {
    echo "=== Phase 1: QVH CG-DETR eval ==="
    LOG="$LOGS/phase1_qvh_eval_$(date +%Y%m%d_%H%M%S).log"

    # ckpt パスを自動探索
    CKPT=$(find "$REPO/results" -path "*cg_detr*qvhighlight*" -name "best.ckpt" 2>/dev/null | head -1)
    if [ -z "$CKPT" ]; then
        echo "ERROR: CG-DETR QVH ckpt が見つからない。setup_qvh を先に実行すること"
        exit 1
    fi
    echo "Using ckpt: $CKPT"

    "$PYTHON" training/evaluate.py \
        --model cg_detr \
        --dataset qvhighlight \
        --feature clip_slowfast \
        --split val \
        --model_path "$CKPT" \
        --eval_path data/qvhighlight/highlight_val_release.jsonl \
        2>&1 | tee "$LOG"

    echo "Log saved: $LOG"
    echo "Metrics:"
    grep -E "R1|mAP|metric" "$LOG" | tail -20
}

# ============================================================
phase2_smoke() {
    echo "=== Phase 2: Smoke (epoch=10) ==="
    WRAPPER=/home/menserve/CG-DETR/train_with_override.py

    # B0 smoke
    echo "--- B0: CASTELLA direct (smoke, epoch=10) ---"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr \
        --dataset castella \
        --feature clap \
        --n_epoch 10 \
        --seed 2023 \
        --results_dir results/smoke_b0 \
        2>&1 | tee "$LOGS/phase2_b0_smoke.log"

    # B1 pretrain smoke
    echo "--- B1 pretrain: Clotho (smoke, epoch=10) ---"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr \
        --dataset clotho-moment \
        --feature clap \
        --n_epoch 10 \
        --seed 2023 \
        --results_dir results/smoke_b1_pretrain \
        2>&1 | tee "$LOGS/phase2_b1_pretrain_smoke.log"

    # B1 finetune smoke
    echo "--- B1 finetune: CASTELLA (smoke, epoch=10) ---"
    PRETRAIN_CKPT="$REPO/results/smoke_b1_pretrain/best.ckpt"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr \
        --dataset castella \
        --feature clap \
        --n_epoch 10 \
        --seed 2023 \
        --resume "$PRETRAIN_CKPT" \
        --results_dir results/smoke_b1_finetune \
        2>&1 | tee "$LOGS/phase2_b1_finetune_smoke.log"

    echo "=== Smoke 結果サマリ ==="
    echo "B0 smoke:"
    grep -E "R1|mAP" "$LOGS/phase2_b0_smoke.log" | tail -5
    echo "B1 finetune smoke:"
    grep -E "R1|mAP" "$LOGS/phase2_b1_finetune_smoke.log" | tail -5
}

# ============================================================
phase2_full() {
    echo "=== Phase 2: Full chain with early stopping (max 100 ep, patience 15) ==="
    WRAPPER=/home/menserve/CG-DETR/train_with_override.py
    MAX_EP=100
    PATIENCE=15
    SEED=2023
    TS=$(date +%Y%m%d_%H%M%S)

    # B0
    echo "--- [1/3] B0: CASTELLA direct (max ${MAX_EP}ep, patience ${PATIENCE}) ---"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr --dataset castella --feature clap \
        --n_epoch $MAX_EP --es_patience $PATIENCE --seed $SEED \
        --results_dir results/full_b0 \
        2>&1 | tee "$LOGS/phase2_b0_full_${TS}.log"

    # B1 pretrain
    echo "--- [2/3] B1 pretrain: Clotho (max ${MAX_EP}ep, patience ${PATIENCE}) ---"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr --dataset clotho-moment --feature clap \
        --n_epoch $MAX_EP --es_patience $PATIENCE --seed $SEED \
        --results_dir results/full_b1_pretrain \
        2>&1 | tee "$LOGS/phase2_b1_pretrain_full_${TS}.log"

    # B1 finetune
    PRETRAIN_CKPT="$REPO/results/full_b1_pretrain/best.ckpt"
    if [ ! -f "$PRETRAIN_CKPT" ]; then
        echo "ERROR: B1 pretrain ckpt not found: $PRETRAIN_CKPT"; exit 1
    fi
    echo "--- [3/3] B1 finetune: CASTELLA from Clotho (max ${MAX_EP}ep, patience ${PATIENCE}) ---"
    "$PYTHON" "$WRAPPER" \
        --model cg_detr --dataset castella --feature clap \
        --n_epoch $MAX_EP --es_patience $PATIENCE --seed $SEED \
        --resume "$PRETRAIN_CKPT" \
        --results_dir results/full_b1_finetune \
        2>&1 | tee "$LOGS/phase2_b1_finetune_full_${TS}.log"

    echo ""
    echo "=== Phase 2 Full Chain 完了 ==="
    for run in full_b0 full_b1_pretrain full_b1_finetune; do
        f="$REPO/results/${run}/best_castella_val_preds_metrics.json"
        [ -f "$f" ] || f="$REPO/results/${run}/best_clotho-moment_val_preds_metrics.json"
        if [ -f "$f" ]; then
            echo "--- $run ---"
            "$PYTHON" -c "import json; d=json.load(open('$f'))['brief']; [print(f'  {k}: {v}') for k,v in d.items()]"
        fi
    done
}

# ============================================================
CMD="${1:-help}"
case "$CMD" in
    check)        check ;;
    setup_qvh)    setup_qvh ;;
    phase1_eval)  phase1_eval ;;
    phase2_smoke) phase2_smoke ;;
    phase2_full)  phase2_full ;;
    *)
        echo "Usage: bash runbook.sh [check|setup_qvh|phase1_eval|phase2_smoke|phase2_full]"
        ;;
esac
