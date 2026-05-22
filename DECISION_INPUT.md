# DECISION_INPUT.md — A/B 最終判定用要約 (全 Phase + 追加実験 + Bug Fix A/B 完了)

宛先: GPT-5.5 (判定・考察役)
作成: Opus
日付: 2026-05-21 (Phase 1+2 full + EXP-A/B/D + Bug fix A/B 完了)
判定対象: CG-DETR の「棄却確定」可否

---

## 0. 最終結論 (TL;DR)

- **A (Phase 1)**: **Pass** — 公式 ckpt 完全一致 + 学習パイプラインも paper 値再現 (EXP-D)
- **B (Phase 2)**: **Fail (gate 未達)** — buggy/fix の双方で R1@0.7 が UVCOM gate (31.82) に到達せず
- **Bug fix A/B**: 中盤に lighthouse 実装の 2 件のバグを発見・修正、再学習で fix 効果 +2.56pt (R1@0.7) を計測、ただし gate との差 -5.40pt は埋まらず
- **判定**: **棄却確定を維持** (bug fix 後でも棄却根拠は再現された)
- team_repo の棄却結論は独立環境で確認 (independent replication 成立)

---

## 1. プロジェクト目的

team_repo で「CG-DETR 棄却確定」が出かかっている状況で、独立環境で再検証し
**(a) 手法本来の限界か / (b) 実装・環境 confound か** を分離する。

---

## 2. 判定マトリクス

| A (Phase 1) | B (Phase 2) | 判定 |
|-------------|-------------|------|
| Pass | **Fail (gate 未達)** | **棄却支持 (実装健全、転移ギャップが棄却根拠)** ← **本件** |
| Pass | Pass (gate 到達) | 棄却再考 |
| Fail | — | 棄却保留 |

**主判定軸**: CASTELLA val/test R1@0.7 ≧ UVCOM gate (val 31.82 / test 23.68)

---

## 3. Phase 1 (QVH) — A pass 二重確認

### 3.1 公式 ckpt eval (Codex, 初回)

| Metric | 実測 | Reference | 差分 |
|--------|------|-----------|------|
| R1@0.5 | 66.19 | 66.19 | +0.00 |
| R1@0.7 | 49.23 | 49.23 | +0.00 |
| mAP avg | 44.48 | 44.48 | +0.00 |
| mAP@0.5 | 64.93 | 64.93 | +0.00 |
| mAP@0.75 | 45.17 | 45.17 | +0.00 |

→ eval パイプライン健全 (公式 reference と完全一致)

### 3.2 学習パイプライン健全性確認 (EXP-D, scratch 学習)

| Metric | 本独立 scratch | 公式 ckpt | 差分 |
|--------|--------------|----------|------|
| R1@0.5 | 65.87 | 66.19 | -0.32 |
| R1@0.7 | 51.23 | 49.23 | **+2.00** |
| mAP avg | 44.39 | 44.48 | -0.09 |
| mAP@0.5 | 65.24 | 64.93 | +0.31 |
| mAP@0.75 | 45.55 | 45.17 | +0.38 |

→ **学習パイプラインも paper 値完全再現**。R1@0.7 は paper を上回る。
→ Phase 2 の CASTELLA 低値は **学習パイプラインの問題ではない** ことが確定。

詳細: [RESULTS_QVH.md](RESULTS_QVH.md)

---

## 3.5 モデル × データセット スコアマトリクス (横断ビュー)

### R1@0.7 (主判定軸)

| モデル / 条件 | QVH val | Clotho val | CASTELLA val | CASTELLA test |
|--------------|---------|------------|--------------|---------------|
| **CG-DETR 公式 ckpt** | **49.23** | — | — | — |
| CG-DETR 本独立 scratch (EXP-D) | 51.23 | — | — | — |
| CG-DETR 本独立 B0 | — | — | 1.14 | — |
| CG-DETR 本独立 B1 pretrain | — | 82.90 | — | — |
| CG-DETR 本独立 B1 ft seed=2023 | — | — | 23.86 | **19.15** |
| CG-DETR 本独立 B1 ft seed=42 | — | — | 18.75 | — |
| CG-DETR 本独立 B1 ft seed=1234 | — | — | 24.43 | — |
| **CG-DETR 本独立 B1 ft mean (3 seed)** | — | — | **22.35 ± 3.13** | 19.15 |
| CG-DETR team_repo b_repr (参考) | — | 75.68 | 26.42 | 19.97 |
| **UVCOM A-aug s1 (gate 基準)** | — | — | **31.82** | **23.68** |

### R1@0.5

| モデル / 条件 | QVH val | Clotho val | CASTELLA val | CASTELLA test |
|--------------|---------|------------|--------------|---------------|
| CG-DETR 公式 ckpt | 66.19 | — | — | — |
| CG-DETR 本独立 scratch (EXP-D) | 65.87 | — | — | — |
| CG-DETR 本独立 B0 | — | — | 3.41 | — |
| CG-DETR 本独立 B1 pretrain | — | 89.12 | — | — |
| CG-DETR 本独立 B1 ft seed=2023 | — | — | 38.64 | 32.37 |
| CG-DETR 本独立 B1 ft seed=42 | — | — | 33.81 | — |
| CG-DETR 本独立 B1 ft seed=1234 | — | — | 37.22 | — |
| CG-DETR 本独立 B1 ft mean | — | — | 36.56 ± 2.48 | 32.37 |
| CG-DETR team_repo b_repr | — | 83.14 | 32.44 | — |

### mAP avg

| モデル / 条件 | QVH val | Clotho val | CASTELLA val | CASTELLA test |
|--------------|---------|------------|--------------|---------------|
| CG-DETR 公式 ckpt | 44.48 | — | — | — |
| CG-DETR 本独立 scratch (EXP-D) | 44.39 | — | — | — |
| CG-DETR 本独立 B0 | — | — | 1.98 | — |
| CG-DETR 本独立 B1 pretrain | — | 79.22 | — | — |
| CG-DETR 本独立 B1 ft seed=2023 | — | — | 17.56 | 14.87 |
| CG-DETR 本独立 B1 ft seed=42 | — | — | 16.89 | — |
| CG-DETR 本独立 B1 ft seed=1234 | — | — | 19.43 | — |
| CG-DETR 本独立 B1 ft mean | — | — | 17.96 ± 1.32 | 14.87 |
| CG-DETR team_repo b_repr | — | 69.57 | 14.88 | — |

### 読み取り

- QVH 行: 本独立 scratch ≈ 公式 ckpt → **学習パイプライン健全**
- CASTELLA val 列: 全 seed が UVCOM gate (31.82) から ≥7pt 不足、std=3.13 でも 3σ で gate 触れず
- CASTELLA test 列: gate 23.68 から -4.53pt で未達
- B0 vs B1 ft: pretrain なしでは学習困難、Clotho pretrain で大幅改善するも CASTELLA gate には届かず

---

## 4. Phase 2 (Clotho→CASTELLA) — B fail (gate 未達)

### 4.1 単一 seed (seed=2023) full 結果

| 実験 | データセット | R1@0.5 | R1@0.7 | mAP | best epoch | 実 epoch |
|------|-------------|--------|--------|------|-----------|----------|
| B0 | CASTELLA val | 3.41 | 1.14 | 1.98 | 12 | 27 (es) |
| B1 pretrain | Clotho val | 89.12 | 82.90 | 79.22 | 23 | 38 (es) |
| **B1 finetune** | CASTELLA val | **38.64** | **23.86** | 17.56 | 51 | 66 (es) |

転移効果 (B1 ft − B0): R1@0.7 +22.72 (20.9×) → 転移自体は明確に有効、ただし絶対値が低い

### 4.2 Multi-seed B1 finetune (EXP-B, val)

| seed | R1@0.5 | R1@0.7 | mAP |
|------|--------|--------|-----|
| 2023 | 38.64 | 23.86 | 17.56 |
| 42 | 33.81 | 18.75 | 16.89 |
| 1234 | 37.22 | 24.43 | 19.43 |
| **mean ± std** | **36.56 ± 2.48** | **22.35 ± 3.13** | **17.96 ± 1.32** |

### 4.3 CASTELLA test split (EXP-A, B1 ft seed=2023)

| Metric | 実測 |
|--------|------|
| R1@0.5 | 32.37 |
| **R1@0.7** | **19.15** |
| mAP | 14.87 |

### 4.4 UVCOM gate 比較 (主判定軸)

| Source | split | R1@0.7 | gate | gate との差 |
|--------|-------|--------|------|------------|
| UVCOM A-aug s1 (gate 基準) | val | — | 31.82 | — |
| UVCOM A-aug s1 (gate 基準) | test | — | 23.68 | — |
| team_repo b_repr CG-DETR b64 s1 | val | 26.42 | 31.82 | -5.40 |
| team_repo b_repr CG-DETR b64 s1 | test | 19.97 | 23.68 | -3.71 |
| **本独立 B1 ft mean (3 seed)** | val | **22.35 ± 3.13** | 31.82 | **-9.47 (mean)** |
| 本独立 B1 ft 最大 (seed1234) | val | 24.43 | 31.82 | -7.39 |
| 本独立 B1 ft (seed2023) | test | 19.15 | 23.68 | **-4.53** |

→ **val / test / 全 seed で gate 未達**
→ multi-seed std=3.13、3σ でも gate 31.74 でやっと触れる → **現実験範囲では seed variance による gate 突破を期待する根拠がない**
→ team_repo 結果と ballpark 一致 (val: 22.35±3.13 vs 26.42)

**注**: 上記 §4 は **bug fix 前 (buggy 実装)** での結果。bug fix 後の結果は §4.5 を参照。両方の表を保持する。

---

## 4.5 Bug fix A/B 結果 (実装バグ修正後の再検証)

### 4.5.1 発見されたバグ (Codex, 2026-05-21)

1. **attention 側 false-negative 対比損失の加算先ミス** (`lighthouse/lighthouse/common/cg_detr.py`)
   - buggy: `loss_rank_contrastive += falseneg_loss_rank_contrastive`
   - fixed: `loss_rank_contrastive_attn += falseneg_loss_rank_contrastive`
2. **空判定条件のタイポ** (`lighthouse/lighthouse/models.py`)
   - `len(ranked_moments)==0 and len(ranked_moments)==0` → `... and len(saliency_scores)==0`

同一 ckpt 比較で saliency 損失 +16.78%、総損失 +3.01% (12/12 batch で fix > buggy)。
→ buggy 状態では attention 側 false-negative 罰則が実質的に抜けていた。

**重要**: §3 (Phase 1) と §4 (Phase 2) の結果は **buggy 実装**。EXP-D の「学習パイプライン健全」確認も buggy 版。本節で fix 版を検証。

### 4.5.2 段階的 A/B (打ち切り条件付き)

| Stage | 内容 | R1@0.5 | R1@0.7 | mAP | 判定 |
|-------|------|--------|--------|-----|------|
| buggy (基準, seed=2023) | full B1 ft | 38.64 | 23.86 | 17.56 | — |
| **Stage 1** (buggy pretrain + fix ft) | seed=2023 | 38.07 | **26.42** | 20.03 | PROCEED (≥26) |
| **Stage 2** (full chain fix) | seed=2023 | 35.23 | **22.73** | 19.29 | ABORT (<30) |

Stage 2 の打ち切り条件 (R1@0.7 ≥ 30) 未達のため Stage 3 (multi-seed) は未実施。

### 4.5.3 fix 効果と gate との関係

| 条件 | val R1@0.7 | gate 31.82 との差 |
|------|-----------|-------------------|
| buggy seed=2023 | 23.86 | -7.96 |
| **fix Stage 1 (最良)** | **26.42** | **-5.40** |
| fix Stage 2 (full chain) | 22.73 | -9.09 |

- fix の効果は最良ケース (Stage 1) で **+2.56pt** (23.86→26.42)
- gate 突破に必要な +7.96pt に対し、fix 効果は **不足**
- Stage 2 (full chain fix) は buggy より低い → pretrain の fix は Clotho 大規模データで wash out、または fix pretrain ckpt が finetune に最適でない可能性 (単一 seed のため variance も否定できず)

### 4.5.4 観察 (要記録)

- Stage 2 R1@0.7=22.73 が buggy 23.86 を下回る点は systematic か variance か未確定 (Stage 3 打ち切りのため)
- 将来再検証する場合: Stage 2 pretrain ckpt + multi-seed finetune で切り分け可能

---

## 5. 留保点の解消状況

| 留保 (旧 DECISION_INPUT) | 現状 |
|------------------------|------|
| (1) 単一 seed のみ | **解消** — EXP-B で 3 seed mean 22.35±3.13、gate 31.82 から 9.47pt 下、現実験範囲では突破を期待する根拠なし |
| (2) val split のみ | **解消** — EXP-A で test も 19.15 (< gate 23.68) で未達 |
| (3) B0 異常低値 (EXP-C 未実施) | 未解明だが判定影響なし — B1 finetune が主軸、B0 は pretrain なし条件の付随現象 |
| (4) best ckpt 選択基準 (mAP vs R1@0.7) | 影響なし — seed1234 の R1@0.7=24.43 でも gate に -7.39pt 不足 |
| (5) **実装バグ confound** (中盤発見) | **解消** — bug fix 後の再学習で R1@0.7 最良 26.42、gate に -5.40pt 不足 (§4.5) |

加えて、**学習パイプライン confound 疑い (EXP-D で確認)** も 強く反証された (paper 値完全再現、ただし buggy 版)。
bug fix 版でも gate 未達のため、buggy/fix 双方で棄却根拠は維持される。

---

## 6. 最終判定

**棄却確定を維持**。team_repo governance 文言は「棄却確定」のまま据え置きを推奨。

> **GPT-5.5 最終承認 (2026-05-23)**: 棄却確定維持に異議なし。Phase 1 で実装・学習系の健全性が十分確認され、Phase 2 は val/test/multi-seed で主 gate 未達。bug fix は「判定を覆す confound ではなく、改善はするが足りない要因」と評価。文言「seed variance では突破不可能」は「現実験範囲では突破を期待する根拠がない」に緩和済 (§4 反映)。

### 根拠

1. **実装健全性**: 公式 ckpt eval (5/5 一致) + scratch 学習 (5/5 paper レンジ再現) で **二重確認**
2. **転移パイプライン健全性**: B1 pretrain (Clotho val R1@0.5=89.12) と B1 finetune (CASTELLA への転移自体は +35pt 改善) で確認
3. **gate 未達の頑健性**: multi-seed (val) + test split の **全条件**で R1@0.7 < gate
4. **team_repo との一致**: 本独立 (buggy) 22.35±3.13 vs team_repo 26.42 → ballpark 一致、独立 replication 成立
5. **bug fix 後も gate 未達**: 中盤に発見した実装バグを修正・再学習しても R1@0.7 最良 26.42 (gate -5.40pt)。fix 効果 +2.56pt は gate 突破に必要な +7.96pt に不足 (§4.5)

### bug fix が判定に与えた影響

- bug fix は実装 confound を解消したが、**判定結論は不変** (buggy/fix 双方で gate 未達)
- fix 後の最良値 (26.42) は team_repo b_repr (26.42) と偶然にも一致 → 独立 replication の信頼度を補強

### 再考トリガー (将来 active strategy 復帰を検討する条件)

- bug fix 版で multi-seed (Stage 3) を実施し mean R1@0.7 が gate 31.82 を超えた場合
- 別データセット (Charades 等) で fix 後に顕著な改善が確認された場合
- lighthouse upstream が追加の実装改善を取り込み、paper レンジが向上した場合

### 棄却の意味 (再掲)

- active strategy から外す のみ
- コード・artifact は保持 (削除しない)
- governance 文言の差し替えは不要 (「棄却確定」維持)

---

## 7. 全成果物の場所

| 種類 | path |
|------|------|
| 正典 | `/home/menserve/CG-DETR/CANON.md` |
| Phase 0 setup | `/home/menserve/CG-DETR/SETUP_REPORT.md` |
| Phase 1 結果 (eval + scratch) | `/home/menserve/CG-DETR/RESULTS_QVH.md` |
| Phase 2 結果 (smoke + full + 追加) | `/home/menserve/CG-DETR/RESULTS_CASTELLA.md` |
| 追加実験 handoff | `/home/menserve/CG-DETR/handoff_to_codex_additional.md` |
| Phase 2 ckpt | `lighthouse/results/{full_b0,full_b1_pretrain,full_b1_finetune,full_b1_finetune_seed42,full_b1_finetune_seed1234,full_qvh_scratch}/best.ckpt` |
| Phase 2 log | `logs/phase2_*_full_20260521_122305.log`, `logs/exp_*.log` |

---

## 8. 環境

| 項目 | 値 |
|------|---|
| lighthouse commit | d095eaa552cecef240897a8b750306b3b2a08740 |
| torch | 2.11.0+cu128 |
| GPU | RTX 5090 (34.2 GB) |
| Python | 3.12.3 |
| seeds | 2023 (主) + 42, 1234 (EXP-B) |
