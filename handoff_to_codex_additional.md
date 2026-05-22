# handoff_to_codex_additional.md — Phase 2 後の追加実験指示

宛先: Codex
作成: Opus, 2026-05-21
所要時間目安: 1-3 時間 (実施範囲による)

---

## 背景

Phase 2 full の主結果（[RESULTS_CASTELLA.md](RESULTS_CASTELLA.md), [DECISION_INPUT.md](DECISION_INPUT.md) 参照）:

- B1 finetune (CASTELLA from Clotho) val R1@0.7 = **23.86** vs UVCOM gate **31.82** → **gate 未達**
- 暫定判定: **棄却支持**

しかし以下の頑健化が未実施。GPT-5.5 判定の前にこれらを補強したい。

---

## 必読

1. `/home/menserve/CG-DETR/CANON.md` — 全体ルール、役割、起動法
2. `/home/menserve/CG-DETR/RESULTS_CASTELLA.md` — Phase 2 結果と懸念点 (4節)
3. `/home/menserve/CG-DETR/DECISION_INPUT.md` — 現在の暫定判定と留保点

---

## 事前確認

```bash
bash /home/menserve/CG-DETR/runbook.sh check
```

`cuda: True / RTX 5090` が出ない場合は中止して報告。

---

## 追加実験リスト (優先度順)

### EXP-A: CASTELLA test split eval (優先度: 高、最短)

**目的**: val だけでなく test split でも gate 未達かを確認。team_repo 棄却基準 (UVCOM test R1@0.7=23.68) との比較。

**所要**: 数分 (eval のみ、学習なし)

**手順**:
```bash
cd /home/menserve/CG-DETR/lighthouse
/home/menserve/CG-DETR/.venv/bin/python training/evaluate.py \
  --model cg_detr --dataset castella --feature clap \
  --split test \
  --model_path /home/menserve/CG-DETR/lighthouse/results/full_b1_finetune/best.ckpt \
  --eval_path data/castella/castella_test_release.jsonl \
  2>&1 | tee /home/menserve/CG-DETR/logs/exp_a_castella_test.log
```

**注**: evaluate.py の CLI 引数は train.py と仕様が異なる可能性あり。最初に `--help` で確認。必要なら `train_with_override.py` と同様の wrapper を作っても良い。

**記録対象**: CASTELLA test の R1@0.5 / R1@0.7 / mAP

---

### EXP-B: multi-seed B1 finetune (優先度: 中、~30分)

**目的**: seed variance を確認。R1@0.7 23.86 が安定値か外れ値かを判定。

**所要**: B1 finetune (full, early stopping) を 2 seed 追加で約 20-30 分

**前提**: B1 pretrain ckpt は既存の `lighthouse/results/full_b1_pretrain/best.ckpt` を流用 (再学習しない)

**手順**:
```bash
WRAPPER=/home/menserve/CG-DETR/train_with_override.py
PYTHON=/home/menserve/CG-DETR/.venv/bin/python
PRETRAIN=/home/menserve/CG-DETR/lighthouse/results/full_b1_pretrain/best.ckpt

for SEED in 42 1234; do
  echo "=== B1 finetune seed=$SEED ==="
  "$PYTHON" "$WRAPPER" \
    --model cg_detr --dataset castella --feature clap \
    --n_epoch 100 --es_patience 15 --seed $SEED \
    --resume "$PRETRAIN" \
    --results_dir results/full_b1_finetune_seed${SEED} \
    2>&1 | tee /home/menserve/CG-DETR/logs/exp_b_b1ft_seed${SEED}.log
done
```

**記録対象**:
- 各 seed の R1@0.5 / R1@0.7 / mAP
- 3 seed (2023, 42, 1234) の mean / std

---

### EXP-D: QVH scratch 学習で paper 値レンジに届くか (優先度: 中-高、~30-50分)

**目的**: Phase 1 は公式 ckpt の eval のみ。我々の学習パイプラインが QVH を scratch から学習しても paper 値の近傍 (R1@0.5 60+) に到達できるか確認する。届かなければ Phase 2 の CASTELLA 低値は「CG-DETR 転移失敗」ではなく「学習パイプライン全体の confound」となり判定変更が必要。

**所要**: ~30-50 分 (early stopping patience=15、~30-60 epoch で plateau 想定)

**前提**: QVH features (clip + slowfast + clip_text) は配置済み (`lighthouse/features/qvhighlight/`)

**手順**:
```bash
WRAPPER=/home/menserve/CG-DETR/train_with_override.py
PYTHON=/home/menserve/CG-DETR/.venv/bin/python

"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset qvhighlight --feature clip_slowfast \
  --n_epoch 100 --es_patience 15 --seed 2023 \
  --results_dir results/full_qvh_scratch \
  2>&1 | tee /home/menserve/CG-DETR/logs/exp_d_qvh_scratch.log
```

**記録対象**: QVH val の R1@0.5 / R1@0.7 / mAP avg / mAP@0.5 / mAP@0.75 (best ckpt)

**判定基準** (paper 値 = 公式 ckpt 値):

| Metric | 公式 ckpt 値 | EXP-D 合格目安 (±5pt) | 判定 |
|--------|------------|---------------------|------|
| R1@0.5 | 66.19 | 61.19 以上 | 学習 OK |
| R1@0.7 | 49.23 | 44.23 以上 | 学習 OK |
| mAP | 44.48 | 39.48 以上 | 学習 OK |

- **合格**: 学習パイプライン正常 → Phase 2 の CASTELLA 低値は本物の転移失敗 → 棄却支持確定
- **不合格** (大きく下回る): 学習パイプライン自体に confound → 判定変更必要

---

### EXP-C: B0 異常低値の原因切り分け (優先度: 低-中、~30分)

**目的**: なぜ B0 (CASTELLA 直接) が R1@0.5=3.41 と team_repo b_repr の 32.44 から大きく乖離するのかを軽く調査。

**仮説**:
1. lighthouse 標準実装と b_repr 実装の差 (loss weight, optimizer 等)
2. patience=15 が短すぎて plateau 誤認
3. lr / bsz の差

**手順**:
```bash
# C1: patience を緩めて長く回す
"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset castella --feature clap \
  --n_epoch 100 --es_patience 50 --seed 2023 \
  --results_dir results/full_b0_patience50 \
  2>&1 | tee /home/menserve/CG-DETR/logs/exp_c1_b0_patience50.log

# C2 (任意): bsz=64 で試す
"$PYTHON" "$WRAPPER" \
  --model cg_detr --dataset castella --feature clap \
  --n_epoch 100 --es_patience 15 --bsz 64 --seed 2023 \
  --results_dir results/full_b0_bsz64 \
  2>&1 | tee /home/menserve/CG-DETR/logs/exp_c2_b0_bsz64.log
```

**判定への影響**: 直接はなし (B1 finetune が主判定軸)。本実験で B0 が伸びても棄却判定は不変。**スキップ可**。

---

## 不変ルール (CANON 8節と同じ)

1. team_repo は読み取りのみ
2. lighthouse 上流コードは編集禁止 → `train_with_override.py` 経由
3. 各実験は別 `--results_dir` を使い既存結果を上書きしない
4. 全コマンド・全 metric・全 artifact path をログ化
5. ckpt / npz / log は `.gitignore` で除外済み (コミット不要)
6. 判定文書 (RESULTS, DECISION_INPUT, CANON) を Codex が編集する場合は **必ず**:
   - 既存 git 履歴を `./gitw log --oneline` で確認
   - 編集前に `./gitw pull` 相当はないが、最新の Opus 編集を読み直す
   - 編集後 `./gitw add <file> && ./gitw commit -m "..."` で記録

---

## 完了後の報告

Opus セッション宛てに以下を簡潔報告:

1. 実施した EXP (A / B / C のどれをやったか)
2. 各実験の主要 metric (特に R1@0.7)
3. multi-seed の場合は mean ± std
4. 結論として gate (31.82) との関係 (変わらず未達か、それとも届くケースあるか)
5. ログ・結果ファイルのパス
6. 想定外の事象があれば全文記録

Opus 側で DECISION_INPUT.md の最終化 (留保点を解消・残置の判断) を行います。

---

## 推奨実施範囲

時間制約に応じて選択:

- 最小: **EXP-A のみ** (数分、test split で gate 未達を再確認)
- 標準: **EXP-A + EXP-B + EXP-D** (~1.5時間、判定の頑健化に必要十分)
- 完全: **EXP-A + B + C + D** (~2時間、B0 異常含めて全方位)

Opus の推奨: **A + D + B** の順で実施。
- A は数分で test split 確認 (判定の頑健化)
- D は学習パイプライン確認 (CASTELLA 低値の confound 切り分け、判定変更の可能性)
- B は seed variance 確認 (頑健化の最終仕上げ)
- C は判定に直接影響しない (optional)

D の結果が「合格」(R1@0.5 ≧ 61) なら学習パイプラインは正常、棄却支持確定。
「不合格」(大きく下回る) なら判定要変更、Opus に即報告。
