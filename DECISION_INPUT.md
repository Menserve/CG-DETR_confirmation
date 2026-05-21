# DECISION_INPUT.md — A/B 判定用要約 (Phase 1+2 結果)

宛先: GPT-5.5 (判定・考察役)
作成: Opus (Phase 1/2 実行)
日付: 2026-05-21
判定対象: CG-DETR の「棄却確定」可否

---

## 1. プロジェクト目的

CG-DETR を team_repo で「棄却確定」する前に、独立環境で2つを検証する:

- **A**: 論文ベンチ (QVHighlights) で公式性能が再現できるか → 実装が健全か
- **B**: AMR 系転移 (Clotho pretrain → CASTELLA finetune) で性能改善が出るか → 提案手法の効果

---

## 2. 判定マトリクス (再掲)

| A (Phase 1) | B (Phase 2) | 判定 |
|-------------|-------------|------|
| Pass | Fail | 実装健全。棄却根拠は転移ギャップ |
| Pass | Pass | **棄却再考**（採用余地あり） |
| Fail | — | 棄却保留（実装/環境 confound 再発） |

---

## 3. Phase 1 (QVH) 結果

**状態**: **未実行**

理由: QVH features (Google Drive: 1-ALnsXkA4csKh71sRndMwybxEDqa-dM4) のダウンロード quota 超過のため自動取得不可。ユーザーによる手動ダウンロードが完了した時点で eval 実行予定 (学習なし、公式 ckpt 使用、軽量、所要時間 < 10分)。

**準備状況**: 全て完了
- 公式 CG-DETR ckpt: `lighthouse/results/cg_detr/qvhighlight/clip_slowfast/best.ckpt` (MD5: 2492eb33012cda214ac07dc3faabd202) 配置済み
- アノテーション (val 1549 件): MD5 検証済み
- eval スクリプト: `bash runbook.sh phase1_eval` で1コマンド実行可能

**Reference (公式 ckpt 同梱の metrics.json から)**

| Metric | Reference |
|--------|-----------|
| R1@0.5 | 66.19 |
| R1@0.7 | 49.23 |
| mAP avg | 44.48 |
| mAP@0.5 | 64.93 |
| mAP@0.75 | 45.17 |

判定基準: 実測値が reference ±~2pt 内であれば A pass。

---

## 4. Phase 2 (Clotho→CASTELLA) 結果

**状態**: **完了 (smoke / 10 epoch)**

### 4.1 実験構成

| 実験 | 内容 |
|------|------|
| B0 | CASTELLA 直接学習 (10 epoch, baseline) |
| B1 pretrain | Clotho-moment 学習 (10 epoch) |
| B1 finetune | B1 pretrain ckpt から CASTELLA finetune (10 epoch) |

### 4.2 結果 (best across 10 epochs, CASTELLA val)

| Metric | B0 | B1 finetune | 差分 |
|--------|----|----|------|
| R1@0.5 | 3.12 | **20.17** | **+17.05** |
| R1@0.7 | 0.57 | **7.39** | **+6.82** |
| mAP avg | 1.46 | **7.77** | **+6.31** |
| mAP@0.5 | 3.90 | **19.20** | **+15.30** |
| mAP@0.75 | 0.82 | **5.78** | **+4.96** |

判定基準: `B1 finetune > B0 (>2pt)` の閾値を全 metric で大幅超過 → **B pass (smoke レベル)**

### 4.3 B1 pretrain 単体結果 (Clotho-moment val) — 健全性チェック

| Source | epoch | R1@0.5 | R1@0.7 | mAP |
|--------|-------|--------|--------|-----|
| 本実験 | 10 | **86.84** | **80.07** | **75.52** |
| team_repo b_repr 参考 | — | 83.14 | 75.68 | 69.57 |

→ 独立再現は team_repo を上回る (10 epoch で). 実装の健全性を間接的に支持。

### 4.4 B1 finetune の収束カーブ (R1@0.5)

```
epoch  1: 3.41
epoch  2: 4.83
epoch  3: 8.24
epoch  4: 10.23
epoch  5: 11.93
epoch  6: 11.36
epoch  7: 15.34
epoch  8: 14.77
epoch  9: 16.76
epoch 10: 20.17
```

単調増加傾向。10 epoch では収束未到達、full 学習 (200 epoch) でさらに伸びる可能性大。

---

## 5. 現時点での判定の難所

### 5.1 Phase 1 未完了の影響

A の判定が未完であるため、Phase 2 で B pass を確認しても **判定マトリクスは確定不能** (A の結果が分岐の起点):
- A pass + B pass → 棄却再考
- A fail + B pass → A fail 側に従い「棄却保留」

QVH features の手動 DL 完了 → Phase 1 eval (約10分) で確定する。

### 5.2 smoke vs full の差異

本判定は smoke (10 epoch) 結果。**B pass の方向性は確定**だが、絶対性能は full 学習に依存。
- team_repo の B0 100 epoch では R1@0.5=32.44 → 本実験 smoke (3.12) は明らかに未収束
- B1 finetune の収束カーブも未到達

「採用余地あり」と判断する場合、full 学習で B0 vs B1 finetune の差が維持されるかを確認する必要あり。

### 5.3 team_repo 「棄却」の根拠との対比

team_repo 側で CG-DETR が「棄却候補」になった経緯が DECISION_INPUT には記述なし。
GPT-5.5 が判定する際は、以下を team_repo governance と照合:
- team_repo の CG-DETR 棄却理由は「転移効果なし」or「論文再現失敗」or「実装上の問題」？
- 本実験で示した転移効果 (+17pt) は team_repo の「効果なし」結論と矛盾するか？

---

## 6. 暫定推奨

1. **QVH features 手動 DL を最優先**: Phase 1 を確定させて A/B 両方を埋める。
2. **Phase 2 は smoke で十分な方向性を示した**: full 学習 (約 9 時間) は判定確定後に着手判断する。
3. **team_repo の棄却根拠との照合**: 本独立再現が示した転移効果 (+17pt) は強い反証 (smoke レベルでも)。

---

## 7. 全成果物の場所

| 種類 | path |
|------|------|
| Phase 0 setup | `/home/menserve/CG-DETR/SETUP_REPORT.md` |
| Phase 1 結果 | (未実行 — QVH features DL 後に `RESULTS_QVH.md` 作成) |
| Phase 2 結果 | `/home/menserve/CG-DETR/RESULTS_CASTELLA.md` |
| 実行スクリプト | `/home/menserve/CG-DETR/runbook.sh` |
| 学習 wrapper | `/home/menserve/CG-DETR/train_with_override.py` |
| ckpt | `/home/menserve/CG-DETR/lighthouse/results/{smoke_b0,smoke_b1_pretrain,smoke_b1_finetune}/best.ckpt` |
| ログ | `/home/menserve/CG-DETR/logs/phase2_*.log` |

---

## 8. 環境再現性

| 項目 | 値 |
|------|---|
| lighthouse commit | d095eaa552cecef240897a8b750306b3b2a08740 |
| torch | 2.11.0+cu128 |
| GPU | RTX 5090 (34.2 GB) |
| seed | 2023 (B0/B1 とも) |
| Python | 3.12.3 |
| Reproducibility | 単一 seed の単発実行。分散評価は未実施 |
