# RESULTS_CASTELLA.md — Phase 2: Clotho→CASTELLA 転移チェック (smoke)

実行者: Opus (Phase 2)
実行日: 2026-05-21
環境: /home/menserve/CG-DETR/lighthouse (commit d095eaa), torch 2.11.0+cu128, RTX 5090

---

## 1. 実験設定

| 項目 | 値 |
|------|-----|
| Model | cg_detr (lighthouse 標準実装, 12,219,179 params) |
| Feature | clap (audio_tef, a_feat_dim=768, t_feat_dim=768) |
| Epoch | 10 (smoke) |
| Seed | 2023 |
| Batch size | 32 |
| Learning rate | 1e-4 |
| Optimizer | AdamW |
| Override script | `/home/menserve/CG-DETR/train_with_override.py` (lighthouse source non-mutate) |

---

## 2. 結果サマリ (best across 10 epochs)

| 実験 | データセット | R1@0.5 | R1@0.7 | mAP avg | mAP@0.5 | mAP@0.75 | 時間 |
|------|------------|--------|--------|---------|---------|---------|------|
| **B0** (CASTELLA 直接) | CASTELLA val | 3.12 | 0.57 | 1.46 | 3.90 | 0.82 | 1分50秒 |
| **B1 pretrain** (Clotho) | Clotho val | 86.84 | 80.07 | 75.52 | 90.25 | 78.81 | 約25分 |
| **B1 finetune** (CASTELLA from Clotho) | CASTELLA val | **20.17** | **7.39** | **7.77** | **19.20** | **5.78** | 約2分 |

---

## 3. 差分 (B1 finetune − B0)

| Metric | B0 best | B1 ft best | 差分 (pt) | 改善率 |
|--------|---------|------------|-----------|--------|
| R1@0.5 | 3.12 | 20.17 | **+17.05** | **6.5×** |
| R1@0.7 | 0.57 | 7.39 | **+6.82** | **13.0×** |
| mAP avg | 1.46 | 7.77 | **+6.31** | **5.3×** |
| mAP@0.5 | 3.90 | 19.20 | **+15.30** | **4.9×** |
| mAP@0.75 | 0.82 | 5.78 | **+4.96** | **7.0×** |

**判定**: smoke (10 epoch) でも **明確かつ大幅な転移効果** が確認された。`B1 finetune > B0 (>2pt)` のしきい値を全 metric で大幅超過。

---

## 4. B1 finetune の収束カーブ (CASTELLA val R1@0.5)

```
epoch  1: 3.41  ← clotho ckpt から開始した直後
epoch  2: 4.83
epoch  3: 8.24
epoch  4: 10.23
epoch  5: 11.93
epoch  6: 11.36
epoch  7: 15.34
epoch  8: 14.77
epoch  9: 16.76
epoch 10: 20.17  ← 単調収束、まだ伸びる余地あり
```

epoch 1 ですでに B0 final (1.42) を超え、epoch 10 までほぼ単調増加。
200 epoch の full 学習でさらに伸びる可能性が高い。

---

## 5. 参考値との比較

### B1 pretrain (Clotho-moment val)

| Source | R1@0.5 | R1@0.7 | mAP avg |
|--------|--------|--------|---------|
| 本実験 (10 epoch) | **86.84** | **80.07** | **75.52** |
| team_repo b_repr 参考 | 83.14 | 75.68 | 69.57 |

→ 独立再現の方が良好（10 epoch でも team_repo 値を超過）。実装の健全性を示唆。

### B0 / B1 finetune (CASTELLA val)

直接比較できる team_repo 値は 100 epoch (b_repr) のため smoke 比較は不可:

| Source | epoch | R1@0.5 | R1@0.7 | mAP |
|--------|-------|--------|--------|-----|
| 本実験 B0 smoke | 10 | 3.12 | 0.57 | 1.46 |
| 本実験 B1 ft smoke | 10 | 20.17 | 7.39 | 7.77 |
| team_repo b_repr B0 | 100 | 32.44 | 18.86 | 14.88 |

200 epoch の full 学習で参照値に近づく見込み（収束未到達）。

---

## 6. 実行ログ・成果物

| 種類 | path |
|------|------|
| B0 ckpt | `lighthouse/results/smoke_b0/best.ckpt` |
| B0 log | `logs/phase2_b0_smoke.log` |
| B1 pretrain ckpt | `lighthouse/results/smoke_b1_pretrain/best.ckpt` |
| B1 pretrain log | `logs/phase2_b1_pretrain_smoke.log` |
| B1 finetune ckpt | `lighthouse/results/smoke_b1_finetune/best.ckpt` |
| B1 finetune log | `logs/phase2_b1_finetune_smoke.log` |

---

## 7. 注意点 / 既知の問題

1. **Clotho-moment 特徴量 path の修正** (Phase 0 で誤りを修正):
   - 当初 symlink: `/home/menserve/compe_YCU/data/features/clotho-moment/clap` (17233 files = 33.8%)
   - 修正後: `/home/menserve/compe_YCU/data/features/features/clotho-moment/clap` (51240 files = 100%)
   - 修正により全 32694 train サンプル使用可能となった。本実験は修正後の結果。

2. **smoke の限界**: 10 epoch は CASTELLA 収束には不十分。B1 finetune の収束カーブは単調増加の途中。full 学習 (200 epoch) で絶対値はさらに改善が見込まれる。

3. **再現性**: 単一 seed (2023) のみで実施。分散評価には複数 seed 必要だが、効果量 (+17pt) が大きいため smoke 段階での方向性判定としては十分。

---

## 8. 次のアクション

- **判定**: smoke レベルで「Clotho pretrain → CASTELLA finetune は明確に有効」を確認 → **full 学習に進む価値あり**
- **full 学習** (200 epoch × 3) の推定時間:
  - B0 full: ~40 分
  - B1 pretrain full: ~8 時間 (Clotho 32694 train)
  - B1 finetune full: ~40 分
- これは DECISION_INPUT.md に整理して GPT-5.5 へ引き継ぐ
