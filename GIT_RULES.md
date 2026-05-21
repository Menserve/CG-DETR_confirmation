# GIT_RULES.md

## このプロジェクトの Git 運用ルール

1. このリポジトリは `gitw` を使って操作する。
2. `lighthouse/` は上流 clone のため、親リポジトリでは追跡しない。
3. 重い生成物 (`downloads/`, `logs/`, `*.ckpt`, `*.npz`) はコミットしない。
4. 判定に使う文書 (`CANON.md`, `DECISION_INPUT.md`, `RESULTS_*.md`) は必ずコミットする。
5. 実験を再現する起動点 (`runbook.sh`, `train_with_override.py`) の変更は必ずコミットする。
6. `team_repo` には書き込み禁止 (読み取りのみ)。

## よく使うコマンド

```bash
./gitw status
./gitw add .
./gitw commit -m "docs: update decision input"
./gitw log --oneline -n 10
```
