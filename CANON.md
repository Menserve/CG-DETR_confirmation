# CANON.md — CG-DETR 独立再現プロジェクト 正典

このファイルが本プロジェクトの単一参照点。他の md と矛盾があれば本ファイルが優先する。
最終更新: 2026-05-21 (Opus, 全 Phase + Bug fix A/B 完了、棄却維持確定)

---

## 0. プロジェクト所在地

- 独立環境: `/home/menserve/CG-DETR/`
- team_repo: `/home/menserve/compe_YCU/team_repo/` (**変更禁止**)
- 締切: 2026-06-15

---

## 1. 動機 (なぜこれをやっているか)

team_repo で出かかっている「CG-DETR 棄却確定」を、独立環境で再検証する。
判断軸は **(a) 手法本来の限界か / (b) 実装・環境 confound か** の分離。

### 棄却の経緯

| 日付 | 状態 |
|------|------|
| 2026-05-19 | 一度目の棄却判断 |
| 2026-05-20 朝 | A-aug mixup confound 疑いで「暫定」に格下げ |
| 2026-05-20 夜 | 分離実験で confound 統制済み → 棄却「確定」に戻る |
| 2026-05-21〜 | **本独立再現開始** (confound 統制が本当に十分かを別環境で再検証) |

### 棄却の中心根拠

- 主 gate: **CASTELLA val R1@0.7 ≧ 31.82** (UVCOM A-aug s1 基準)
- CG-DETR b64 s1: val 26.42 / test 19.97 → 失敗

### 棄却の意味

- **active strategy から外す** のみ
- コード・artifact は保持 (削除しない)
- governance 文言の差し替え

詳細: `~/.claude/projects/-home-menserve-CG-DETR/memory/project_cgdetr_rejection_context.md`

---

## 2. 判定マトリクス

| Phase 1 (A: 論文系) | Phase 2 (B: 転移) | 判定 |
|--------------------|-------------------|------|
| Pass | Fail | 実装健全、棄却根拠は転移ギャップ → **棄却支持** |
| Pass | **Pass** | 実装健全、転移も効く → **棄却再考** (本独立再現の confound 反証) |
| Fail | — | 環境問題未解決 → **棄却保留** |

**判定の重要原則**:
- 厳密な定量比較は不要
- 短時間で定性的方向性が出ればよい
- Phase 2 では **R1@0.7** を主軸とし UVCOM gate 31.82 との比較で判定する
- R1@0.5 / mAP の改善幅単独では判定しない

---

## 3. 役割分担

| 担当 | 範囲 | 状態 |
|------|------|------|
| **Opus** (このセッション) | Phase 0 setup / Phase 2 実行 / 結果文書化 / DECISION_INPUT 作成 | Phase 0 完了、Phase 2 smoke 完了、Phase 2 full 起動待機中 |
| **Codex** (別セッション) | Phase 1 (QVH eval) / Phase 2 補助デバッグ | Phase 1 実行中 (権限調整後) |
| **GPT-5.5** | DECISION_INPUT.md を読んで最終判定 | 全 Phase 完了後 |

---

## 4. Phase 進捗 — **全 Phase 完了 (2026-05-21)**

### Phase 0: 独立環境セットアップ — **完了**
- 詳細: [SETUP_REPORT.md](SETUP_REPORT.md)

### Phase 1: QVHighlights CG-DETR — **完了 (A pass)**
- 公式 ckpt eval: 5/5 metric 完全一致
- EXP-D scratch 学習: paper 値レンジ再現 (R1@0.5=65.87, R1@0.7=51.23)
- 結果: [RESULTS_QVH.md](RESULTS_QVH.md)

### Phase 2: Clotho→CASTELLA 転移 — **完了 (B fail: gate 未達)**
- smoke / full / multi-seed (EXP-B) / test (EXP-A) 全実施
- B1 ft (buggy) val R1@0.7 mean 22.35±3.13 < UVCOM gate 31.82
- 結果: [RESULTS_CASTELLA.md](RESULTS_CASTELLA.md)

### Bug fix A/B — **完了 (棄却維持)**
- 中盤に lighthouse cg_detr の 2 バグを発見・修正 (Codex)
- Stage 1 (fix ft) R1@0.7=26.42, Stage 2 (full fix) 22.73 → いずれも gate 未達
- fix 効果 +2.56pt は gate 突破に必要な +7.96pt に不足
- 結果: RESULTS_CASTELLA.md §4.5, DECISION_INPUT.md §4.5

### 最終判定: **棄却確定を維持** — [DECISION_INPUT.md](DECISION_INPUT.md) で GPT-5.5 に最終確認を委ねる

---

## 5. ファイル地図

| カテゴリ | path | 役割 |
|---------|------|------|
| **正典** | `CANON.md` | このファイル (単一参照点) |
| 文書 | `SETUP_REPORT.md` | Phase 0 セットアップ詳細・MD5 ハッシュ |
| 文書 | `RESULTS_CASTELLA.md` | Phase 2 smoke 結果 |
| 文書 | `RESULTS_QVH.md` | Phase 1 結果 (Codex 作成予定) |
| 文書 | `DECISION_INPUT.md` | GPT-5.5 向け判定要約 |
| Codex 指示書 | `handoff_to_codex_phase1.md` | Phase 1 委託内容 |
| 旧 Codex 指示書 | `handoff_to_codex.md` | (Phase 0→Codex 引継時のもの、参考) |
| 実行スクリプト | `runbook.sh` | 全 Phase の起動エントリポイント |
| 学習 wrapper | `train_with_override.py` | n_epoch/seed/results_dir/es_patience override |
| Phase 0 smoke | `lighthouse/smoke_test.py` | パイプライン検証用 (Phase 0 でのみ使用) |
| Memory | `~/.claude/projects/-home-menserve-CG-DETR/memory/` | 自動参照される長期記憶 |

---

## 6. 環境

| 項目 | 値 |
|------|---|
| lighthouse commit | `d095eaa552cecef240897a8b750306b3b2a08740` |
| Python | 3.12.3 |
| venv | `/home/menserve/CG-DETR/.venv/bin/python` |
| torch | 2.11.0+cu128 |
| GPU | RTX 5090 (34.2 GB) |
| seed | 2023 (全 Phase 共通) |

---

## 7. 起動エントリポイント

すべて `runbook.sh` 経由で起動する (LD_LIBRARY_PATH や PYTHONPATH の自動設定込み)。

```bash
bash /home/menserve/CG-DETR/runbook.sh check         # 環境チェック
bash /home/menserve/CG-DETR/runbook.sh setup_qvh     # QVH features 解凍
bash /home/menserve/CG-DETR/runbook.sh phase1_eval   # Phase 1: QVH eval (Codex 担当)
bash /home/menserve/CG-DETR/runbook.sh phase2_smoke  # Phase 2 smoke (実行済み)
bash /home/menserve/CG-DETR/runbook.sh phase2_full   # Phase 2 full (early stopping 連続チェーン)
```

### `phase2_full` の挙動

```
B0 (CASTELLA, max 100ep, patience 15) 
  → B1 pretrain (Clotho, max 100ep, patience 15)
    → B1 finetune (CASTELLA from B1 pretrain best.ckpt, max 100ep, patience 15)
      → 全結果サマリ表示
```

各 stage は `results/full_b0`, `results/full_b1_pretrain`, `results/full_b1_finetune` に出力。
早期停止で約 100 分以内で完了見込み。

---

## 8. 不変ルール (全エージェント共通)

1. `/home/menserve/compe_YCU/team_repo/` は **一切触らない** (読み取りのみ可)
2. `lighthouse/` 配下の上流コードは **原則編集禁止**
   - 必要な変更は `train_with_override.py` のような外部 wrapper / patch に分離
   - **例外: 明確な実装バグの修正は許可**。ただし (a) fix 内容 (before/after) (b) 影響定量 (同一 ckpt での loss 差分等) を必ず DECISION_INPUT/RESULTS に記録する。2026-05-21 の cg_detr saliency loss バグ修正がこの例外の前例。
3. 推測で埋めず「未確認」と記録する
4. 全コマンド・全 metric・全 artifact path をログ化する
5. cuda:True を確認しない状態で GPU ジョブを起動しない
6. Codex セッションと Opus セッションで **同時に GPU ジョブを走らせない** (VRAM 競合回避)
7. **判定文書 (CANON / DECISION_INPUT / RESULTS_*) の編集は Opus が担当**。Codex は実験実行と結果報告のみ (文書編集しない)

---

## 9. 既知の落とし穴

| 問題 | 対処 |
|------|------|
| `train.py` は `--n_epoch / --seed / --results_dir` を受け付けない | `train_with_override.py` 経由で起動する |
| `max_es_cnt` は base.yml にあるが lighthouse 実装で未使用 | `train_with_override.py --es_patience` で代替 |
| Codex セッションで `cuda: False` (NVML init fail) | WSL2/VSCode 再起動 + 権限設定 |
| Clotho-moment 特徴量は 2 path に分散 | symlink は `features/features/clotho-moment/clap` (51240 files の方) を使う |
| QVH features zip は `QVHighlight/` で展開される | `lighthouse/features/qvhighlight` から symlink |
| cg_detr saliency loss / models.py に実装バグ (2026-05-21 修正済) | fix 済。詳細は DECISION_INPUT §4.5。buggy 結果と fix 結果は両方保持 |

---

## 10. 最終状態 (2026-05-21 全 Phase + Bug fix A/B 完了)

### 結論
- **A (Phase 1)**: Pass / **B (Phase 2)**: Fail (gate 未達) → **棄却確定を維持**
- bug fix 後も R1@0.7 最良 26.42 < UVCOM gate 31.82 (詳細 DECISION_INPUT §4.5)

### 残アクション
1. **GPT-5.5**: [DECISION_INPUT.md](DECISION_INPUT.md) を読んで最終判定 (棄却維持を確認 / 異議)
2. **Opus**: GPT-5.5 判定後、必要なら team_repo governance へのフィードバック案作成
3. (将来) 再考トリガー (DECISION_INPUT §6) に該当する事象が出たら再開
