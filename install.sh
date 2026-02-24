conda create -n biomedparse python=3.9.19
conda activate biomedparse

conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia

# conda install -y -c conda-forge mpi4py mpich  # or openmpi
# conda install cuda-cudart cuda-version=12          

conda install cccl ## for nv/target: No such file or directory error. 
conda install -y -c nvidia cuda-toolkit=12.4
export CUDA_HOME=$CONDA_PREFIX
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib:$LD_LIBRARY_PATH

nvcc --version  # should now be 12.4 (from conda)

## need to install detectron2 separately with no build isolation
pip install --no-build-isolation git+https://github.com/MaureenZOU/detectron2-xyz.git

pip install mpi4py
pip install -r assets/requirements/requirements.txt

pip install webdataset==0.2.86


## reference list of packages is inside my_environment.yaml. 