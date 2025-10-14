# **BiomedParse**

[Notice] This is v2 of the [`BiomedParse`](https://aka.ms/biomedparse-paper) model, with improved code and model architecture using [`BoltzFormer`](https://openaccess.thecvf.com/content/CVPR2025/papers/Zhao_Boltzmann_Attention_Sampling_for_Image_Analysis_with_Small_Objects_CVPR_2025_paper.pdf). We also provide end-to-end 3D inference. Check [`v1`](https://github.com/microsoft/BiomedParse/tree/main) if you are looking for the original version.

This repository hosts the code and resources for the paper **"A Foundation Model for Joint Segmentation, Detection, and Recognition of Biomedical Objects Across Nine Modalities"** (published in [*Nature Methods*](https://aka.ms/biomedparse-paper)).

[[`Paper`](https://aka.ms/biomedparse-paper)] [[`Demo`](https://microsoft.github.io/BiomedParse/)] [[`Model`](https://huggingface.co/microsoft/BiomedParse)]  [[`Data`](https://huggingface.co/datasets/microsoft/BiomedParseData)]  [[`BibTeX`](#Citation)]

**BiomedParse** is designed for comprehensive biomedical image analysis. It offers a unified approach to perform **segmentation**, **detection**, and **recognition** across diverse biomedical imaging modalities. By consolidating these tasks, BiomedParse provides an efficient and flexible tool tailored for researchers and practitioners, facilitating the interpretation and analysis of complex biomedical data.

![Example Predictions](assets/readmes/biomedparse_prediction_examples.png)

## News
- Jun. 11, 2025: BiomedParse is #1 in the [`CVPR 2025: Foundation Models for Text-guided 3D Biomedical Image Segmentation Challenge`](https://www.codabench.org/competitions/5651/)! We upgraded our model and finetuned on the challenge [`dataset`](https://huggingface.co/datasets/junma/CVPR-BiomedSegFM) with a wider and more comprehensive coverage for 3D biomedical imaging data. Checkout our model in containerized [[`docker image`](https://drive.google.com/file/d/1eUAY1qvEzM0Ut0PA9BGp6gexn5TiFWj8/view?usp=sharing)] for direct inference. Please acknowledge the original challenge if you use this version of the model.
- Jan. 9, 2025: Refined all object recognition script and added notebook with examples.
- Dec. 12, 2024: Uploaded extra datasets for finetuning on [[`Data`](https://huggingface.co/datasets/microsoft/BiomedParseData)]. Added random rotation feature for training.
- Dec. 5, 2024: The loading process of target_dist.json is optimized by automatic downloading from HuggingFace.
- Dec. 3, 2024: We added inference notebook examples in inference_example_RGB.ipynb and inference_example_NIFTI.ipynb
- Nov. 22, 2024: We added negative prediction p-value example in inference_example_DICOM.ipynb
- Nov. 18, 2024: BiomedParse is officially online in [*Nature Methods*](https://aka.ms/biomedparse-paper)!

## Installation
```sh
git clone https://github.com/microsoft/BiomedParse.git
```

### Conda Environment Setup
```sh
conda create -n biomedparse_v2 python=3.10.14
conda activate biomedparse_v2
```

Install dependencies
```sh
pip install -r assets/requirements/requirements.txt 

The above requirements file assumes your environment uses cuda12.4 adjust accordingly for your system/environment

pip install azureml-automl-core
pip install opencv-python
pip install git+https://github.com/facebookresearch/detectron2.git
```



## Model Weights
### Option 1: Hugging Face Hub
You can download the pretrained model weights directly from the Hugging Face Hub.

First, install the required package:
```bash
pip install huggingface_hub
```

Then, download the checkpoint file using the Hugging Face Hub API:
```python
from huggingface_hub import hf_hub_download

# Download the checkpoint file
file_path = hf_hub_download(
    repo_id="microsoft/BiomedParse",
    filename="biomedparse_v2.ckpt"
)

print("Model weights downloaded to:", file_path)
```

### Option 2: Direct Download via Command Line
You can also download the file directly using `wget` or `curl`:
```bash
wget https://huggingface.co/microsoft/BiomedParse/resolve/main/biomedparse_v2.ckpt
```
or
```bash
curl -L -o biomedparse_v2.ckpt https://huggingface.co/microsoft/BiomedParse/resolve/main/biomedparse_v2.ckpt
```

> 💡 **Note:** If the repository is private, log in with your Hugging Face token using:
> ```bash
> huggingface-cli login
> ```
> before attempting to download.


Now you should have the model weights ready for use!

## Fine-tuning BiomedParse V2

Once the model weights are downloaded, you can fine-tune **BiomedParse V2** using our modular YAML configuration system powered by [Hydra](https://hydra.cc/) and [AzureML Olympus](https://learn.microsoft.com/en-us/azure/machine-learning/).

---

### 🧩 How Hydra Works

Hydra enables **composable configuration management** — each logical part of training (model, dataset, trainer, optimizer, etc.) is defined in a separate YAML file and referenced in a master config via the `defaults:` list.

Example structure of `finetune_biomedparse.yaml`:

```yaml
defaults:
  - model: biomedparse
  - datamodule: biomedparse_finetune_datamodule
  - trainer: biomedparse_trainer
  - evaluator: biomedparse_evaluator
  - loss: biomedparse_loss
  - optimizer: adamw
  - olympus_checkpoint: biomedparse_checkpoint_loader
  - _self_
```

When you run a job, Hydra automatically merges these component configs into one runtime configuration.  
You can override any field on the command line without editing YAML files.

For example:

```bash
python -m azureml.acft.image.components.olympus.app.main \
  --config-path configs \
  --config-name finetune_biomedparse \
  trainer.max_epochs=5 optimizer.lr=5e-5 datamodule.dataloaders.train.batch_size=16
```

---

### ⚙️ Running the Fine-tuning Job

To launch a fine-tuning run with default parameters, execute:

```bash
python -m azureml.acft.image.components.olympus.app.main \
  --config-path configs \
  --config-name finetune_biomedparse
```

This will:
1. Load all YAML config components via Hydra.  
2. Initialize the Olympus training pipeline.  
3. Start fine-tuning from the checkpoint defined in the configuration.

---

### 🧾 Baseline Configuration

The baseline configuration is located in the config directories. Start with finetune_biomedparse.yaml and follow the nested structure. 

### 🧠 Dataset Setup

Datasets are defined using modular configs that allow combining multiple datasets.  
Example configuration:

```yaml
_target_: azureml.acft.image.components.olympus.core.ModuleDatasets
train:
  _target_: torch.utils.data.ConcatDataset
  _partial_: True
  datasets:
    - _target_: src.datasets.biomedparse_dataset.BiomedParseDataset
      root_dir: ${mounts.external}/data/MIP3D_CVPR_FT/PET/processed
    - _target_: src.datasets.biomedparse_dataset.BiomedParseDataset
      root_dir: ${mounts.external}/data/MIP3D_CVPR_FT/MR_crossmoda/processed
```
### 💾 Checkpoints

Fine-tuning starts from the pretrained checkpoint specified in your config:

```yaml
checkpoint_path: ${mounts.external}/biomedparse_v2.ckpt
```

You can replace this path with your own checkpoint for continued training or domain adaptation.

---

### 📦 Outputs

Training logs, checkpoints, and metrics are saved to:

```
${mounts.external}/outputs
```

Monitor progress in AzureML or your chosen logging backend.

---

### ✅ Example Override Commands

Change the optimizer and batch size:

```bash
python -m azureml.acft.image.components.olympus.app.main \
  --config-path configs \
  --config-name finetune_biomedparse \
  optimizer=adamw optimizer.lr=1e-4 datamodule.dataloaders.train.batch_size=4
```

Switch loss function or backbone:

```bash
python -m azureml.acft.image.components.olympus.app.main \
  --config-path configs \
  --config-name finetune_biomedparse \
  loss=custom_loss model.backbone=resnet101
```

---

### 🔍 Learn More

- [Hydra Documentation](https://hydra.cc/docs/intro/)
- [AzureML Components](https://learn.microsoft.com/en-us/azure/machine-learning/)
- [PyTorch Lightning](https://lightning.ai/docs/pytorch/stable/)


## Model Inference
The v2 version of BiomedParse supports inference in both 2D and 3D images. The segmentation of 3D volumes is performed in a slice-by-slice 2.5D manner, with neighboring 3D context encoded for each slice in RGB format. Here we provide the example usage of the model weights trained on the CVPR 2025 Text-guided 3D Segmentation Challenge [`dataset`](https://huggingface.co/datasets/junma/CVPR-BiomedSegFM). Please acknowledge the original challenge if you use this version of the model.
### Inference 3D Examples
```sh
import numpy as np
import matplotlib.pyplot as plt
import torch
import torch.nn.functional as F
import hydra
from hydra import compose
from hydra.core.global_hydra import GlobalHydra
from utils import process_input, process_output, slice_nms
from inference import postprocess, merge_multiclass_masks

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Using device:", device)

GlobalHydra.instance().clear()
hydra.initialize(config_path="configs", job_name="example_prediction")
cfg = compose(config_name="biomedparse_3D")
model = hydra.utils.instantiate(cfg, _convert_="object")
model.load_pretrained("model_weights/biomedparse_3D_AllData_MultiView_edge.ckpt")
model = model.to(device).eval()


file_path = "examples/imgs/CT_AMOS_amos_0018.npz"

npz_data = np.load(file_path, allow_pickle=True)
imgs = npz_data["imgs"]
text_prompts = npz_data["text_prompts"].item()

print("Loaded image shape:", imgs.shape)
print("Text prompts:", text_prompts)

ids = [int(_) for _ in text_prompts.keys() if _ != "instance_label"]
ids.sort()
text = "[SEP]".join([text_prompts[str(i)] for i in ids])

imgs, pad_width, padded_size, valid_axis = process_input(imgs, 512)

imgs = imgs.to(device).int()

input_tensor = {
    "image": imgs.unsqueeze(0),  # Add batch dimension
    "text": [text],
}

with torch.no_grad():
    output = model(input_tensor, mode="eval", slice_batch_size=4)

mask_preds = output["predictions"]["pred_gmasks"]
mask_preds = F.interpolate(
    mask_preds,
    size=(512, 512),
    mode="bicubic",
    align_corners=False,
    antialias=True,
)

mask_preds = postprocess(mask_preds, output["predictions"]["object_existence"])
mask_preds = merge_multiclass_masks(mask_preds, ids)
mask_preds = process_output(mask_preds, pad_width, padded_size, valid_axis)
print("Processed mask shape:", mask_preds.shape)
```

Please refer to inference_example_3D.ipynb for more examples.

## Dataset
BiomedParseData was created from preprocessing publicly available biomedical image segmentation datasets. Check a subset of our processed datasets on HuggingFace: https://huggingface.co/datasets/microsoft/BiomedParseData. For the source datasets, please check the details here: [BiomedParseData](assets/readmes/DATASET.md). As a quick start, we've samples a tiny demo dataset at biomedparse_datasets/BiomedParseData-Demo

<!-- ## Model Checkpoints
We host our model checkpoints on HuggingFace here: https://huggingface.co/microsoft/BiomedParse. See example code below on model loading.

Please expect future updates of the model as we are making it more robust and powerful based on feedbacks from the community. We recomment using the latest version of the model.

## Running Inference with BiomedParse

We’ve streamlined the process for running inference using BiomedParse. Below are details and resources to help you get started.

### How to Run Inference
To perform inference with BiomedParse, use the provided example code and resources:

- **Inference Code**: Use the example inference script in `example_prediction.py`.
- **Sample Images**: Load and test with the provided example images located in the `examples` directory.
- **Model Configuration**: The model settings are defined in `configs/biomedparse_inference.yaml`.

### Example Notebooks

We’ve included sample notebooks to guide you through running inference with BiomedParse:

- **RGB Inference Example**: Check out the `inference_examples_RGB.ipynb` notebook for example using normal RGB images, including Pathology, X-ray, Ultrasound, Endoscopy, Dermoscopy, OCT, Fundus.
- **DICOM Inference Example**: Check out the `inference_examples_DICOM.ipynb` notebook for example using DICOM images.
- **NIFTI Inference Example**: Check out the `inference_examples_NIFTI.ipynb` notebook for example using NIFTI image slices.
- You can also try a quick online demo: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/microsoft/BiomedParse/blob/main/inference_colab_demo.ipynb)

### Model Setup
```sh
from PIL import Image
import torch
from modeling.BaseModel import BaseModel
from modeling import build_model
from utilities.distributed import init_distributed
from utilities.arguments import load_opt_from_config_files
from utilities.constants import BIOMED_CLASSES
from inference_utils.inference import interactive_infer_image
from inference_utils.output_processing import check_mask_stats
import numpy as np

# Build model config
opt = load_opt_from_config_files(["configs/biomedparse_inference.yaml"])
opt = init_distributed(opt)

# Load model from pretrained weights
#pretrained_pth = 'pretrained/biomed_parse.pt'
pretrained_pth = 'hf_hub:microsoft/BiomedParse'

model = BaseModel(opt, build_model(opt)).from_pretrained(pretrained_pth).eval().cuda()
with torch.no_grad():
    model.model.sem_seg_head.predictor.lang_encoder.get_text_embeddings(BIOMED_CLASSES + ["background"], is_eval=True)
```

### Segmentation On Example Images
```sh
# RGB image input of shape (H, W, 3). Currently only batch size 1 is supported.
image = Image.open('examples/Part_1_516_pathology_breast.png', formats=['png'])
image = image.convert('RGB')
# text prompts querying objects in the image. Multiple ones can be provided.
prompts = ['neoplastic cells', 'inflammatory cells']

# load ground truth mask
gt_masks = []
for prompt in prompts:
    gt_mask = Image.open(f"examples/Part_1_516_pathology_breast_{prompt.replace(' ', '+')}.png", formats=['png'])
    gt_mask = 1*(np.array(gt_mask.convert('RGB'))[:,:,0] > 0)
    gt_masks.append(gt_mask)

pred_mask = interactive_infer_image(model, image, prompts)

# prediction with ground truth mask
for i, pred in enumerate(pred_mask):
    gt = gt_masks[i]
    dice = (1*(pred>0.5) & gt).sum() * 2.0 / (1*(pred>0.5).sum() + gt.sum())
    print(f'Dice score for {prompts[i]}: {dice:.4f}')
    check_mask_stats(image, pred_mask[i]*255, 'X-Ray-Chest', text_prompt[i])
    print(f'p-value for {prompts[i]}: {p_value:.4f}')
```


Detection and recognition inference code are provided in `inference_utils/output_processing.py`.

- `check_mask_stats()`: Outputs p-value for model-predicted mask for detection. Check the `inference_examples_RGB.ipynb` notebook.
- `combine_masks()`: Combines predictions for non-overlapping masks.

## Finetune on Your Own Data
While BiomedParse can take in arbitrary image and text prompt, it can only reasonably segment the targets that it has learned during pretraining! If you have a specific segmentation task that the latest checkpint doesn't do well, here is the instruction on how to finetune it on your own data.

### Raw Image and Annotation
BiomedParse expects images and ground truth masks in 1024x1024 PNG format. For each dataset, put the raw image and mask files in the following format
```
├── biomedparse_datasets
    ├── YOUR_DATASET_NAME
        ├── train
        ├── train_mask
        ├── test
        └── test_mask
```
Each folder should contain .png files. The mask files should be binary images where pixels != 0 indicates the foreground region.

### File Name Convention
Each file name follows certain convention as

[IMAGE-NAME]\_[MODALITY]\_[SITE].png

[IMAGE-NAME] is any string that is unique for one image. The format can be anything.
[MODALITY] is a string for the modality, such as "X-Ray"
[SITE] is the anatomic site for the image, such as "chest"

One image can be associated with multiple masks corresponding to multiple targets in the image. The mask file name convention is

[IMAGE-NAME]\_[MODALITY]\_[SITE]\_[TARGET].png

[IMAGE-NAME], [MODALITY], and [SITE] are the same with the image file name.
[TARGET] is the name of the target with spaces replaced by '+'. E.g. "tube" or "chest+tube". Make sure "_" doesn't appear in [TARGET].

### Get Final Data File with Text Prompts
In biomedparse_datasets/create-customer-datasets.py, specify YOUR_DATASET_NAME. Run the script with
```
cd biomedparse_datasets
python create-customer-datasets.py
```
After that, the dataset folder should be of the following format
```
├── dataset_name
        ├── train
        ├── train_mask
        ├── train.json
        ├── test
        ├── test_mask
        └── test.json
```

### Register Your Dataset for Training and Evaluation
In datasets/registration/register_biomed_datasets.py, simply add YOUR_DATASET_NAME to the datasets list. Registered datasets are ready to be added to the training and evaluation config file configs/biomed_seg_lang_v1.yaml. Your training dataset is registered as biomed_YOUR_DATASET_NAME_train, and your test dataset is biomed_YOUR_DATASET_NAME_test.


## Train BiomedParse
To train the BiomedParse model, run:

```sh
bash assets/scripts/train.sh
```
This will continue train the model using the training datasets you specified in configs/biomed_seg_lang_v1.yaml

## Evaluate BiomedParse
To evaluate the model, run:
```sh
bash assets/scripts/eval.sh
```
This will continue evaluate the model on the test datasets you specified in configs/biomed_seg_lang_v1.yaml. We put BiomedParseData-Demo as the default. You can add any other datasets in the list. -->


## Citation

Please cite our paper if you use the code, model, or data.

```bibtex
@article{zhao2025foundation,
  title={A foundation model for joint segmentation, detection and recognition of biomedical objects across nine modalities},
  author={Zhao, Theodore and Gu, Yu and Yang, Jianwei and Usuyama, Naoto and Lee, Ho Hin and Kiblawi, Sid and Naumann, Tristan and Gao, Jianfeng and Crabtree, Angela and Abel, Jacob and others},
  journal={Nature methods},
  volume={22},
  number={1},
  pages={166--176},
  year={2025},
  publisher={Nature Publishing Group US New York}
}
```

If you use the v2 code or model, please also cite the BoltzFormer paper:
```bibtex
@inproceedings{zhao2025boltzmann,
  title={Boltzmann Attention Sampling for Image Analysis with Small Objects},
  author={Zhao, Theodore and Kiblawi, Sid and Usuyama, Naoto and Lee, Ho Hin and Preston, Sam and Poon, Hoifung and Wei, Mu},
  booktitle={Proceedings of the Computer Vision and Pattern Recognition Conference},
  pages={25950--25959},
  year={2025}
}
```

## Usage and License Notices
The model described in this repository is provided for research and development use only. The model is not intended for use in clinical decision-making or for any other clinical use, and the performance of the model for clinical use has not been established. You bear sole responsibility for any use of this model, including incorporation into any product intended for clinical use.
