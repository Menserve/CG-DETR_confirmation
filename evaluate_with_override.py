"""
Wrapper around lighthouse/training/evaluate.py with:
- CLI override for results_dir
- Standardized invocation from project root without modifying lighthouse code
"""
import argparse
import os
import sys

REPO = "/home/menserve/CG-DETR/lighthouse"
os.chdir(REPO)
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "training"))

from training.config import BaseOptions
from training.evaluate import check_valid_combination, start_inference


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--model", "-m", required=True)
    p.add_argument("--dataset", "-d", required=True)
    p.add_argument("--feature", "-f", required=True)
    p.add_argument("--model_path", required=True)
    p.add_argument("--split", required=True, choices=["val", "test"])
    p.add_argument("--eval_path", required=True)
    p.add_argument("--domain", "-dm", default=None)
    p.add_argument("--results_dir", default=None)
    return p.parse_args()


def main():
    args = parse_args()
    if not check_valid_combination(args.dataset, args.feature, args.domain):
        raise ValueError(
            f"Invalid combination: dataset={args.dataset}, feature={args.feature}, domain={args.domain}"
        )

    option_manager = BaseOptions(args.model, args.dataset, args.feature, False, args.domain)
    option_manager.parse()
    opt = option_manager.option

    if args.results_dir is not None:
        opt.results_dir = args.results_dir
    os.makedirs(opt.results_dir, exist_ok=True)

    opt.model_path = args.model_path
    opt.eval_split_name = args.split
    opt.eval_path = args.eval_path

    print(f"[override] results_dir = {opt.results_dir}")
    print(f"[override] split       = {opt.eval_split_name}")
    print(f"[override] eval_path    = {opt.eval_path}")
    print(f"[override] model_path   = {opt.model_path}")

    start_inference(opt, domain=args.domain)


if __name__ == "__main__":
    main()
