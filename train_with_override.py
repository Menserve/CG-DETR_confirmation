"""
Wrapper around lighthouse/training/train.py with:
- CLI overrides for n_epoch, seed, results_dir, bsz, eval_epoch_interval, resume
- Early stopping via --es_patience (monkey-patches the training loop)

Lighthouse source is NOT modified.

Usage:
    python train_with_override.py \
        --model cg_detr --dataset castella --feature clap \
        --n_epoch 100 --seed 2023 --results_dir results/full_b0 \
        --es_patience 15
"""
import os
import sys
import copy
import argparse
import pprint
import logging

REPO = '/home/menserve/CG-DETR/lighthouse'
os.chdir(REPO)
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, 'training'))

import torch
from torch.utils.data import DataLoader
from tqdm import trange
from training.config import BaseOptions
from training import train as train_module
from training.train import (
    main, check_valid_combination, train_epoch,
    cg_detr_start_end_collate, start_end_collate,
)
from training.evaluate import eval_epoch
from lighthouse.common.utils.basic_utils import (
    write_log, save_checkpoint, rename_latest_to_best,
)
from lighthouse.common.utils.model_utils import ModelEMA

logger = logging.getLogger('train_with_override')


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--model', '-m', required=True)
    p.add_argument('--dataset', '-d', required=True)
    p.add_argument('--feature', '-f', required=True)
    p.add_argument('--resume', '-r', type=str, default=None)
    p.add_argument('--domain', '-dm', type=str, default=None)
    p.add_argument('--n_epoch', type=int, default=None)
    p.add_argument('--seed', type=int, default=None)
    p.add_argument('--results_dir', type=str, default=None)
    p.add_argument('--bsz', type=int, default=None)
    p.add_argument('--eval_epoch_interval', type=int, default=None)
    p.add_argument('--es_patience', type=int, default=None,
                   help='Early stopping patience (epochs without improvement). '
                        'If None, no early stopping.')
    return p.parse_args()


def make_early_stopping_train(patience):
    """Return a drop-in replacement for train_module.train with early stopping."""
    def train_with_es(model, criterion, optimizer, lr_scheduler,
                      train_dataset, val_dataset, opt):
        opt.train_log_txt_formatter = "{time_str} [Epoch] {epoch:03d} [Loss] {loss_str}\n"
        opt.eval_log_txt_formatter = "{time_str} [Epoch] {epoch:03d} [Loss] {loss_str} [Metrics] {eval_metrics_str}\n"
        collate_fn = cg_detr_start_end_collate if opt.model_name == 'cg_detr' else start_end_collate
        save_submission_filename = f"latest_{opt.dset_name}_val_preds.jsonl"

        train_loader = DataLoader(
            train_dataset, collate_fn=collate_fn,
            batch_size=opt.bsz, num_workers=opt.num_workers, shuffle=True,
        )

        model_ema = ModelEMA(model, decay=opt.ema_decay) if opt.model_ema else None
        if model_ema:
            logger.info('Using model EMA...')

        prev_best_score = 0.0
        es_counter = 0
        best_epoch = -1

        for epoch_i in trange(opt.n_epoch, desc='Epoch'):
            train_epoch(model, criterion, train_loader, optimizer, opt, epoch_i)
            lr_scheduler.step()
            if model_ema:
                model_ema.update(model)

            if (epoch_i + 1) % opt.eval_epoch_interval == 0:
                with torch.no_grad():
                    eval_model = model_ema.module if model_ema else model
                    metrics, eval_loss_meters, latest_file_paths = eval_epoch(
                        epoch_i, eval_model, val_dataset, opt,
                        save_submission_filename, criterion,
                    )
                write_log(opt, epoch_i, eval_loss_meters, metrics=metrics, mode='val')
                logger.info('metrics %s', pprint.pformat(metrics['brief'], indent=4))

                if opt.dset_name in ('tvsum', 'youtube_highlight'):
                    stop_score = metrics['brief']['mAP']
                else:
                    stop_score = metrics['brief']['MR-full-mAP']

                if stop_score > prev_best_score:
                    prev_best_score = stop_score
                    best_epoch = epoch_i
                    es_counter = 0
                    save_checkpoint(model, optimizer, lr_scheduler, epoch_i, opt)
                    logger.info('The checkpoint file has been updated.')
                    rename_latest_to_best(latest_file_paths)
                else:
                    es_counter += 1
                    logger.info(
                        '[early-stop] no improvement: %d/%d (best=%.4f @ epoch %d)',
                        es_counter, patience, prev_best_score, best_epoch + 1,
                    )
                    if patience is not None and es_counter >= patience:
                        logger.info(
                            '[early-stop] Triggered at epoch %d. '
                            'Best score %.4f at epoch %d. Stopping.',
                            epoch_i + 1, prev_best_score, best_epoch + 1,
                        )
                        return

    return train_with_es


def main_wrapper():
    args = parse_args()

    if not check_valid_combination(args.dataset, args.feature, args.domain):
        raise ValueError(f'Invalid combination: {args.dataset}/{args.feature}/{args.domain}')

    om = BaseOptions(args.model, args.dataset, args.feature, args.resume, args.domain)
    om.parse()
    opt = om.option

    if args.results_dir is not None:
        opt.results_dir = args.results_dir
        opt.ckpt_filepath = os.path.join(opt.results_dir, opt.ckpt_filename)
        opt.train_log_filepath = os.path.join(opt.results_dir, opt.train_log_filename)
        opt.eval_log_filepath = os.path.join(opt.results_dir, opt.eval_log_filename)
    if args.n_epoch is not None:
        opt.n_epoch = args.n_epoch
    if args.seed is not None:
        opt.seed = args.seed
    if args.bsz is not None:
        opt.bsz = args.bsz
    if args.eval_epoch_interval is not None:
        opt.eval_epoch_interval = args.eval_epoch_interval

    if args.es_patience is not None:
        train_module.train = make_early_stopping_train(args.es_patience)
        print(f'[override] early-stop patience = {args.es_patience} epochs')

    print(f'[override] results_dir = {opt.results_dir}')
    print(f'[override] n_epoch     = {opt.n_epoch}')
    print(f'[override] seed        = {opt.seed}')
    print(f'[override] bsz         = {opt.bsz}')
    print(f'[override] resume      = {args.resume}')

    om.clean_and_makedirs()
    main(opt, resume=args.resume, domain=args.domain)


if __name__ == '__main__':
    main_wrapper()
