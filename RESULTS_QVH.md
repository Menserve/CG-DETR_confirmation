# RESULTS_QVH.md — Phase 1: QVHighlights CG-DETR 公式 ckpt 再現 eval

実行者: Codex (Phase 1)
実行日: 2026-05-21
環境: /home/menserve/CG-DETR/lighthouse, torch 2.11.0+cu128, RTX 5090

## 1. 実行コマンド

```bash
bash /home/menserve/CG-DETR/runbook.sh check
bash /home/menserve/CG-DETR/runbook.sh phase1_eval
```

実際に runbook から呼ばれた evaluate:

```bash
/home/menserve/CG-DETR/.venv/bin/python training/evaluate.py \
  --model cg_detr \
  --dataset qvhighlight \
  --feature clip_slowfast \
  --split val \
  --model_path /home/menserve/CG-DETR/lighthouse/results/cg_detr/qvhighlight/clip_slowfast/best.ckpt \
  --eval_path data/qvhighlight/highlight_val_release.jsonl
```

## 2. 結果 vs Reference

| Metric | 実測 | Reference | 差分 | 判定 |
|--------|------|-----------|------|------|
| R1@0.5 | 66.19 | 66.19 | +0.00 | ○ |
| R1@0.7 | 49.23 | 49.23 | +0.00 | ○ |
| mAP avg | 44.48 | 44.48 | +0.00 | ○ |
| mAP@0.5 | 64.93 | 64.93 | +0.00 | ○ |
| mAP@0.75 | 45.17 | 45.17 | +0.00 | ○ |

## 3. 総合判定

- 全 metric ±2pt 以内: **A pass**
- A の最終判定: **Pass**

## 4. ログ

- check: `cuda: True`, `gpu: NVIDIA GeForce RTX 5090` を確認
- 実行ログ: `logs/phase1_qvh_eval_20260521_110423.log`
- 予測 jsonl: `lighthouse/results/cg_detr/qvhighlight/clip_slowfast/hl_val_submission.jsonl`
- 指標 json: `lighthouse/results/cg_detr/qvhighlight/clip_slowfast/hl_val_submission_metrics.json`

## 5. 観察

- 5 metric は同梱 reference と完全一致（差分 0.00）。
- eval ログ上でエラー・例外なし。
