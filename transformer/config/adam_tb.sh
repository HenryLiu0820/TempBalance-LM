export PYTHONUNBUFFERED=1
bash ~/.bashrc
conda activate ww_train_2

SEED=43
DATA_PATH=/scratch/tpang/zhliu/data/nlp/mt/data-bin/iwslt14.tokenized.de-en.joined
model=transformer
PROBLEM=iwslt14_de_en
ARCH=transformer_iwslt_de_en_v2
tb=True
tbr_after_warm=True
temp_balance_lr=tb_linear_map
metric=alpha
lr_min_ratio=0.6
lr_slope=0.8
xmin_pos=2
fix_fingers=xmin_mid

OUTPUT_PATH=/scratch/tpang/zhliu/checkpoints/nlp/mt/${PROBLEM}/adam_tb/${ARCH}_${PROBLEM}_seed${SEED}/after_warmup_${tbr_after_warm}_${temp_balance_lr}_${metric}/min_${lr_min_ratio}_slope${lr_slope}_${fix_fingers}_mid_pos${xmin_pos}
NUM=5
mkdir -p $OUTPUT_PATH

CUDA_VISIBLE_DEVICES=1 python train.py ${DATA_PATH} \
                            --seed ${SEED} \
                            --adam-eps 1e-08 \
                            --arch ${ARCH} --share-all-embeddings \
                            --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
                            --dropout 0.3 --attention-dropout 0.1 --relu-dropout 0.1 \
                            --criterion label_smoothed_cross_entropy \
                            --lr-scheduler inverse_sqrt --warmup-init-lr 1e-7 --warmup-updates 8000 \
                            --lr 0.0015 --min-lr 1e-9 \
                            --label-smoothing 0.1 --weight-decay 0.0001 \
                            --tb ${tb} --tbr-after-warm ${tbr_after_warm} --temp-balance-lr ${temp_balance_lr} --metric ${metric} \
                            --lr-min-ratio ${lr_min_ratio} --lr-slope ${lr_slope} --xmin-pos ${xmin_pos} --fix-fingers ${fix_fingers} \
                            --max-tokens 4096 --save-dir ${OUTPUT_PATH} \
                            --update-freq 1 --no-progress-bar --log-interval 50 \
                            --ddp-backend no_c10d \
                            --keep-last-epochs ${NUM} --max-epoch 55 \
                            --restore-file ${OUTPUT_PATH}/checkpoint_best.pt \
                            | tee -a ${OUTPUT_PATH}/train_log.txt

# --early-stop ${NUM} \

# python scripts/average_checkpoints.py --inputs ${OUTPUT_PATH} --num-epoch-checkpoints ${NUM} --output ${OUTPUT_PATH}/averaged_model.pt

# BEAM_SIZE=5
# LPEN=1.0
# TRANS_PATH=${OUTPUT_PATH}/trans
# RESULT_PATH=${TRANS_PATH}/

# mkdir -p $RESULT_PATH
# CKPT=averaged_model.pt

# export CUDA_VISIBLE_DEVICES=2; python generate.py \
#     ${DATA_PATH} \
#     --path ${OUTPUT_PATH}/${CKPT} \
#     --batch-size 128 \
#     --beam ${BEAM_SIZE} \
#     --lenpen ${LPEN} \
#     --remove-bpe \
#     --log-format simple \
#     --source-lang de \
#     --target-lang en \
# > ${RESULT_PATH}/res.txt
