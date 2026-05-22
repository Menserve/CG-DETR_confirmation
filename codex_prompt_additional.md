# Codex 用コピペプロンプト (追加実験)

下の `---PROMPT---` ブロックをそのまま Codex セッションに貼ってください。

---PROMPT---

CG-DETR 独立再現プロジェクトの追加実験 (Phase 2 後の頑健化) を担当してください。

# 必読 (順)

1. `/home/menserve/CG-DETR/CANON.md` — 全体ルール、役割、起動法、不変ルール 9 項目
2. `/home/menserve/CG-DETR/handoff_to_codex_additional.md` — 本タスクの詳細指示書 (EXP-A, B, C, D)
3. `/home/menserve/CG-DETR/RESULTS_CASTELLA.md` — 直近 Phase 2 結果 (B1 ft R1@0.7=23.86 < UVCOM gate 31.82)
4. `/home/menserve/CG-DETR/DECISION_INPUT.md` — 暫定判定 (棄却支持) と 4 つの留保点

# 事前確認

最初に必ず実行:
```
bash /home/menserve/CG-DETR/runbook.sh check
```

`cuda: True / gpu: NVIDIA GeForce RTX 5090` が出ない場合は中止して報告 (前回詰まった箇所)。

# 実施範囲

優先度順に **A → D → B** を実施。時間に余裕があれば C も。

| EXP | 内容 | 所要 | 重要度 |
|-----|------|------|------|
| A | CASTELLA test split eval (B1 ft 既存 ckpt 使用) | ~数分 | 高 (判定頑健化) |
| D | QVH scratch 学習 (学習パイプライン健全性確認) | ~30-50 分 | 中-高 (判定変更可能性) |
| B | B1 finetune の multi-seed (42, 1234) | ~30 分 | 中 (seed variance 確認) |
| C | B0 異常低値の原因切り分け | ~30 分 | 低 (判定影響なし、optional) |

各 EXP の具体的コマンドは `handoff_to_codex_additional.md` 参照。

# 重要な判定基準 (EXP-D)

EXP-D の結果次第で判定が変わる可能性あり:

| EXP-D R1@0.5 | 解釈 | 次アクション |
|-------------|------|------------|
| ≧ 61 (paper 値 66.19 の -5pt 以内) | 学習パイプライン健全 | 棄却支持確定、Opus に通常報告 |
| 大きく下回る (例: 30 台) | 学習パイプライン自体に confound 疑い | **Opus に即報告、判定変更検討** |

# 不変ルール (CANON 8節)

- team_repo は読み取りのみ
- lighthouse 上流コードは編集禁止 (`train_with_override.py` 経由で起動)
- 各実験は別 `--results_dir` を使う (既存上書き禁止)
- 全コマンド・全 metric・全 artifact path をログ化
- ckpt / npz / log は .gitignore で除外済み (コミット不要)
- 判定文書 (CANON.md, RESULTS_*.md, DECISION_INPUT.md) を編集する場合のみ `./gitw` でコミット

# 完了後の報告

Opus セッション宛てに以下を簡潔報告:

1. 実施した EXP (A / B / C / D のどれをやったか)
2. 各実験の主要 metric (特に R1@0.7、EXP-D は R1@0.5/R1@0.7/mAP 全部)
3. multi-seed (EXP-B) の場合は mean ± std
4. EXP-D の判定: paper 値レンジ到達 (合格) / 大きく下回る (不合格)
5. UVCOM gate (31.82) との関係 (変わらず未達か、それとも届くケースあるか)
6. ログ・結果ファイルのパス
7. 想定外の事象があれば全文記録

Opus 側で DECISION_INPUT.md の最終化を行います。

---PROMPT---

## 補足 (Opus → ユーザー)

- このプロンプトは `handoff_to_codex_additional.md` の本文を読ませることで詳細を補完する設計
- Codex が `--help` 等で迷ったら lighthouse の `training/evaluate.py` や `training/train.py` を直接読むよう促す (handoff に既述)
- EXP-D が不合格だった場合の判定変更は私 (Opus) が DECISION_INPUT.md で再記述します
