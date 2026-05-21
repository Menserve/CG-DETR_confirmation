# handoff_to_codex.md — Phase 1/2 実行指示書
宛先: Codex  
作成: Sonnet (Phase 0)  
日付: 2026-05-20

---

## 概要

独立環境の準備が完了した。本ファイルに従って Phase 1 (QVH eval) と Phase 2 (Clotho→CASTELLA) を実行すること。

**絶対禁則事項**:
- `/home/menserve/compe_YCU/team_repo/` は一切触らない
- lighthouse ソースコードを直接編集しない (外部 config/patch で対応)
- 不明点は推測で埋めず「未確認」と記録する
- 全コマンド・全 metric・全 artifact path をログ化する

---

## 環境

```bash
# 作業ディレクトリ
REPO=/home/menserve/CG-DETR/lighthouse

# Python interpreter
PYTHON=/home/menserve/CG-DETR/.venv/bin/python

# 全コマンドはこの前置きで実行
cd $REPO && $PYTHON training/train.py ...
```

---

## Phase 1: QVHighlights CG-DETR 公式 eval

### 前提条件 (Codex 実行前に確認)

1. **pretrained_weights.zip が完了していること**
   ```bash
   ls -lh /home/menserve/CG-DETR/downloads/pretrained_weights.zip
   # ファイル名に `.part` が残っていれば未完了
   ```

2. **QVH features が手動 DL されていること**
   - 手動 DL 先: https://drive.google.com/file/d/1-ALnsXkA4csKh71sRndMwybxEDqa-dM4/view
   - 保存先: `/home/menserve/CG-DETR/downloads/qvhighlights_features.tar.gz`

### Phase 1 手順

```bash
# Step 1: pretrained weights を解凍 (HOME に展開 — README 指定)
cd /home/menserve/CG-DETR/lighthouse
unzip /home/menserve/CG-DETR/downloads/pretrained_weights.zip

# Step 1b: 解凍後の構造確認 (ckpt パスを特定)
find . -path "*/cg_detr/qvhighlight*" -name "best.ckpt" | head -5

# Step 2: QVH features を解凍
tar -xzf /home/menserve/CG-DETR/downloads/qvhighlights_features.tar.gz -C features/
# 解凍後の構造を確認:
ls features/QVHighlight/   # または features/qvhighlight/

# Step 3: eval 実行 (val split)
cd /home/menserve/CG-DETR/lighthouse
/home/menserve/CG-DETR/.venv/bin/python training/evaluate.py \
  --model cg_detr \
  --dataset qvhighlight \
  --feature clip_slowfast \
  --split val \
  --model_path results/cg_detr/qvhighlight/clip_slowfast/best.ckpt \
  --eval_path data/qvhighlight/highlight_val_release.jsonl \
  2>&1 | tee /home/menserve/CG-DETR/logs/phase1_qvh_eval.log

# ckpt パスが不明な場合は find で探す:
# find results/ -path "*cg_detr*qvhighlight*" -name "best.ckpt"
```

### Phase 1 記録対象 Metrics

`/home/menserve/CG-DETR/RESULTS_QVH.md` に以下を記録:

| Metric | 実測値 | 論文/README 参照値 | 差分 |
|--------|--------|-------------------|------|
| R1@0.5 | | | |
| R1@0.7 | | | |
| mAP avg | | | |
| mAP@0.5 | | | |
| mAP@0.75 | | | |

**論文参照値** (lighthouse README 記載の CG-DETR, clip_slowfast):
- README には具体的数値の記載なし → CG-DETR 論文 (arXiv: 2311.12533) Table 1 を参照:
  - R1@0.5: 65.43, R1@0.7: 48.38, mAP@0.5: 62.26, mAP@0.75: 40.49, mAP avg: 47.81

---

## Phase 2: Clotho-Moment → CASTELLA 転移チェック

### 前提条件
- Phase 1 の前提条件は不要 (CASTELLA/Clotho features は既に配置済み)
- features/castella/ と features/clotho-moment/ の symlink が有効であること

### Phase 2 実験構成

| 実験 | コマンド | 出力先 |
|------|---------|--------|
| B0: CASTELLA 直接学習 | 下記参照 | results/cg_detr/castella/clap/ |
| B1: Clotho pretrain | 下記参照 | results/cg_detr/clotho-moment/clap/ |
| B1b: CASTELLA finetune | 下記参照 | results/cg_detr/castella_finetune/clap/ |

### Phase 2 コマンド

```bash
cd /home/menserve/CG-DETR/lighthouse
PYTHON=/home/menserve/CG-DETR/.venv/bin/python

# ------ B0: CASTELLA 直接学習 (smoke: n_epoch=10) ------
$PYTHON training/train.py \
  --model cg_detr \
  --dataset castella \
  --feature clap \
  --n_epoch 10 \
  --seed 2023 \
  2>&1 | tee /home/menserve/CG-DETR/logs/phase2_b0_smoke.log

# ------ B0: 本学習 (n_epoch=200) ------
$PYTHON training/train.py \
  --model cg_detr \
  --dataset castella \
  --feature clap \
  --seed 2023 \
  2>&1 | tee /home/menserve/CG-DETR/logs/phase2_b0_full.log

# ------ B1 Step1: Clotho pretrain ------
$PYTHON training/train.py \
  --model cg_detr \
  --dataset clotho-moment \
  --feature clap \
  --seed 2023 \
  2>&1 | tee /home/menserve/CG-DETR/logs/phase2_b1_pretrain.log

# ------ B1 Step2: CASTELLA finetune ------
$PYTHON training/train.py \
  --model cg_detr \
  --dataset castella \
  --feature clap \
  --seed 2023 \
  --resume results/cg_detr/clotho-moment/clap/best.ckpt \
  --results_dir results/cg_detr_castella_finetune \
  2>&1 | tee /home/menserve/CG-DETR/logs/phase2_b1_finetune.log
```

**小実験フロー**:
1. まず B0 smoke (epoch=10) と B1 smoke (clotho pretrain epoch=10 → castella finetune epoch=10) を実行
2. smoke で R1@0.5 に有意差 (>2pt) が出る方向ならば本学習に進む
3. 差がなければ「独立再現では転移効果なし」として記録

### Phase 2 記録対象

`/home/menserve/CG-DETR/RESULTS_CASTELLA.md` に以下を記録:

| 実験 | R1@0.5 | R1@0.7 | mAP avg | mAP@0.5 | mAP@0.75 | epoch | seed |
|------|--------|--------|---------|---------|---------|-------|------|
| B0 smoke | | | | | | 10 | 2023 |
| B1 smoke | | | | | | 10+10 | 2023 |
| B0 full | | | | | | 200 | 2023 |
| B1 full | | | | | | 200+200 | 2023 |

---

## ログ・成果物の保存先

```
/home/menserve/CG-DETR/
├── logs/
│   ├── phase1_qvh_eval.log
│   ├── phase2_b0_smoke.log
│   ├── phase2_b0_full.log
│   ├── phase2_b1_pretrain.log
│   └── phase2_b1_finetune.log
├── RESULTS_QVH.md       (Phase 1 完了後に作成)
├── RESULTS_CASTELLA.md  (Phase 2 完了後に作成)
└── DECISION_INPUT.md    (Phase 1+2 完了後に作成 — Opus 向け)
```

---

## トラブルシューティング

### import エラー
```bash
# training/ 以下は sys.path にない場合がある
cd /home/menserve/CG-DETR/lighthouse
export PYTHONPATH=/home/menserve/CG-DETR/lighthouse:$PYTHONPATH
```

### QVH features の解凍先が合わない
features/ 以下に展開して、config.py が期待するパス (`features/qvhighlight/clip` 等) を確認:
```bash
grep -n "qvhighlight\|clip\|slowfast" /home/menserve/CG-DETR/lighthouse/training/config.py | head -20
```

### ckpt パスが見つからない
pretrained_weights.zip を解凍後:
```bash
find /home/menserve/CG-DETR/lighthouse -name "best.ckpt" | grep -i "cg_detr" | head -20
```

### CASTELLA clap ファイル数不足
symlink 確認:
```bash
ls /home/menserve/CG-DETR/lighthouse/features/castella/clap/ | wc -l   # 期待: 1862
ls /home/menserve/CG-DETR/lighthouse/features/castella/clap_text/ | wc -l  # 期待: 3881
```
