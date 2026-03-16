update scripts set content = $SCRIPT$
#!/bin/bash
set -e

source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== HEAVEN MODE — Starting ==="

if [[ ! -d "${COMFYUI_DIR}" ]]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

if [[ -f requirements.txt ]]; then
    pip install --no-cache-dir -r requirements.txt > /dev/null 2>&1
fi

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/GACLove/ComfyUI-VFI"
    "https://github.com/yoyodontsnitch777/node"
)

WAN_FP8_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/SteadyDancer/Wan21_SteadyDancer_fp8_e4m3fn_scaled_KJ.safetensors"
)

WAN_JSON_MODELS=(
    "https://huggingface.co/diego97martinez/video_baile_stady_dancer/resolve/main/WAN2-1-SteadyDancer-FP8.json"
)

LORA_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/a328a632b80d44062fda7df9b6b1a7b2c3a5cf2c/Wan2_1_VAE_bf16.safetensors"
)

CLIP_VISION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

TEXT_ENCODER_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors"
)

UPSCALE_MODELS=(
    "https://raw.githubusercontent.com/gamefurius32-lgtm/upsclane1xskin/main/1xSkinContrast-SuperUltraCompact%20(3).pth"
)

WAN_ANIMATE_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
)

LORA_MODELS_EXTRA=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors"
)

TEXT_ENCODER_FP8=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

VAE_MODELS_NEW=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

CLIP_VISION_NEW=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

DETECTION_MODELS=(
    "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx"
    "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors"
)

download_files() {
    local dir="$1"
    shift
    mkdir -p "$dir"
    for url in "$@"; do
        if [[ -n "$HF_TOKEN" && "$url" =~ huggingface.co ]]; then
            wget --header="Authorization: Bearer $HF_TOKEN" -nc --content-disposition -P "$dir" "$url" > /dev/null 2>&1
        else
            wget -nc --content-disposition -P "$dir" "$url" > /dev/null 2>&1
        fi
    done
}

mkdir -p custom_nodes
for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="custom_nodes/${dir}"
    if [[ -d "$path" ]]; then
        (cd "$path" && git pull) > /dev/null 2>&1
    else
        git clone "$repo" "$path" --recursive > /dev/null 2>&1
    fi
    [[ -f "${path}/requirements.txt" ]] && pip install --no-cache-dir -r "${path}/requirements.txt" > /dev/null 2>&1
done

mkdir -p models/detection
mkdir -p models/controlnet
download_files "models/diffusion_models" "${WAN_JSON_MODELS[@]}"
download_files "models/diffusion_models" "${WAN_FP8_MODELS[@]}"
download_files "models/loras" "${LORA_MODELS[@]}"
download_files "models/vae" "${VAE_MODELS[@]}"
download_files "models/clip_vision" "${CLIP_VISION_MODELS[@]}"
download_files "models/text_encoders" "${TEXT_ENCODER_MODELS[@]}"
download_files "models/upscale_models" "${UPSCALE_MODELS[@]}"
download_files "models/diffusion_models" "${WAN_ANIMATE_MODELS[@]}"
download_files "models/loras" "${LORA_MODELS_EXTRA[@]}"
download_files "models/text_encoders" "${TEXT_ENCODER_FP8[@]}"
download_files "models/vae" "${VAE_MODELS_NEW[@]}"
download_files "models/clip_vision" "${CLIP_VISION_NEW[@]}"
download_files "models/detection" "${DETECTION_MODELS[@]}"
download_files "models/controlnet" "${CONTROLNET_MODELS[@]}"

# Rename models
mv -f "models/diffusion_models/Wan21_SteadyDancer_fp8_e4m3fn_scaled_KJ.safetensors" "models/diffusion_models/sd_dance.safetensors" 2>/dev/null || true
mv -f "models/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" "models/diffusion_models/animate.safetensors" 2>/dev/null || true
mv -f "models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" "models/loras/lx2v_r64.safetensors" 2>/dev/null || true
mv -f "models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" "models/loras/lx2v_r256.safetensors" 2>/dev/null || true
mv -f "models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" "models/loras/lx2v_hn.safetensors" 2>/dev/null || true
mv -f "models/loras/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" "models/loras/fun_ln.safetensors" 2>/dev/null || true
mv -f "models/loras/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" "models/loras/wanPus.safetensors" 2>/dev/null || true

echo "=== Starting ComfyUI ==="

python main.py --listen 0.0.0.0 --port 8188
$SCRIPT$
where name = 'heaven_mode';

update scripts set content = replace(content, E'\r\n', E'\n') where name = 'heaven_mode';
