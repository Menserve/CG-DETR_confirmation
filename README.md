# CG-DETR_confirmation

CG-DETR の独立再現プロジェクトです。`team_repo` での「CG-DETR 棄却判断」を、別環境で再検証するために作成しました。

## 目的

- 手法そのものの限界か、実装/環境 confound かを分離する。
- 判定基準は CASTELLA の `R1@0.7` を主軸に、UVCOM gate（val `31.82` / test `23.68`）と比較する。

## 最終判定

**棄却確定を維持**（GPT-5.5 承認済, 2026-05-23）。

- A（Phase 1）: Pass
- B（Phase 2）: Fail（gate 未達）

詳細は [DECISION_INPUT.md](DECISION_INPUT.md) を参照。

## 根拠サマリ

| 区分 | 主要結果 | 判定 |
|------|----------|------|
| Phase 1 (QVH) | 公式 ckpt eval が reference と 5/5 完全一致（R1@0.7=49.23） | **A pass（実装健全）** |
| Phase 2 (CASTELLA, B1 ft multi-seed) | `R1@0.7 = 22.35 ± 3.13`（val）< UVCOM gate `31.82` | **B fail（gate 未達）** |
| Bug fix 後の最良値 | Stage 1 で `R1@0.7 = 26.42`、gate との差 `-5.40pt` | **判定不変（未達）** |

## ファイルガイド

| ファイル | 役割 |
|---------|------|
| [CANON.md](CANON.md) | プロジェクト正典（目的、判定マトリクス、運用ルール） |
| [DECISION_INPUT.md](DECISION_INPUT.md) | 最終判定文書（TL;DR と最終結論） |
| [RESULTS_CASTELLA.md](RESULTS_CASTELLA.md) | Phase 2（Clotho→CASTELLA）と bug fix A/B の結果 |
| [RESULTS_QVH.md](RESULTS_QVH.md) | Phase 1（QVH）の再現評価結果 |
| [SETUP_REPORT.md](SETUP_REPORT.md) | 環境構築ログとセットアップ根拠 |

## 環境

| 項目 | 値 |
|------|----|
| lighthouse commit | `d095eaa` |
| torch | `2.11.0+cu128` |
| GPU | `RTX 5090` |
| 代表 seed | `2023` |

補足: README は要点のみを記載し、詳細な考察・留保・再考トリガーは [DECISION_INPUT.md](DECISION_INPUT.md) に集約しています。
