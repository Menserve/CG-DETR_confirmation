# RESULTS_CASTELLA.md — Phase 2: Clotho→CASTELLA 転移チェック

実行者: Opus (smoke + full 実行・記録)
実行日: 2026-05-21
環境: /home/menserve/CG-DETR/lighthouse (commit d095eaa), torch 2.11.0+cu128, RTX 5090

---

## 0. 主要結論 (TL;DR) — multi-seed + test 確認後

| 指標 | B0 (seed=2023) | B1 ft mean (3 seed) | B1 ft test (seed=2023) | UVCOM gate val | UVCOM gate test |
|------|---------------|--------------------|----------------------|---------------|-----------------|
| R1@0.5 | 3.41 | 36.56 ± 2.48 | 32.37 | — | — |
| **R1@0.7** | 1.14 | **22.35 ± 3.13** | **19.15** | **31.82** | **23.68** |
| mAP | 1.98 | 17.96 ± 1.32 | 14.87 | — | — |

- 転移効果そのものは明確に正 (B1 ft >> B0、R1@0.5 で +33pt 改善)
- しかし **主 gate (CASTELLA val/test R1@0.7) を全 seed/split で未達**:
  - val: mean 22.35 ± 3.13 → gate 31.82 から -9.47pt (3σ でもギリギリ届かず)
  - test: 19.15 → gate 23.68 から -4.53pt
- team_repo b_repr CG-DETR b64 s1 (val 26.42 / test 19.97) と ballpark 一致 → **棄却根拠を独立環境で再現**
- 学習パイプライン自体は健全 (EXP-D: QVH scratch で paper 値完全再現、詳細は [RESULTS_QVH.md](RESULTS_QVH.md))

---

## 1. 実験設定

| 項目 | smoke | full |
|------|-------|------|
| Model | cg_detr (lighthouse 標準実装, 12,219,179 params) | 同左 |
| Feature | clap (audio_tef, a_feat_dim=768, t_feat_dim=768) | 同左 |
| n_epoch (上限) | 10 | 100 |
| Early stopping | なし | patience=15 (best mAP 改善なし 15 epoch で停止) |
| Seed | 2023 | 2023 |
| Batch size / LR | 32 / 1e-4 (デフォルト) | 同左 |
| Override script | `/home/menserve/CG-DETR/train_with_override.py` (lighthouse non-mutate) | 同左 |

---

## 2. Smoke 結果 (n_epoch=10)

### 2.1 サマリ (best across epochs)

| 実験 | データセット | R1@0.5 | R1@0.7 | mAP | mAP@0.5 | mAP@0.75 | 時間 |
|------|-------------|--------|--------|------|---------|----------|------|
| B0 | CASTELLA val | 3.12 | 0.57 | 1.46 | 3.90 | 0.82 | 1m50s |
| B1 pretrain | Clotho val | 86.84 | 80.07 | 75.52 | 90.25 | 78.81 | ~25m |
| B1 finetune | CASTELLA val | 20.17 | 7.39 | 7.77 | 19.20 | 5.78 | ~2m |

差分 (B1 ft - B0): R1@0.5 +17.05, R1@0.7 +6.82 → 方向性 OK だが R1@0.7 絶対値は低い (未収束)

---

## 3. Full 結果 (n_epoch≦100, early stopping patience=15)

### 3.1 サマリ (best ckpt = best mAP で選択)

| 実験 | データセット | R1@0.5 | R1@0.7 | mAP | mAP@0.5 | mAP@0.75 | 実 epoch | best epoch |
|------|-------------|--------|--------|------|---------|----------|----------|-----------|
| B0 | CASTELLA val | 3.41 | 1.14 | 1.98 | 5.90 | 1.33 | 27 (es) | 12 |
| B1 pretrain | Clotho val | 89.12 | 82.90 | 79.22 | 92.21 | 82.48 | 38 (es) | 23 |
| B1 finetune | CASTELLA val | **38.64** | **23.86** | **17.56** | **33.79** | **16.48** | 66 (es) | 51 |

### 3.2 差分 (B1 finetune − B0, full)

| Metric | B0 | B1 ft | 差分 | 改善率 |
|--------|----|------|------|--------|
| R1@0.5 | 3.41 | 38.64 | +35.23 | 11.3× |
| R1@0.7 | 1.14 | 23.86 | +22.72 | 20.9× |
| mAP | 1.98 | 17.56 | +15.58 | 8.9× |
| mAP@0.5 | 5.90 | 33.79 | +27.89 | 5.7× |
| mAP@0.75 | 1.33 | 16.48 | +15.15 | 12.4× |

→ 転移効果そのものは明確 (smoke と同方向、より大きい)

### 3.3 B1 finetune の R1@0.7 推移

- 第1 epoch: 1.99 → 第10 epoch 付近: ~7-8 → 第30 epoch 付近: ~16-18 → 第50 epoch 付近: ~22-24
- best ckpt (epoch 51, mAP 基準): R1@0.7 = 23.86
- R1@0.7 単独の最大値 (epoch 横断): **24.72** (best ckpt と別 epoch)
- いずれも UVCOM gate (31.82) には未達

### 3.4 UVCOM gate 比較

| ソース | val R1@0.7 | gate との差 |
|--------|----------|------------|
| UVCOM A-aug s1 (gate 設定基準) | 31.82 | — |
| team_repo b_repr CG-DETR b64 s1 | 26.42 | -5.40 |
| **本独立再現 B1 ft full (best ckpt)** | **23.86** | **-7.96** |
| 本独立再現 B1 ft full (epoch max) | 24.72 | -7.10 |

team_repo の棄却結論「CG-DETR は UVCOM gate に届かない」は独立環境でも再現された。

---

## 4. 観察と懸念点

### 4.1 B0 (CASTELLA 直接学習) が異常低

- 本独立: R1@0.5 = 3.41 (full 27 epoch、best @ epoch 12)
- team_repo b_repr B0 100 epoch: R1@0.5 = 32.44
- **約 10 倍の差**。学習が早期に止まり改善しない

**仮説**:
- (a) lighthouse 標準 CG-DETR + clap feature の組み合わせが CASTELLA で機能しない (B0 単独不可)
- (b) early stopping が患い設定 (patience=15) → ただし best @ epoch 12 から 15 epoch 改善なしで停止しており、それ以上回しても伸びなさそう
- (c) team_repo b_repr は非標準実装 (b_repr 派生コード) で、loss/optimizer 等に差がある可能性

**この差分は本判定の confound 候補** だが、B1 finetune の結果は十分高く (38.64 R1@0.5) Clotho pretrain 経由なら正常学習しており、B0 の不調はあくまで「pretrain なしでは CASTELLA を学習できない」という観察に留まる。

### 4.2 best ckpt 選択基準 (mAP) vs gate metric (R1@0.7)

- lighthouse は best.ckpt を mAP で選んでいる
- gate は R1@0.7 → 本来は R1@0.7 で best 選択すべきだが、差は小さい (epoch max 24.72 vs ckpt 23.86)
- いずれも gate 未達なので判定は変わらない

### 4.3 単一 seed のみ

- seed=2023 1回のみ
- R1@0.7 23.86 が seed variance で gate (31.82) を超えるか? 差 -7.96pt は 1 sigma を超える大きな差で、複数 seed でも逆転しない見込み
- ただし「絶対 reject」のためには複数 seed で確認したい

---

## 4.5 Bug fix A/B 結果 (実装バグ修正後の再検証)

**注**: §0〜§4 のスコアは全て **bug fix 前 (buggy 実装)**。本節は fix 後の結果で、上記表は削除せず保持する。

### バグ概要 (Codex 発見・修正, 2026-05-21)
1. attention 側 false-negative 対比損失の加算先ミス (`cg_detr.py`) — buggy では罰則が実質脱落
2. 空判定条件のタイポ (`models.py`)
- 同一 ckpt 比較で saliency 損失 +16.78%, 総損失 +3.01%

### A/B 結果 (打ち切り条件付き、CASTELLA val)

| 条件 | R1@0.5 | R1@0.7 | mAP | gate(31.82)差 | 判定 |
|------|--------|--------|-----|--------------|------|
| buggy (基準, seed=2023) | 38.64 | 23.86 | 17.56 | -7.96 | — |
| **Stage 1** (buggy pretrain + fix ft, seed=2023) | 38.07 | **26.42** | 20.03 | **-5.40** | PROCEED |
| **Stage 2** (full chain fix, seed=2023) | 35.23 | **22.73** | 19.29 | -9.09 | ABORT (<30) |

- fix 効果は最良 (Stage 1) で **+2.56pt** (23.86→26.42)、gate 突破に必要な +7.96pt に不足
- Stage 2 (full chain fix) が buggy を下回る → pretrain fix は Clotho 大規模で wash out、または fix pretrain ckpt が finetune に最適でない (単一 seed のため variance も否定不可)
- Stage 2 R1@0.7=22.73 < 30 で打ち切り → Stage 3 (multi-seed) 未実施

### Bug fix 後の結論
- buggy / fix 双方で gate 未達 → **棄却根拠は不変**
- fix 最良 (26.42) は team_repo b_repr (26.42) と一致 → independent replication 補強

### 成果物 (bug fix A/B)

| 種類 | path |
|------|------|
| Stage 1 ckpt/log | `lighthouse/results/fix_stage1_b1ft/`, `logs/fix_stage1_b1ft.log` |
| Stage 2 pretrain | `lighthouse/results/fix_stage2_b1_pretrain/`, `logs/fix_stage2_b1_pretrain.log` |
| Stage 2 finetune | `lighthouse/results/fix_stage2_b1ft/`, `logs/fix_stage2_b1ft.log` |

---

## 5. 実行ログ・成果物

| 種類 | path |
|------|------|
| B0 full ckpt | `lighthouse/results/full_b0/best.ckpt` |
| B0 full log | `logs/phase2_b0_full_20260521_122305.log` |
| B1 pretrain full ckpt | `lighthouse/results/full_b1_pretrain/best.ckpt` |
| B1 pretrain full log | `logs/phase2_b1_pretrain_full_20260521_122305.log` |
| B1 finetune full ckpt | `lighthouse/results/full_b1_finetune/best.ckpt` |
| B1 finetune full log | `logs/phase2_b1_finetune_full_20260521_122305.log` |
| B0 smoke | `lighthouse/results/smoke_b0/`, `logs/phase2_b0_smoke.log` |
| B1 pretrain smoke | `lighthouse/results/smoke_b1_pretrain/`, `logs/phase2_b1_pretrain_smoke.log` |
| B1 finetune smoke | `lighthouse/results/smoke_b1_finetune/`, `logs/phase2_b1_finetune_smoke.log` |

---

## 6. 判定 (bug fix A/B 完了後)

- **A (Phase 1)**: Pass (公式 reference と完全一致, [RESULTS_QVH.md](RESULTS_QVH.md))
- **B (Phase 2)**: **gate 未達** (buggy R1@0.7=23.86 / fix 最良=26.42、いずれも < 31.82)
  - 転移効果は明確だが UVCOM 基準には届かず、bug fix でも +2.56pt のみで不足
- **マトリクス**: A pass + B [gate 未達] → **team_repo の棄却を独立環境でも再現** → **棄却維持**

最終判定は [DECISION_INPUT.md](DECISION_INPUT.md) で GPT-5.5 に委ねる。

---

## 7. 推奨追加実験 (任意 / Codex 担当案)

優先度順:

1. **CASTELLA test split eval** (高): val だけでなく test (gate 23.68) も同様に gate 未達か確認。本判定の頑健化。
2. **multi-seed B1 finetune** (中): seed=42, 1234 を追加して R1@0.7 の variance 確認。
3. **B0 低値の原因切り分け** (低-中): lr / bsz / model_ema 等の設定差分検証。判定には直接影響しないが手法理解には有用。

詳細は [handoff_to_codex_additional.md](handoff_to_codex_additional.md) を参照。
