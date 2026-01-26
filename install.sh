conda create -n biomedparse python=3.9.19
conda activate biomedparse

conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia

## need to install detectron2 separately with no build isolation
pip install --no-build-isolation git+https://github.com/MaureenZOU/detectron2-xyz.git

pip install -r assets/requirements/requirements.txt