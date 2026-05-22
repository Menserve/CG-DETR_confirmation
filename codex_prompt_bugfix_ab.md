# Codex 用コピペプロンプト (Bug fix 後 A/B 検証)

`---PROMPT---` ブロックを Codex セッションにそのまま貼ってください。

---PROMPT---

CG-DETR 独立再現プロジェクトの **bug fix 後 A/B 検証** を担当してください。

# 概要
あなた自身が直前に発見・修正した cg_detr の 2 件のバグ (saliency loss 加算先 / models.py タイポ) により、既存の棄却判定の前提 (実装健全性) が崩れました。Stage 1→2→3 で fix 後の真の性能を測定し、UVCOM gate (CASTELLA val R1@0.7=31.82) を超えるかを確定します。

# 必読 (順)
1. `/home/menserve/CG-DETR/CANON.md` — 全体ルール、役割、起動法
2. `/home/menserve/CG-DETR/handoff_to_codex_bugfix_ab.md` — **本タスクの正典** (Stage 1/2/3 詳細、打ち切り条件、報告フォーマット)
3. `/home/menserve/CG-DETR/DECISION_INPUT.md` — 現在の暫定状態 (棄却保留)

# 事前確認 (毎 Stage 開始時に必ず実行)
```
bash /home/menserve/CG-DETR/runbook.sh check
```
`cuda: True / NVIDIA GeForce RTX 5090` が出ない場合は中止して報告。

# 実施全体像 (打ち切り条件付き 3 段階)

```
[Stage 1: 既存 pretrain ckpt + finetune fix, seed=2023]  約15分
   ↓
   R1@0.7 < 26 → [打ち切り] 棄却維持で報告して終了
   R1@0.7 ≥ 26 → [Stage 2 へ]

[Stage 2: Full B1 chain (pretrain も fix で再学習), seed=2023]  約90分
   ↓
   R1@0.7 < 30 → [打ち切り] 棄却維持で報告して終了
   R1@0.7 ≥ 30 → [Stage 3 へ]

[Stage 3: multi-seed B1 ft (fix), seeds 42, 1234]  約30分
   → mean ± std 計算、最終報告
```

**重要**: 各 Stage 完了後に R1@0.7 を必ず確認し、打ち切り条件で次へ進むか判断してください。判断ロジックの自動化スクリプト (Python ワンライナー) は handoff の各 Stage 節に記載済みです。

# 不変ルール (CANON 8節)
- team_repo は読み取りのみ
- lighthouse 上流コードは **bug fix 以外は編集禁止** (今回の修正は例外として承認済)
- 各実験は別 `--results_dir` を使う (既存結果上書き禁止)
- 全コマンド・全 metric・全 artifact path をログ化
- ckpt / log は .gitignore で除外済み、コミット不要
- **判定文書 (CANON, DECISION_INPUT, RESULTS_*) は Codex は編集しない**。結果報告のみ Opus に渡し、Opus が文書更新を担当

# 想定所要時間
- 最短 (Stage 1 で打ち切り): ~15 分
- 中間 (Stage 2 で打ち切り): ~105 分
- 完了 (Stage 3 まで実施): ~135 分 (~2h15m)

# 最終報告フォーマット
全 Stage 完了後、handoff_to_codex_bugfix_ab.md の 7節 (最終報告フォーマット) に従い Opus セッション宛に報告してください。

# 想定外の事象が起きた場合
- 即座に作業中止
- 状況を全文記録して Opus 宛に報告
- 自己判断で lighthouse コードを追加修正しない (bug fix は既に完了済みのもののみ承認)

---PROMPT---

## 補足 (Opus → ユーザー)

- このプロンプトは `handoff_to_codex_bugfix_ab.md` を読ませることで詳細補完する設計
- 打ち切り条件は **R1@0.7 のみで自動判定可能** にしてあるので Codex の判断負荷は小
- Stage 1 で R1@0.7 ≥ 30 という強シグナルが出た場合は handoff 4.3 節で「Stage 2 をスキップして Stage 3 へ進む選択肢あり (判断は Opus に委ねる)」と記載 → Codex はその場合は **Opus に確認を求める** こと
- Codex が判定文書を編集しないよう明示済 (これまでの経験で Codex が文書編集する傾向があったため)
