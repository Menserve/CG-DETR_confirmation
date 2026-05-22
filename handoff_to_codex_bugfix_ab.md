# handoff_to_codex_bugfix_ab.md — Bug fix 後 A/B 検証 (Stage 1→2→3)

宛先: Codex
作成: Opus, 2026-05-21
目的: lighthouse cg_detr のバグ修正後、CASTELLA val R1@0.7 が UVCOM gate (31.82) を超えるかを段階的に検証

---

## 1. 背景

- Codex が lighthouse 実装に 2 件の bug を発見・修正済 (`cg_detr.py` の false-negative loss 加算先、`models.py` のタイポ)
- 同一 ckpt 比較で saliency 損失 +16.78%、総損失 +3.01% → 学習シグナル弱化が判明
- 既存の棄却支持判定は **buggy 実装** での結果なので **前提崩れ → 判定保留**
- 本タスクで fix 後再学習し、判定を確定する

詳細背景: [DECISION_INPUT.md](DECISION_INPUT.md) と最新 Opus 応答 (このセッションの直前ターン)

---

## 2. 実施全体像 (打ち切り条件付き 3 段階)

```
[Stage 1: 既存 pretrain ckpt + finetune fix, seed=2023]
   ↓ R1@0.7 結果で分岐
   ├── < 26 → [打ち切り] Stage 2 進まず、棄却維持で報告
   └── ≥ 26 → [Stage 2 へ]

[Stage 2: Full B1 chain (pretrain も fix で再学習), seed=2023]
   ↓ R1@0.7 結果で分岐
   ├── < 30 → [打ち切り] Stage 3 進まず、棄却維持で報告
   └── ≥ 30 → [Stage 3 へ]

[Stage 3: multi-seed B1 chain (fix), seeds 42, 1234]
   → mean ± std を計算、棄却再考の根拠材料を出す
```

**重要**: 各 stage 完了後に **必ず R1@0.7 を確認してから次に進むか判断**。判断ロジックは下記コマンド例参照。

---

## 3. 共通の前提条件

### 3.1 環境チェック (各 Stage 開始時に毎回実行)

```bash
bash /home/menserve/CG-DETR/runbook.sh check
```

`cuda: True / NVIDIA GeForce RTX 5090` が出ない場合は中止して報告。

### 3.2 不変ルール (CANON 8節)

- team_repo は読み取りのみ
- lighthouse 上流コードは **既に bug fix のため例外的に修正済** だが、それ以外の編集禁止
- 各実験は別 `--results_dir` を使う (既存上書き禁止)
- 全コマンド・全 metric・全 artifact path をログ化
- ckpt / log は .gitignore 除外、コミット不要

---

## 4. Stage 1: Finetune-only fix test

### 4.1 目的

既存の buggy pretrain ckpt を再利用したまま、**finetune 段階だけ fix された** 状態で学習し、buggy seed=2023 (R1@0.7=23.86) と直接比較する。

### 4.2 実行コマンド

```bash
WRAPPER=/home/menserve/CG-DETR/train_with_override.py
PYTHON=/home/menserve/CG-DETR/.venv/bin/python
PRETRAIN=/home/menserve/CG-DETR/lighthouse/results/full_b1_pretrain/best.ckpt

"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset castella --feature clap \
  --n_epoch 100 --es_patience 15 --seed 2023 \
  --resume "$PRETRAIN" \
  --results_dir results/fix_stage1_b1ft \
  2>&1 | tee /home/menserve/CG-DETR/logs/fix_stage1_b1ft.log
```

### 4.3 打ち切り判断ロジック

完了後に下記スクリプトで自動判定:

```bash
RESULT=/home/menserve/CG-DETR/lighthouse/results/fix_stage1_b1ft/best_castella_val_preds_metrics.json
R1_07=$($PYTHON -c "import json; print(json.load(open('$RESULT'))['brief']['MR-full-R1@0.7'])")
echo "Stage 1 R1@0.7: $R1_07"

# 自動判定 (bash で実装)
$PYTHON -c "
import json
r = json.load(open('$RESULT'))['brief']['MR-full-R1@0.7']
if r < 26:
    print(f'[STAGE 1 ABORT] R1@0.7={r} < 26.0 → Stage 2 に進まず、棄却維持で Opus 報告')
elif r < 30:
    print(f'[STAGE 1 PROCEED to STAGE 2] R1@0.7={r} ≥ 26.0、Stage 2 へ')
else:
    print(f'[STAGE 1 STRONG SIGNAL] R1@0.7={r} ≥ 30.0、Stage 2 をスキップして直接 Stage 3 へ進む選択肢あり (判断は Opus に委ねる)')
"
```

### 4.4 Stage 1 完了報告 (Opus に渡す内容)

- R1@0.5 / R1@0.7 / mAP / mAP@0.5 / mAP@0.75 (best ckpt)
- 実 epoch 数 / early stop trigger epoch
- 判定 (ABORT / PROCEED / STRONG SIGNAL)
- ログパス

---

## 5. Stage 2: End-to-end full B1 chain with fix

### 5.1 目的

pretrain も buggy だった点を解消し、**完全な fix 版** で B1 chain を再現する。

### 5.2 実行コマンド

```bash
WRAPPER=/home/menserve/CG-DETR/train_with_override.py
PYTHON=/home/menserve/CG-DETR/.venv/bin/python

# Stage 2a: B1 pretrain (Clotho) を fix で再学習
"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset clotho-moment --feature clap \
  --n_epoch 100 --es_patience 15 --seed 2023 \
  --results_dir results/fix_stage2_b1_pretrain \
  2>&1 | tee /home/menserve/CG-DETR/logs/fix_stage2_b1_pretrain.log

# Stage 2b: 新 pretrain ckpt から B1 finetune
NEW_PRETRAIN=/home/menserve/CG-DETR/lighthouse/results/fix_stage2_b1_pretrain/best.ckpt

if [ ! -f "$NEW_PRETRAIN" ]; then
  echo "[ERROR] Stage 2a の pretrain ckpt が存在しない。中止して報告"
  exit 1
fi

"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset castella --feature clap \
  --n_epoch 100 --es_patience 15 --seed 2023 \
  --resume "$NEW_PRETRAIN" \
  --results_dir results/fix_stage2_b1ft \
  2>&1 | tee /home/menserve/CG-DETR/logs/fix_stage2_b1ft.log
```

### 5.3 打ち切り判断ロジック

```bash
RESULT=/home/menserve/CG-DETR/lighthouse/results/fix_stage2_b1ft/best_castella_val_preds_metrics.json
$PYTHON -c "
import json
r = json.load(open('$RESULT'))['brief']['MR-full-R1@0.7']
if r < 30:
    print(f'[STAGE 2 ABORT] R1@0.7={r} < 30.0 → Stage 3 に進まず、棄却維持で Opus 報告')
else:
    print(f'[STAGE 2 PROCEED to STAGE 3] R1@0.7={r} ≥ 30.0、multi-seed 検証へ')
"
```

### 5.4 Stage 2 完了報告

- B1 pretrain (Clotho val) の best metrics (健全性確認用)
- B1 finetune (CASTELLA val) の R1@0.5 / R1@0.7 / mAP / mAP@0.5 / mAP@0.75
- 各 stage の実 epoch 数 / early stop epoch
- 判定 (ABORT / PROCEED)
- ログパス

---

## 6. Stage 3: Multi-seed 頑健化

### 6.1 目的

Stage 2 で gate 突破した場合、seed variance を確認して棄却再考の信頼度を上げる。

### 6.2 実行コマンド

Stage 2 の pretrain ckpt (fix 済み) を共有して、finetune だけ multi-seed:

```bash
WRAPPER=/home/menserve/CG-DETR/train_with_override.py
PYTHON=/home/menserve/CG-DETR/.venv/bin/python
PRETRAIN=/home/menserve/CG-DETR/lighthouse/results/fix_stage2_b1_pretrain/best.ckpt

for SEED in 42 1234; do
  echo "=== Stage 3: B1 ft seed=$SEED (fix) ==="
  "$PYTHON" "$WRAPPER" \
    --model cg_detr --dataset castella --feature clap \
    --n_epoch 100 --es_patience 15 --seed $SEED \
    --resume "$PRETRAIN" \
    --results_dir results/fix_stage3_b1ft_seed${SEED} \
    2>&1 | tee /home/menserve/CG-DETR/logs/fix_stage3_b1ft_seed${SEED}.log
done
```

### 6.3 集計

3 seed (2023 from Stage 2, 42 / 1234 from Stage 3) で mean ± std を計算:

```bash
$PYTHON << 'EOF'
import json, statistics
seeds = {
    2023: '/home/menserve/CG-DETR/lighthouse/results/fix_stage2_b1ft/best_castella_val_preds_metrics.json',
    42:   '/home/menserve/CG-DETR/lighthouse/results/fix_stage3_b1ft_seed42/best_castella_val_preds_metrics.json',
    1234: '/home/menserve/CG-DETR/lighthouse/results/fix_stage3_b1ft_seed1234/best_castella_val_preds_metrics.json',
}
metrics = ['MR-full-R1@0.5', 'MR-full-R1@0.7', 'MR-full-mAP']
for m in metrics:
    vals = [json.load(open(p))['brief'][m] for p in seeds.values()]
    print(f"{m}: {statistics.mean(vals):.2f} ± {statistics.stdev(vals):.2f}  (per seed: {vals})")
EOF
```

### 6.4 Stage 3 完了報告

- 各 seed の主要 metrics
- 3 seed の mean ± std (R1@0.5 / R1@0.7 / mAP)
- gate (31.82) との関係:
  - mean ≥ gate → **棄却再考の強い根拠**
  - mean < gate だが mean + 1σ ≥ gate → **棄却再考は条件付き**
  - mean + 1σ < gate → **棄却維持** (fix しても変わらず)
- ログパス

---

## 7. 全 Stage 完了後の最終報告フォーマット

Opus に以下の形式で報告:

```markdown
# Bug fix A/B 結果報告

## Stage 1 (finetune-only fix)
- R1@0.5 / R1@0.7 / mAP: ...
- 判定: [ABORT / PROCEED / STRONG SIGNAL]

## Stage 2 (full chain fix, seed=2023)
- pretrain Clotho val R1@0.7: ...
- finetune CASTELLA val: R1@0.5 / R1@0.7 / mAP: ...
- 判定: [ABORT / PROCEED]

## Stage 3 (multi-seed, if proceeded)
- seed 2023: R1@0.7 ...
- seed 42: R1@0.7 ...
- seed 1234: R1@0.7 ...
- mean ± std (R1@0.7): ...

## gate (31.82) との関係
- ...

## 想定外の事象
- ...

## アーティファクト
- ckpt: results/fix_stage*_*/best.ckpt
- log: logs/fix_stage*_*.log
```

---

## 8. 想定所要時間

| Stage | 内容 | 所要 |
|-------|------|------|
| 1 | 既存 pretrain + finetune fix | ~15 分 |
| 2 | pretrain (75min) + finetune (15min) fix | ~90 分 |
| 3 | finetune × 2 seed (fix) | ~30 分 |
| **最短 (Stage 1 abort)** | | **~15 分** |
| **中間 (Stage 2 abort)** | | **~105 分** |
| **完了 (Stage 3 まで)** | | **~135 分 (2h15m)** |

---

## 9. Opus が引き継いで行う作業 (Codex 完了後)

- 結果を [DECISION_INPUT.md](DECISION_INPUT.md) に反映 (棄却支持 / 棄却維持 / 棄却再考のいずれかに確定)
- [RESULTS_CASTELLA.md](RESULTS_CASTELLA.md) に fix 後結果を追記
- [CANON.md](CANON.md) を最新状態に更新
- 必要なら team_repo 側へのフィードバック案を作成

Codex は文書更新は行わない (結果報告のみ)。
