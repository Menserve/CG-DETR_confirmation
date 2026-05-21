# handoff_to_codex_phase1.md — Phase 1 (QVH eval) 外注指示

宛先: Codex
作成: Opus, 2026-05-21
所要時間目安: 10 分以内（学習なし、eval のみ）

---

## ゴール

公式 CG-DETR ckpt を使って QVHighlights val で eval を実行し、`RESULTS_QVH.md` を作成する。

---

## 前提状態 (Opus 側で準備済み)

| 項目 | 状態 |
|------|------|
| QVH features 解凍 | 済 (`lighthouse/features/qvhighlight/{clip,clip_text,slowfast,pann,resnet}`) |
| 公式 CG-DETR ckpt | 済 (`lighthouse/results/cg_detr/qvhighlight/clip_slowfast/best.ckpt`) |
| アノテーション | 済 (`lighthouse/data/qvhighlight/highlight_val_release.jsonl`, 1550行) |
| Phase 2 結果 (参考) | 完了済み: `/home/menserve/CG-DETR/RESULTS_CASTELLA.md` |

---

## 重要な事前チェック

**必ず最初に GPU 確認をしてください**。前回の試行では Codex セッションが `cuda: False` で停止しました。

```bash
bash /home/menserve/CG-DETR/runbook.sh check
```

`cuda: True / gpu: NVIDIA GeForce RTX 5090` が出ない場合は **作業を中止して報告してください**（ユーザに WSL/VSCode 再起動を依頼）。`features/qvhighlight` の OK 表示も同時に確認。

---

## 実行コマンド

```bash
bash /home/menserve/CG-DETR/runbook.sh phase1_eval
```

これは `training/evaluate.py` を以下の引数で呼びます:

```
--model cg_detr
--dataset qvhighlight
--feature clip_slowfast
--split val
--model_path lighthouse/results/cg_detr/qvhighlight/clip_slowfast/best.ckpt
--eval_path data/qvhighlight/highlight_val_release.jsonl
```

ログは `logs/phase1_qvh_eval_<timestamp>.log` に出力されます。

---

## 期待値 (公式 ckpt 同梱の `best_qvhighlight_val_preds_metrics.json` から)

| Metric | Reference | 許容差 |
|--------|-----------|--------|
| R1@0.5 | 66.19 | ±2.0 |
| R1@0.7 | 49.23 | ±2.0 |
| mAP avg | 44.48 | ±2.0 |
| mAP@0.5 | 64.93 | ±2.0 |
| mAP@0.75 | 45.17 | ±2.0 |

判定: 全 metric が許容差内なら **A pass**。

---

## RESULTS_QVH.md の作成

eval ログから metric を抽出し `/home/menserve/CG-DETR/RESULTS_QVH.md` を以下のテンプレートで作成してください。

```markdown
# RESULTS_QVH.md — Phase 1: QVHighlights CG-DETR 公式 ckpt 再現 eval

実行者: Codex (Phase 1)
実行日: 2026-05-21
環境: /home/menserve/CG-DETR/lighthouse, torch 2.11.0+cu128, RTX 5090

## 1. 実行コマンド
(実行した evaluate.py コマンドを記載)

## 2. 結果 vs Reference

| Metric | 実測 | Reference | 差分 | 判定 |
|--------|------|-----------|------|------|
| R1@0.5 | XX.XX | 66.19 | ±X.XX | ○ / × |
| R1@0.7 | XX.XX | 49.23 | ±X.XX | ○ / × |
| mAP avg | XX.XX | 44.48 | ±X.XX | ○ / × |
| mAP@0.5 | XX.XX | 64.93 | ±X.XX | ○ / × |
| mAP@0.75 | XX.XX | 45.17 | ±X.XX | ○ / × |

## 3. 総合判定
- 全 metric ±2pt 以内: **A pass / A fail**
- A の最終判定: Pass / Fail

## 4. ログ
- 実行ログ: logs/phase1_qvh_eval_<timestamp>.log
- 予測 jsonl: (evaluate.py が出力するパス)

## 5. 観察 (任意)
- 差分の傾向、警告、その他気づき
```

---

## 完了後の報告

完了したら、以下を Opus セッションに簡潔に報告してください:

1. 実行結果の summary (5 metric)
2. A pass/fail 判定
3. RESULTS_QVH.md のパス
4. ログのパス
5. エラー/警告があれば全文

私 (Opus) は DECISION_INPUT.md にこの結果を反映し、GPT-5.5 へ最終判定を渡します。

---

## トラブルシューティング

- ckpt 読み込みエラー: `find /home/menserve/CG-DETR/lighthouse/results -name "best.ckpt" -path "*cg_detr*qvhighlight*"`
- features missing: `bash /home/menserve/CG-DETR/runbook.sh check` で features/qvhighlight の確認
- 上流コード (lighthouse) は **編集しない**。問題があれば報告のみ

---

## 重要ルール (再掲)

- team_repo (`/home/menserve/compe_YCU/team_repo/`) は触らない
- 上流コードは原則 non-mutate（必要修正は外部 patch として分離して相談）
- 推測で埋めず「未確認」と記録
- 全コマンド・全 metric・全 artifact path をログ化
