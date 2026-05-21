# SETUP_REPORT.md — Phase 0: 独立環境セットアップ
作成日: 2026-05-20  
作成者: Sonnet (Phase 0)

---

## 1. 独立ディレクトリ構成

```
/home/menserve/CG-DETR/
├── lighthouse/              # line/lighthouse clone (独立・team_repo非接触)
├── .venv/                   # uv 管理 venv
├── downloads/               # ダウンロード成果物
│   └── pretrained_weights.zip  (44.7GB, ダウンロード中)
└── SETUP_REPORT.md (本ファイル)
```

**重要**: team_repo (`/home/menserve/compe_YCU/team_repo/`) は一切変更していない。

---

## 2. lighthouse clone

| 項目 | 値 |
|------|-----|
| リポジトリ | https://github.com/line/lighthouse |
| commit hash | `d095eaa552cecef240897a8b750306b3b2a08740` |
| commit message | `Merge pull request #73 from line/bug/castella` |
| clone 日時 | 2026-05-20 |
| team_repo 側 commit | `d095eaa` (同一 — 最新 HEAD と一致確認済み) |

---

## 3. Python / CUDA 環境

| 項目 | 値 |
|------|-----|
| Python | 3.12.3 (CPython) |
| uv | /home/menserve/.local/bin/uv |
| venv path | /home/menserve/CG-DETR/.venv |
| GPU | NVIDIA GeForce RTX 5090 |
| VRAM | 34.2 GB |
| Driver | 591.86 / CUDA 13.1 |
| torch | 2.11.0+cu128 |
| torchvision | 0.26.0+cu128 |
| torchaudio | 2.11.0+cu128 |
| cuda available | True (実機確認済み) |
| transformers | 4.51.3 |
| numpy | 1.26.4 |

**備考**: cu128 は CUDA 13.1 ドライバ上で後方互換動作確認済み。  
team_repo の torch バージョン (`2.11.0+cu128`) と統一。

---

## 4. 取得データ / feature 一覧

### 4.1 アノテーションファイル (lighthouse/data/ — git 管理済み)

| ファイル | 行数 | MD5 |
|---------|------|-----|
| castella/castella_train_release.jsonl | 2182 | `937fffdcd431c89a65457c4e09097d72` |
| castella/castella_val_release.jsonl | 352 | `7109907e4d1300eb84e8f447c5729837` |
| castella/castella_test_release.jsonl | (全) | `fa8e3be93e23452a9474d511b1bd2409` |
| clotho_moment/clotho_moment_train_release.jsonl | 32694 | `146555a5333638a4607ec63e3e3e2f71` |
| clotho_moment/clotho_moment_val_release.jsonl | (全) | `cd3707e3964ce5294ad10ad35bda2837` |
| clotho_moment/clotho_moment_test_release.jsonl | (全) | `58193c2fe7cbcc30c79ccbbb0f95dd8c` |
| qvhighlight/highlight_train_release.jsonl | (全) | `e46a5ef1511c4b992cef96fde24b61d0` |
| qvhighlight/highlight_val_release.jsonl | 1549 | `eeb362ecb684b1812376c6ecb73cab84` |
| qvhighlight/highlight_test_release.jsonl | (全) | `b3f23d1ed20769ebc325b2dc0ac085b7` |

### 4.2 CASTELLA 特徴量 (symlink)

| symlink | 実体 | ファイル数 |
|---------|------|-----------|
| lighthouse/features/castella/clap | /home/menserve/compe_YCU/data/features/castella/clap | 1862 |
| lighthouse/features/castella/clap_text | /home/menserve/compe_YCU/data/features/castella/clap_text | 3881 |

サンプル MD5 (castella/clap 先頭5ファイル):
```
d87154ab7fcfc9fb523e45ce0374d54a  --0w1YA1Hm4.npz
652efdeec9fc5e50320e522b6f12526c  -0awng26xQ8.npz
961cc739847d0e0a0ca2adda4b8bb79e  -2oPWkt1y_8.npz
6989d3d4b7f85d1e505d995d10d5792c  -2qHGzHjUOU.npz
794f73bdb982b1ec943fe0735b6c43c7  -2va_YGrK_4.npz
```

### 4.3 Clotho-Moment 特徴量 (symlink)

| symlink | 実体 | ファイル数 |
|---------|------|-----------|
| lighthouse/features/clotho-moment/clap | /home/menserve/compe_YCU/data/features/features/clotho-moment/clap | 51240 |
| lighthouse/features/clotho-moment/clap_text | /home/menserve/compe_YCU/data/features/clotho-moment/clap_text | 44261 |

**重要**: clotho-moment/clap は当初 `/home/menserve/compe_YCU/data/features/clotho-moment/clap` (17233 files, 不完全) を symlink していたが、これは train set 32694 のうち 11062 (33.8%) しかカバーしていなかった (B1 pretrain 1回目の実行で FileNotFoundError 発生)。`/home/menserve/compe_YCU/data/features/features/clotho-moment/clap` (51240 files) に張り直し、全 32694 train サンプルをカバー確認済み (2026-05-21 Phase 2 実行中に判明)。

---

## 5. 公式チェックポイント・QVH 特徴量の取得状況

### 5.1 公式 pretrained weights (Google Drive: 1jxs_bvwttXTF9Lk3aKLohkqfYOonLyrO)
- **サイズ**: 44.7 GB (zip)
- **状態**: **ダウンロード完了** (2026-05-21 00:01)
- **保存先**: /home/menserve/CG-DETR/downloads/pretrained_weights.zip
- **QVH CG-DETR ckpt**: 解凍済み → `lighthouse/results/cg_detr/qvhighlight/clip_slowfast/best.ckpt` (144MB)
- **MD5 (ckpt)**: `2492eb33012cda214ac07dc3faabd202`

### 5.2 QVHighlights 特徴量 (Google Drive: 1-ALnsXkA4csKh71sRndMwybxEDqa-dM4)
- **状態**: **未取得 — 手動DL必要**
- **理由**: Google Drive quota 超過 (gdown エラー: "Too many users have viewed or downloaded this file recently") / wget でも Virus scan ページにリダイレクト
- **解決方法**: ブラウザから手動ダウンロード → /home/menserve/CG-DETR/downloads/qvhighlights_features.tar.gz として保存
- **Phase 1 への影響**: QVH eval は このファイルの手動取得まで **待機**

---

## 5.5 CUDA 診断 (Codex チェック時の不一致対応)

Codex チェック実行時に `cuda: False / device_count: 0` が報告された。  
Sonnet 実行環境では `cuda: True` が確認済み。差異の原因と対策:

**原因**: WSL2 では `/usr/lib/wsl/lib/libcuda.so.1` がセッションによっては ldconfig 経由で見えない場合がある。

**対策 (runbook.sh に実装済み)**:
```bash
export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
```

`bash runbook.sh check` 実行時のディスプレイ例:
```
  LD_LIBRARY_PATH=/usr/lib/wsl/lib:
  libcuda.so.1: libcuda.so.1 => /usr/lib/wsl/lib/libcuda.so.1
  cuda: True / device_count: 1 / gpu: NVIDIA GeForce RTX 5090
```

もし上記の修正後も `cuda: False` になる場合は、WSL2 インスタンスを再起動すること。

---

## 6. 未確認事項 / 解消済み

| 項目 | 状態 |
|------|------|
| pretrained_weights.zip の中身構造 | **解消**: `results/<model>/<dataset>/<feature>/best.ckpt` 階層を確認済み |
| QVH CG-DETR ckpt の正確なパス | **解消**: `results/cg_detr/qvhighlight/clip_slowfast/best.ckpt` を抽出済み |
| QVH features の解凍後ディレクトリ構造 | 未確認 (手動 DL 完了後に setup_qvh で確認) |
| castella clap_text の bert との関係 | b_repr 実験専用のため Phase 1/2 では不要 |
| clotho-moment/clap の全カバー | **解消**: 51240 files の path に修正、32694 train 全カバー確認済み (5.5節) |

---

## 7. 参照情報

- 公式 README: https://github.com/line/lighthouse
- CG-DETR 公式: https://github.com/wjun0830/CGDETR
- CASTELLA features (Zenodo): https://zenodo.org/records/17412176
- Clotho features (Zenodo): https://zenodo.org/records/13806234
- AMR ckpt (Zenodo): https://zenodo.org/uploads/17422909 (CASTELLA/Clotho 学習済み)

---

## 8. 公式 Reference Metrics (Phase 1 の期待値)

公式 pretrained_weights.zip に同梱されていた val metrics (`best_qvhighlight_val_preds_metrics.json`):

**CG-DETR / QVHighlights / clip_slowfast (公式ckpt)**

| Metric | Reference (official) |
|--------|---------------------|
| MR R1@0.5 | 66.19 |
| MR R1@0.7 | 49.23 |
| MR mAP avg | 44.48 |
| MR mAP@0.5 | 64.93 |
| MR mAP@0.75 | 45.17 |
| HL Fair mAP | 76.86 |
| HL Fair Hit1 | 79.10 |

これが Phase 1 eval で再現すべき値。ckpt を使った eval 実行なので学習なしで確認可能。

---

## 9. Phase 2 参考値 (team_repo b_repr, 非標準実装)

**注意**: team_repo の b_repr は独自実装 (QD-DETR 派生) で標準 lighthouse CG-DETR とは異なる。  
あくまで方向性の参考値として記録。

| 実験 | R1@0.5 | R1@0.7 | mAP avg | mAP@0.5 | mAP@0.75 | Source |
|------|--------|--------|---------|---------|---------|--------|
| B0 (CASTELLA direct) | 32.44 | 18.86 | 14.88 | 27.66 | 13.33 | team_repo/results/b_repr/castella_ep100 |
| B1 (Clotho pretrain val) | 83.14 | 75.68 | 69.57 | 87.49 | 74.35 | team_repo/results/b_repr/clotho_moment_pretrain_b (Clotho val) |

## 10. Smoke Test 結果 (Phase 0 パイプライン検証)

独立環境での CG-DETR / CASTELLA / clap パイプライン動作確認:

```
=== Smoke: cg_detr / castella / clap ===
  results_dir: results/cg_detr/castella/clap
  a_feat_dirs: ['features/castella/clap']
  t_feat_dir: features/castella/clap_text
  n_epoch: 200
  dataset size: 352
  batch loaded OK: ['src_txt', 'src_txt_mask', 'src_vid', 'src_vid_mask', 'vid', 'qid', 'src_aud', 'src_aud_mask']
  model forward OK: ['pred_logits', 'pred_spans', 'saliency_scores', ...]
  PASS
```

**結論**: Phase 2 (CASTELLA/Clotho) の実行準備は完了。Phase 1 (QVH) は features の手動 DL のみ待ち。
