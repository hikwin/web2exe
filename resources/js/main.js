// Neutralino 初始化
if (window.Neutralino) {
    Neutralino.init();
    Neutralino.events.on("windowClose", () => {
        Neutralino.app.exit();
    });
}

// 打开外部链接：桌面端用系统默认浏览器，浏览器环境降级
function openExternal(url) {
    if (window.Neutralino && Neutralino.os) {
        Neutralino.os.open(url);
    } else {
        window.open(url, "_blank");
    }
}

// 将 data URL 转为 Blob
function dataURLToBlob(dataURL) {
    const parts = dataURL.split(',');
    const mime = parts[0].match(/:(.*?);/)[1];
    const bstr = atob(parts[1]);
    const n = bstr.length;
    const u8arr = new Uint8Array(n);
    for (let i = 0; i < n; i++) {
        u8arr[i] = bstr.charCodeAt(i);
    }
    return new Blob([u8arr], { type: mime });
}

// 定义搜索引擎列表
const engines = [
    ["Google", "https://www.google.com/searchbyimage?client=app&image_url=", "google"],
    ["Google Lens", "https://lens.google.com/uploadbyurl?url=", "lens"],
    ["Yandex.eu", "https://yandex.eu/images/search?url=", "yandex"],
    ["Bing", "https://www.bing.com/images/search?view=detailv2&iss=SBI&form=SBIIRP&sbisrc=UrlPaste&q=imgurl:", "bing"],
    ["TinEye", "https://tineye.com/search/?url=", "tineye"],
    ["3DIQDB", "https://3d.iqdb.org/?url=", "iqdb"],
    ["IQDB", "https://iqdb.org/?url=", "iqdb"],
    ["SauceNAO", "https://saucenao.com/search.php?url=", "saucenao"],
    ["ascii2d", "https://ascii2d.net/search/url/", "ascii2d"],
    ["WAIT", "https://trace.moe/?url=", "anime"],
    ["Trace.moe", "https://trace.moe/?url=", "anime"]
];

// 图标映射
const icons = {
    google: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>',
    lens: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.5 12c0 3.038-2.462 5.5-5.5 5.5s-5.5-2.462-5.5-5.5 2.462-5.5 5.5-5.5 5.5 2.462 5.5 5.5z" stroke="currentColor" fill="none" stroke-width="2"/><path d="M8.5 8.5l7 7" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="9" stroke="currentColor" fill="none" stroke-width="2"/></svg>',
    yandex: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M2.04 12c0-5.523 4.476-10 10-10 5.522 0 10 4.477 10 10s-4.478 10-10 10c-5.524 0-10-4.477-10-10z" fill="#FC3F1D"/><path d="M13.32 7.666h-1.743v5.831c0 .615-.123 1.12-.369 1.513-.246.394-.615.59-1.107.59-.369 0-.677-.123-.923-.369l-.43 1.353c.369.307.861.461 1.476.461.984 0 1.743-.369 2.276-1.107.533-.738.8-1.784.8-3.136V7.666z" fill="#fff"/></svg>',
    bing: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M5 3v13.263L9.1 19l9.9-5.237V8.5L9.1 13.158l-1.8-1.184V6.105L5 3z" fill="#008373"/></svg>',
    tineye: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10" fill="#bd1c2b"/><circle cx="12" cy="12" r="3" fill="white"/></svg>',
    iqdb: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><rect width="20" height="20" x="2" y="2" rx="2" fill="#5f9ea0"/><path d="M7 7h10v2H7zm0 4h10v2H7zm0 4h7v2H7z" fill="white"/></svg>',
    saucenao: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" fill="#FF6138"/><circle cx="12" cy="12" r="4" fill="#FF6138"/></svg>',
    ascii2d: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M4 4h16v16H4z" fill="#3498db"/><path d="M7 12h10M12 7v10" stroke="white" stroke-width="2"/></svg>',
    anime: '<svg class="w-4 h-4 mr-1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" fill="#9C27B0"/></svg>'
};

function generateButtons() {
    let url = document.getElementById("imageUrlInput").value.trim();
    const container = document.getElementById("buttonsContainer");

    // 检查链接合规性
    if (url && !url.match(/^https?:\/\//i)) {
        showNotification("链接格式不正确，请确保以 http:// 或 https:// 开头", "error");
    }

    // 更新搜索引擎按钮的链接
    updateEngineButtons(url);
}

// 清空图片链接输入框
function clearImageUrl() {
    document.getElementById("imageUrlInput").value = "";
    updateEngineButtons("");
    // 清除预览图片
    resetImagePreview();
    showNotification("已清空图片链接", "info");
}

// 重置图片预览为默认状态
function resetImagePreview() {
    const previewContainer = document.getElementById("uploadPreviewContainer");
    previewContainer.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-primary-500 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
        <p class="text-sm text-gray-600">点击或拖放图片到此处上传</p>
        <p class="text-xs text-gray-500 mt-1">支持 JPG, PNG, GIF 等格式</p>
    `;
}

// 全局变量，用于存储多选模式状态
let isMultiSelectMode = false;
let selectedEngines = new Set();

// 切换多选模式
function toggleMultiSelectMode() {
    isMultiSelectMode = document.getElementById("multiSelectToggle").checked;
    const multiSearchButtonContainer = document.getElementById("multiSearchButtonContainer");

    if (isMultiSelectMode) {
        multiSearchButtonContainer.classList.remove("hidden");
    } else {
        multiSearchButtonContainer.classList.add("hidden");
        selectedEngines.clear();
    }

    // 重新生成按钮以反映模式变化
    let url = document.getElementById("imageUrlInput").value.trim();
    updateEngineButtons(url);
}

// 更新搜索引擎按钮的链接
function updateEngineButtons(url) {
    const container = document.getElementById("buttonsContainer");
    container.innerHTML = "";

    // 如果没有URL，创建按钮但禁用它们
    const isUrlValid = url && url.match(/^https?:\/\//i);

    for (const [name, baseLink, icon] of engines) {
        const engineId = name.replace(/\s+/g, '_').toLowerCase();

        if (isMultiSelectMode) {
            // 多选模式：创建带复选框的按钮
            const buttonContainer = document.createElement("div");
            buttonContainer.className = `relative flex items-center ${isUrlValid ? '' : 'opacity-50 cursor-not-allowed'}`;

            // 创建复选框
            const checkbox = document.createElement("input");
            checkbox.type = "checkbox";
            checkbox.id = engineId;
            checkbox.className = "absolute left-2 top-1/2 transform -translate-y-1/2 z-10 w-4 h-4 text-primary-600 bg-gray-100 border-gray-300 rounded focus:ring-primary-500";
            checkbox.disabled = !isUrlValid;
            checkbox.checked = selectedEngines.has(engineId);
            checkbox.onchange = function() {
                if (this.checked) {
                    selectedEngines.add(engineId);
                } else {
                    selectedEngines.delete(engineId);
                }
            };

            // 创建按钮
            const button = document.createElement("button");
            button.className = `flex items-center justify-center w-full px-4 py-2 pl-8 ${isUrlValid ? 'bg-white hover:bg-gray-50' : 'bg-gray-100'} border border-gray-200 rounded-lg transition-colors duration-300 shadow-sm hover:shadow text-gray-700 text-sm`;
            button.innerHTML = (icons[icon] || '') + name;
            button.disabled = !isUrlValid;
            button.onclick = function(e) {
                // 点击按钮时切换复选框状态
                if (isUrlValid) {
                    checkbox.checked = !checkbox.checked;
                    if (checkbox.checked) {
                        selectedEngines.add(engineId);
                    } else {
                        selectedEngines.delete(engineId);
                    }
                    e.preventDefault(); // 防止打开链接
                }
            };

            buttonContainer.appendChild(checkbox);
            buttonContainer.appendChild(button);
            container.appendChild(buttonContainer);
        } else {
            // 单选模式：创建普通按钮
            const button = document.createElement("button");
            button.className = `flex items-center justify-center px-4 py-2 ${isUrlValid ? 'bg-white hover:bg-gray-50' : 'bg-gray-100 cursor-not-allowed'} border border-gray-200 rounded-lg transition-colors duration-300 shadow-sm hover:shadow text-gray-700 text-sm`;
            button.innerHTML = (icons[icon] || '') + name;

            if (isUrlValid) {
                const fullLink = baseLink + url;
                button.onclick = () => openExternal(fullLink);
            }

            container.appendChild(button);
        }
    }
}

// 打开选中的搜索引擎
function openSelectedEngines() {
    const url = document.getElementById("imageUrlInput").value.trim();
    if (!url || !url.match(/^https?:\/\//i)) {
        showNotification("请输入有效的图片链接", "error");
        return;
    }

    if (selectedEngines.size === 0) {
        showNotification("请至少选择一个搜索引擎", "info");
        return;
    }

    // 计数已打开的窗口
    let openedCount = 0;

    // 遍历所有引擎，打开选中的引擎
    for (const [name, baseLink, icon] of engines) {
        const engineId = name.replace(/\s+/g, '_').toLowerCase();
        if (selectedEngines.has(engineId)) {
            const fullLink = baseLink + url;
            openExternal(fullLink);
            openedCount++;
        }
    }

    showNotification(`已打开 ${openedCount} 个搜索引擎`, "success");
}

async function pasteFromClipboard() {
    // 优先使用 Neutralino 剪贴板 API（桌面端更可靠）
    if (window.Neutralino && Neutralino.clipboard) {
        try {
            const fmt = await Neutralino.clipboard.getFormat();
            if (fmt && fmt.format === 'image') {
                const res = await Neutralino.clipboard.readImage();
                if (res && res.image) {
                    const blob = dataURLToBlob(res.image);
                    const file = new File([blob], 'pasted-image.png', { type: 'image/png' });
                    showNotification("正在上传粘贴的图片...", "info");
                    const fileInput = document.getElementById('fileInput');
                    const dataTransfer = new DataTransfer();
                    dataTransfer.items.add(file);
                    fileInput.files = dataTransfer.files;
                    uploadImage(fileInput);
                    return;
                }
            } else if (fmt && fmt.format === 'text') {
                const res = await Neutralino.clipboard.readText();
                if (res && res.text) {
                    const text = res.text.trim();
                    document.getElementById("imageUrlInput").value = text;
                    generateButtons();
                    return;
                }
            }
        } catch (err) {
            console.warn("Neutralino 剪贴板读取失败，回退到浏览器 API:", err);
        }
    }

    // 浏览器环境降级逻辑
    try {
        const clipboardItems = await navigator.clipboard.read();

        for (const clipboardItem of clipboardItems) {
            if (clipboardItem.types.includes('image/png') ||
                clipboardItem.types.includes('image/jpeg') ||
                clipboardItem.types.includes('image/gif') ||
                clipboardItem.types.includes('image/webp')) {

                const imageType = clipboardItem.types.find(type => type.startsWith('image/'));
                const blob = await clipboardItem.getType(imageType);
                const file = new File([blob], `pasted-image.${imageType.split('/')[1]}`, { type: imageType });

                showNotification("正在上传粘贴的图片...", "info");

                const fileInput = document.getElementById('fileInput');
                const dataTransfer = new DataTransfer();
                dataTransfer.items.add(file);
                fileInput.files = dataTransfer.files;

                uploadImage(fileInput);
                return;
            }
        }

        let text = await navigator.clipboard.readText();
        text = text.trim();
        document.getElementById("imageUrlInput").value = text;
        generateButtons();
    } catch (err) {
        console.error("剪贴板操作失败:", err);
        try {
            let text = await navigator.clipboard.readText();
            text = text.trim();
            document.getElementById("imageUrlInput").value = text;
            generateButtons();
        } catch (textErr) {
            showNotification("读取剪贴板失败，请检查权限或使用 HTTPS", "error");
        }
    }
}

// 显示图片预览
function displayImagePreview(imageUrl) {
    const previewContainer = document.getElementById("uploadPreviewContainer");
    previewContainer.innerHTML = `
        <div class="relative w-full h-full flex items-center justify-center">
            <img src="${imageUrl}" class="max-h-24 max-w-full object-contain rounded-lg" alt="预览图片" />
        </div>
    `;
}

// 图床持久化键名
const STORAGE_KEY_HOST = 'img_search_preferred_host';
const STORAGE_KEY_CUSTOM_WORKER = 'img_search_custom_worker_url';
const DEFAULT_CUSTOM_WORKER = '';

// 图床元数据与适配器
const IMAGE_HOST_CONFIGS = {
    auto: {
        name: '智能多源容灾',
        badgeText: '⚡ 智能故障转移 · 稳定免登录',
        badgeClass: 'bg-emerald-50 text-emerald-600 border-emerald-200'
    },
    picui: {
        name: '皮卡图床 (PicUI)',
        badgeText: '国内 CDN · 免登录',
        badgeClass: 'bg-rose-50 text-rose-600 border-rose-200',
        upload: uploadToPicUI
    },
    tumy: {
        name: '图麦图床 (tu.my)',
        badgeText: '国内高速 · 免登录',
        badgeClass: 'bg-amber-50 text-amber-600 border-amber-200',
        upload: uploadToTuMy
    },
    sxcu: {
        name: 'SXCU 图床',
        badgeText: '国际直链 · 免登录',
        badgeClass: 'bg-sky-50 text-sky-600 border-sky-200',
        upload: uploadToSxcu
    },
    imgur: {
        name: 'Imgur 全球图库',
        badgeText: '全球最大 · 搜图友好',
        badgeClass: 'bg-purple-50 text-purple-600 border-purple-200',
        upload: uploadToImgur
    },
    custom: {
        name: '自定义 Worker / 自建图床',
        badgeText: '自建节点 · 可自定义',
        badgeClass: 'bg-blue-50 text-blue-600 border-blue-200',
        upload: uploadToCustomWorker
    }
};

// 初始化图床设置（恢复记忆）
function initImageHostSettings() {
    const select = document.getElementById('imageHostSelect');
    const customInput = document.getElementById('workerUrlInput');

    let savedHost = localStorage.getItem(STORAGE_KEY_HOST) || 'auto';
    let savedCustomUrl = localStorage.getItem(STORAGE_KEY_CUSTOM_WORKER) || DEFAULT_CUSTOM_WORKER;

    // 检查当前记忆的选项是否有效
    if (!IMAGE_HOST_CONFIGS[savedHost]) {
        savedHost = 'auto';
    }

    if (select) {
        select.value = savedHost;
    }
    if (customInput) {
        customInput.value = savedCustomUrl;
    }
    updateHostUI(savedHost);
}

// 下拉切换图床处理
function onImageHostChange() {
    const select = document.getElementById('imageHostSelect');
    const currentHost = select.value;
    localStorage.setItem(STORAGE_KEY_HOST, currentHost);
    updateHostUI(currentHost);

    const config = IMAGE_HOST_CONFIGS[currentHost];
    const name = config ? config.name : currentHost;
    showNotification(`已切换并自动记住图床：${name}`, 'info');
}

// 记忆自定义 Worker 地址
function saveCustomWorkerUrl() {
    const customInput = document.getElementById('workerUrlInput');
    const url = customInput.value.trim();
    if (url) {
        localStorage.setItem(STORAGE_KEY_CUSTOM_WORKER, url);
    }
}

// 更新图床 UI 状态标签和自定义输入框显示状态
function updateHostUI(host) {
    const customContainer = document.getElementById('customWorkerContainer');
    const statusBadge = document.getElementById('hostStatusBadge');
    const config = IMAGE_HOST_CONFIGS[host] || IMAGE_HOST_CONFIGS.auto;

    if (host === 'custom') {
        customContainer.classList.remove('hidden');
    } else {
        customContainer.classList.add('hidden');
    }

    if (statusBadge) {
        statusBadge.textContent = config.badgeText;
        statusBadge.className = `text-xs px-2.5 py-0.5 rounded-full border font-medium ${config.badgeClass}`;
    }
}

// 上传适配器：皮卡图床 (PicUI)
async function uploadToPicUI(file, signal) {
    const formData = new FormData();
    formData.append("file", file, file.name || "image.png");
    const res = await fetch("https://picui.cn/api/v1/upload", {
        method: "POST",
        body: formData,
        signal
    });
    if (!res.ok) {
        throw new Error(`HTTP 状态码 ${res.status}`);
    }
    const json = await res.json();
    if (!json.status || !json.data?.links?.url) {
        throw new Error(json.message || "上传未返回有效图片直链");
    }
    return json.data.links.url;
}

// 上传适配器：图麦云图床 (tu.my)
async function uploadToTuMy(file, signal) {
    const formData = new FormData();
    formData.append("file", file, file.name || "image.png");
    const res = await fetch("https://tu.my/api/v1/upload", {
        method: "POST",
        body: formData,
        signal
    });
    if (!res.ok) {
        throw new Error(`HTTP 状态码 ${res.status}`);
    }
    const json = await res.json();
    if (!json.status || !json.data?.links?.url) {
        throw new Error(json.message || "上传未返回有效图片直链");
    }
    return json.data.links.url;
}

// 上传适配器：SXCU
async function uploadToSxcu(file, signal) {
    const formData = new FormData();
    formData.append("file", file, file.name || "image.png");
    const res = await fetch("https://sxcu.net/api/files/create", {
        method: "POST",
        body: formData,
        signal
    });
    if (!res.ok) {
        throw new Error(`HTTP 状态码 ${res.status}`);
    }
    const json = await res.json();
    if (!json.id) {
        throw new Error("未获取到图片 ID");
    }
    const match = (file.name || "").match(/\.([a-zA-Z0-9]+)$/);
    const ext = match ? match[1] : "png";
    return `https://sxcu.net/${json.id}.${ext}`;
}

// 上传适配器：Imgur
async function uploadToImgur(file, signal) {
    const formData = new FormData();
    formData.append("image", file, file.name || "image.png");
    const res = await fetch("https://api.imgur.com/3/image", {
        method: "POST",
        headers: {
            "Authorization": "Client-ID 546c25a59c58ad7"
        },
        body: formData,
        signal
    });
    if (!res.ok) {
        throw new Error(`HTTP 状态码 ${res.status}`);
    }
    const json = await res.json();
    if (!json.success || !json.data?.link) {
        throw new Error(json.data?.error || "Imgur 上传失败");
    }
    return json.data.link;
}

// 上传适配器：自定义 Worker / 自建图床
async function uploadToCustomWorker(file, signal) {
    let workerUrl = document.getElementById("workerUrlInput").value.trim();
    if (!workerUrl) {
        throw new Error("请先填写自定义 Worker 地址");
    }
    if (!workerUrl.match(/^https?:\/\//i)) {
        throw new Error("图床地址格式不正确，请确保以 http:// 或 https:// 开头");
    }
    workerUrl = workerUrl.replace(/\/+$/, "");

    const randomKey = generateRandomKey();
    const timestamp = Date.now();
    const key = `${randomKey}${timestamp}`;
    const uploadUrl = `${workerUrl}/upload/${key}`;

    const formData = new FormData();
    formData.append("file", file, file.name || "image.png");

    // 1. 尝试 CF Worker 格式: POST /upload/:key -> GET /download/:key
    try {
        const res = await fetch(uploadUrl, {
            method: "POST",
            body: formData,
            signal
        });
        if (res.ok) {
            return `${workerUrl}/download/${key}`;
        }
    } catch (e) {
        // 忽略并继续备用匹配
    }

    // 2. 尝试通用 Telegraph-Image / Lsky 格式: POST /upload
    try {
        const altUrl = workerUrl.endsWith("/upload") ? workerUrl : `${workerUrl}/upload`;
        const res2 = await fetch(altUrl, {
            method: "POST",
            body: formData,
            signal
        });
        if (res2.ok) {
            const data = await res2.json();
            if (Array.isArray(data) && data[0]?.src) {
                return `${workerUrl}${data[0].src}`;
            }
            if (data.data?.links?.url) {
                return data.data.links.url;
            }
            if (data.url) return data.url;
            if (data.link) return data.link;
        }
    } catch (e) {
        // 忽略
    }

    throw new Error("自定义 Worker 未响应有效图片直链，请检查服务可用性及 CORS 跨域配置");
}

// 智能多源自动故障转移逻辑
async function uploadWithAutoFallback(file, onProgress) {
    const sequence = [
        { key: 'picui', name: '皮卡图床' },
        { key: 'tumy', name: '图麦云图床' },
        { key: 'sxcu', name: 'SXCU 图床' },
        { key: 'imgur', name: 'Imgur 全球图库' }
    ];
    const errors = [];

    for (let i = 0; i < sequence.length; i++) {
        const item = sequence[i];
        if (onProgress) {
            onProgress(`正在上传至 [${item.name}] (${i + 1}/${sequence.length})...`);
        }
        try {
            const controller = new AbortController();
            const timer = setTimeout(() => controller.abort(), 9000);
            const config = IMAGE_HOST_CONFIGS[item.key];
            const url = await config.upload(file, controller.signal);
            clearTimeout(timer);
            return { url, hostName: item.name, key: item.key };
        } catch (err) {
            console.warn(`图床 [${item.name}] 上传失败:`, err.message);
            errors.push(`${item.name}: ${err.message}`);
        }
    }

    throw new Error(`所有可用图床均尝试失败：\n${errors.join('；')}`);
}

// 统一图片上传总入口
async function uploadImage(input) {
    const file = (input && input.files) ? input.files[0] : input;
    if (!file) return;

    // 先显示本地预览
    const localPreviewUrl = URL.createObjectURL(file);
    displayImagePreview(localPreviewUrl);

    const select = document.getElementById("imageHostSelect");
    const selectedHost = select ? select.value : 'auto';

    // 显示上传中提示
    const previewContainer = document.getElementById("uploadPreviewContainer");
    previewContainer.innerHTML = `
        <div class="flex flex-col items-center justify-center">
            <svg class="animate-spin h-10 w-10 text-primary-500 mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <p id="uploadStatusText" class="text-sm font-medium text-primary-600">正在上传图片...</p>
        </div>
    `;

    const updateStatus = (text) => {
        const el = document.getElementById("uploadStatusText");
        if (el) el.textContent = text;
    };

    let finalUrl = '';
    let usedHostName = '';

    try {
        if (selectedHost === 'auto') {
            const result = await uploadWithAutoFallback(file, updateStatus);
            finalUrl = result.url;
            usedHostName = result.hostName;
        } else {
            const config = IMAGE_HOST_CONFIGS[selectedHost];
            if (!config || !config.upload) {
                throw new Error(`未知图床类型: ${selectedHost}`);
            }
            updateStatus(`正在上传至 [${config.name}]...`);

            try {
                const controller = new AbortController();
                const timer = setTimeout(() => controller.abort(), 12000);
                finalUrl = await config.upload(file, controller.signal);
                clearTimeout(timer);
                usedHostName = config.name;
            } catch (singleErr) {
                console.warn(`所选图床 [${config.name}] 失败，尝试自动容灾备用源:`, singleErr);
                updateStatus(`[${config.name}] 异常，正在自动换源重试...`);
                const fallbackResult = await uploadWithAutoFallback(file, updateStatus);
                finalUrl = fallbackResult.url;
                usedHostName = `${fallbackResult.hostName} (自动换源)`;
            }
        }

        // 填入结果 URL
        document.getElementById("imageUrlInput").value = finalUrl;
        generateButtons();

        // 显示上传成功后的图片预览
        displayImagePreview(finalUrl);
        showNotification(`图片上传成功！(${usedHostName})`, "success");

        // 释放本地临时预览 URL
        URL.revokeObjectURL(localPreviewUrl);
    } catch (err) {
        // 恢复本地预览并提示错误
        displayImagePreview(localPreviewUrl);
        showNotification("图片上传失败: " + err.message, "error");
    } finally {
        // 清空 input 使得重复选择相同文件也能触发 onchange
        const fileInput = document.getElementById('fileInput');
        if (fileInput) fileInput.value = '';
    }
}

function generateRandomKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    let result = '';
    for (let i = 0; i < 5; i++) {
        result += chars[Math.floor(Math.random() * chars.length)];
    }
    return result;
}

function showNotification(message, type = 'info') {
    // 创建通知元素
    const notification = document.createElement('div');
    notification.className = `fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg text-white transition-all duration-500 transform translate-y-0 opacity-0 flex items-center`;

    // 根据类型设置背景色
    if (type === 'success') {
        notification.classList.add('bg-green-500');
    } else if (type === 'error') {
        notification.classList.add('bg-red-500');
    } else {
        notification.classList.add('bg-blue-500');
    }

    // 设置图标
    let icon = '';
    if (type === 'success') {
        icon = '<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>';
    } else if (type === 'error') {
        icon = '<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>';
    } else {
        icon = '<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>';
    }

    notification.innerHTML = `${icon}<span>${message}</span>`;
    document.body.appendChild(notification);

    // 显示通知
    setTimeout(() => {
        notification.classList.remove('opacity-0');
        notification.classList.add('opacity-100');
    }, 10);

    // 3秒后隐藏通知
    setTimeout(() => {
        notification.classList.remove('opacity-100');
        notification.classList.add('opacity-0');
        notification.classList.add('translate-y-2');

        // 动画完成后移除元素
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 500);
    }, 3000);
}

// 处理拖放上传功能
function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    // 添加拖放悬停效果
    e.currentTarget.classList.add('border-primary-500', 'bg-primary-50');
}

function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    // 移除拖放悬停效果
    e.currentTarget.classList.remove('border-primary-500', 'bg-primary-50');
}

function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    // 移除拖放悬停效果
    e.currentTarget.classList.remove('border-primary-500', 'bg-primary-50');

    // 获取拖放的文件
    const dt = e.dataTransfer;
    const files = dt.files;

    if (files.length > 0) {
        // 使用现有的uploadImage函数处理文件
        const fileInput = document.getElementById('fileInput');
        fileInput.files = files;
        uploadImage(fileInput);
    }
}

// 处理粘贴事件，支持直接粘贴图片到输入框
async function handlePaste(e) {
    // 如果粘贴事件包含剪贴板数据且有文件
    if (e.clipboardData && e.clipboardData.files && e.clipboardData.files.length > 0) {
        e.preventDefault(); // 阻止默认粘贴行为

        const file = e.clipboardData.files[0];
        // 检查是否为图片文件
        if (file.type.startsWith('image/')) {
            // 先显示本地预览
            const localPreviewUrl = URL.createObjectURL(file);
            displayImagePreview(localPreviewUrl);

            showNotification("正在上传粘贴的图片...", "info");

            // 使用现有的上传函数处理图片
            const fileInput = document.getElementById('fileInput');
            // 创建新的 FileList 对象（通过 DataTransfer）
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);
            fileInput.files = dataTransfer.files;

            // 上传图片
            uploadImage(fileInput);
        }
    }
}

// 检查URL是否为图片并显示预览
function checkAndPreviewImageUrl(url) {
    if (!url || !url.match(/^https?:\/\//i)) return;

    // 检查URL是否为图片
    const img = new Image();
    img.onload = function() {
        // 如果加载成功，说明是有效的图片URL
        displayImagePreview(url);
    };
    img.onerror = function() {
        // 如果加载失败，重置预览
        resetImagePreview();
    };
    img.src = url;
}

// 页面加载完成后，检查URL参数并初始化搜索引擎按钮
document.addEventListener('DOMContentLoaded', () => {
    // 初始化图床设置（恢复上次选择的图床及自定义配置）
    initImageHostSettings();

    const urlParams = new URLSearchParams(window.location.search);
    let imageUrl = urlParams.get('url');
    if (imageUrl) {
        // 去除前导空格
        imageUrl = imageUrl.trim();
        document.getElementById("imageUrlInput").value = imageUrl;

        // 检查是否为图片URL并显示预览
        checkAndPreviewImageUrl(imageUrl);
    }

    // 初始化搜索引擎按钮
    generateButtons();

    // 添加输入框事件监听器，当URL变化时自动更新按钮和预览图片
    const imageUrlInput = document.getElementById("imageUrlInput");
    imageUrlInput.addEventListener('input', function() {
        const url = this.value.trim();
        generateButtons();

        // 检查是否为图片URL并显示预览
        if (url) {
            checkAndPreviewImageUrl(url);
        } else {
            resetImagePreview();
        }
    });

    // 添加粘贴事件监听器，支持直接粘贴图片
    imageUrlInput.addEventListener('paste', handlePaste);

    // 添加拖放事件监听器
    const dropZone = document.querySelector('label[for="fileInput"]');
    dropZone.addEventListener('dragover', handleDragOver);
    dropZone.addEventListener('dragleave', handleDragLeave);
    dropZone.addEventListener('drop', handleDrop);
});
