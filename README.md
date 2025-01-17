# SAFA: Structure Aware Face Animation (3DV2021)
Official Pytorch Implementation of 3DV2021 paper: [**SAFA: Structure Aware Face Animation**](https://arxiv.org/abs/2111.04928).

> :warning: **WARNING**: This repository is a fork of the original [SAFA](https://github.com/Qiulin-W/SAFA) repository, which has been ported to the latest versions of all required external Python modules. I made it working for the following versions: Python 3.9.12, torch 1.11.0, torchvision 0.12.0, CUDA 11.3, and PyTorch3D 0.7.1. Some small bug fixes and other improvements have also been added. Hopefully, these changes will be integrated into the original repository. 

![Screenshot](assets/video_rec1.gif)
![Screenshot](assets/video_rec2.gif)
![Screenshot](assets/source_images.png)
![Screenshot](assets/motion_trans.gif)

![Screenshot](assets/overview.png)

## Getting Started
```
git clone https://github.com/rlaboiss/SAFA.git
```

## Installation
Python 3.6 or higher is recommended. However, PyTorch3d does not seem to work with Python 3.10. Hence, use version 3.9 at most.

### Install PyTorch3D and Other Dependencies
For installing PyTorch3D, follow the guidance from: https://github.com/facebookresearch/pytorch3d/blob/master/INSTALL.md.

However, notice that the installed version PyTorch3D must depend exactly on the same version of CUDA as the installed versions of torch and torchvision, otherwise some dynamically-loaded libraries will fail due to unresolved C++ symbols. One way of accomplishing this is by providing a file of links with the appropriate versions when invoking `pip`, for instance:
```
pip install -r requirements.txt -f https://download.pytorch.org/whl/cu113/torch_stable.html
pip install git+https://github.com/facebookresearch/pytorch3d.git@v0.7.1
```
With the commands above, versions 1.11.0+cu113 and 0.12.0+cu113 of torch and torchvision, respectively, will be installed. They will be compatible with the PyTorch3D installed via GitHub (version 0.7.1).

All the dependencies listed in [requirements.txt](requirements.txt) will be also be installed with the commands above.

N.B.: PyTorch3D is compiled from source with the command above. You need to ensure that conda's `ld` command (in `<conda-dir>/compiler_compat/ld`) is compatible with the `g++` compiler installed in the system. The command below may help to fix incompatibility problems:
```
pip install -c conda-forge gxx binutils
```

## Usage

### 1. Preparation
a. Download [FLAME model](https://flame.is.tue.mpg.de/), choose FLAME 2020 and unzip it, put `generic_model.pkl` under `./modules/data`.

b. Download `head_template.obj`, `landmark_embedding.npy`, `uv_face_eye_mask.png` and `uv_face_mask.png` from [DECA/data](https://github.com/YadiraF/DECA/tree/master/data), and put them under `./module/data`.

c. Download SAFA model checkpoint from [Google Drive](https://drive.google.com/drive/folders/1sXzcAf9mIK08WISz9tjYBocaoTSA3ts_?usp=sharing) and put it under `./ckpt`.

d. (Optional, required by the face swap demo) Download the pretrained face parser from [face-parsing.PyTorch](https://github.com/zllrunning/face-parsing.PyTorch) and put it under `./face_parsing/cp`.

### 2. Demos
We provide demos for animation and face swap.

a. Animation demo
```
python animation_demo.py --config config/end2end.yaml --checkpoint path/to/checkpoint --source_image_pth path/to/source_image --driving_video_pth path/to/driving_video --relative --adapt_scale --find_best_frame
```
This demo can be exercised using the provided [Makefile](Makefile). Just type:
```
make
```
and the `result-elon-musk+original.mp4` file will be created, which contains the original video [assets/02.mp4](assets/02.mp4) and the animated face of Elon Musk side by side. This clip will be created using `ffmpeg`, which must be installed in the system.

b. Face swap demo
We adopt [face-parsing.PyTorch](https://github.com/zllrunning/face-parsing.PyTorch) for indicating the face regions in both the source and driving images.

For preprocessed source images and driving videos, run:
```
python face_swap_demo.py --config config/end2end.yaml --checkpoint path/to/checkpoint --source_image_pth path/to/source_image --driving_video_pth path/to/driving_video
```
For arbitrary images and videos, we use a face detector to detect and swap the corresponding face parts. Cropped images will be resized to 256*256 in order to fit to our model.
```
python face_swap_demo.py --config config/end2end.yaml --checkpoint path/to/checkpoint --source_image_pth path/to/source_image --driving_video_pth path/to/driving_video --use_detection
```

## Training
We modify the distributed traininig framework used in that of the [First Order Motion Model](https://github.com/AliaksandrSiarohin/first-order-model). Instead of using torch.nn.DataParallel (DP), we adopt torch.distributed.DistributedDataParallel (DDP) for faster training and more balanced GPU memory load. The training procedure is divided into two steps: (1) Pretrain the 3DMM estimator, (2) End-to-end Training.

### 3DMM Estimator Pre-training
```
CUDA_VISIBLE_DEVICES="0,1,2,3" python -m torch.distributed.launch --nproc_per_node 4 run_ddp.py --config config/pretrain.yaml
```

### End-to-end Training
```
CUDA_VISIBLE_DEVICES="0,1,2,3" python -m torch.distributed.launch --nproc_per_node 4 run_ddp.py --config config/end2end.yaml --tdmm_checkpoint path/to/tdmm_checkpoint_pth
```

## Evaluation / Inference

### Video Reconstrucion
```
python run_ddp.py --config config/end2end.yaml --checkpoint path/to/checkpoint --mode reconstruction
``` 
### Image Animation
```
python run_ddp.py --config config/end2end.yaml --checkpoint path/to/checkpoint --mode animation
``` 
### 3D Face Reconstruction
```
python tdmm_inference.py --data_dir directory/to/images --tdmm_checkpoint path/to/tdmm_checkpoint_pth
```

## Dataset and Preprocessing
We use [**VoxCeleb1**](https://www.robots.ox.ac.uk/~vgg/data/voxceleb/vox1.html) to train and evaluate our model. Original Youtube videos are downloaded, cropped and splited following the instructions from [video-preprocessing](https://github.com/AliaksandrSiarohin/video-preprocessing). 

a. To obtain the facial landmark meta data from the preprocessed videos, run:
```
python video_ldmk_meta.py --video_dir directory/to/preprocessed_videos out_dir directory/to/output_meta_files
```

b. (Optional) Extract images from videos for 3DMM pretraining:
```
python extract_imgs.py
```

## Citation
If you find our work useful to your research, please consider citing:
```
@article{wang2021safa,
  title={SAFA: Structure Aware Face Animation},
  author={Wang, Qiulin and Zhang, Lu and Li, Bo},
  journal={arXiv preprint arXiv:2111.04928},
  year={2021}
}
```

## License
Please refer to the [LICENSE](LICENSE.md) file.


## Acknowledgement
Here we provide the list of external sources that we use or adapt from:
1. Codes are heavily borrowed from [First Order Motion Model](https://github.com/AliaksandrSiarohin/first-order-model), [LICENSE](https://github.com/AliaksandrSiarohin/first-order-model/blob/master/LICENSE.md). 
2. Some codes are also borrowed from:
a. [FLAME_PyTorch](https://github.com/soubhiksanyal/FLAME_PyTorch), [LICENSE](https://github.com/soubhiksanyal/FLAME_PyTorch/blob/master/LICENSE)
b. [generative-inpainting-pytorch](https://github.com/daa233/generative-inpainting-pytorch), [LICENSE](https://github.com/daa233/generative-inpainting-pytorch/blob/master/LICENSE)
c. [face-parsing.PyTorch](https://github.com/zllrunning/face-parsing.PyTorch), [LICENSE](https://github.com/zllrunning/face-parsing.PyTorch/blob/master/LICENSE)
d. [video-preprocessing](https://github.com/AliaksandrSiarohin/video-preprocessing).
3. We adopt FLAME model resources from:
a. [DECA](https://github.com/YadiraF/DECA), [LICENSE](https://github.com/YadiraF/DECA/blob/master/LICENSE)
b. [FLAME](https://flame.is.tue.mpg.de), [LICENSE](https://flame.is.tue.mpg.de/modellicense.html)
4. External Libaraies:
a. [PyTorch3D](https://github.com/facebookresearch/pytorch3d), [LICENSE](https://github.com/facebookresearch/pytorch3d/blob/main/LICENSE)
b. [face-alignment](https://github.com/1adrianb/face-alignment), [LICENSE](https://github.com/1adrianb/face-alignment/blob/master/LICENSE)
