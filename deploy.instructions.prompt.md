GitHub Pages 发布 Workflow（模板）

目标：以最少依赖将纯静态站点发布到 GitHub Pages。所有具体值以占位符表示，请用你的实际值替换形如 `{ PLACEHOLDER }` 的文本。

—

发布步骤（原子化）
- 启用：在仓库 `{ OWNER }/{ REPO }` 的 Settings → Pages，将 Source 设为 `{ PAGES_SOURCE }`（推荐：`GitHub Actions`）。
- 创建：新建目录 `.github/workflows/`（若已存在则跳过）。
- 新建：在 `.github/workflows/{ WORKFLOW_FILE }` 写入下述工作流模板（文件名示例：`pages.yml`）。

```yaml
name: { WORKFLOW_NAME }

on:
  push:
    branches: ["{ DEFAULT_BRANCH }"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v5
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '{ ARTIFACT_PATH }'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- 准备：将站点入口与静态资源放在仓库根目录（或 `{ ARTIFACT_PATH }`）中，如 `index.html`、`{ STATIC_ASSETS }`、`{ DOWNLOAD_SAMPLES }` 等。
- 添加：在仓库根目录创建空文件 `.nojekyll`（禁用 Jekyll 以避免忽略以 `_` 开头的路径）。
- 配置：在仓库根目录创建 `.artifactignore`，用于排除不需要发布的内容：

```text
.git/
.github/
{ ARTIFACT_EXCLUDES }
```

- 提交：把上述新增文件加入版本控制并提交到 `{ DEFAULT_BRANCH }`。

```bash
git add .nojekyll .artifactignore .github/workflows/{ WORKFLOW_FILE } { STATIC_ASSETS } { DOWNLOAD_SAMPLES } index.html
git commit -m "chore: setup GitHub Pages workflow"
git push origin { DEFAULT_BRANCH }
```

- 切换：在 GitHub 仓库 `{ OWNER }/{ REPO }` 的 Settings → Pages → Build and deployment，将 Source 修改为 `GitHub Actions`（若已为 `GitHub Actions` 则跳过）。
- 等待：完成上述设置后再继续下一步，以便工作流能够正确部署到 Pages。

- 触发：在推送后自动触发工作流（或在 Actions 手动 `Run workflow`）。
- 观察：在 Actions 的 `{ WORKFLOW_NAME }` 运行页面等待 `deploy` 任务完成，记录输出的 `page_url`。
- 验证：在浏览器访问 `{ SITE_URL }` 或工作流输出的 `page_url`，检查页面是否能正常加载与交互。
- 固化：如需自定义域名，在仓库根目录创建 `CNAME`，文件内容为 `{ CUSTOM_DOMAIN }`，提交并推送；在 DNS 供应商配置 CNAME 记录至 `{ USERNAME }.github.io`。
- 维护：后续对 `{ DEFAULT_BRANCH }` 的提交将自动重新部署，无需额外操作。

—

可选扩展
- 精简：在 `.artifactignore` 增加更多排除规则（如 `**/*.test.*`、`scripts/**`、`{ EXTRA_EXCLUDES }`）以减小工件体积。
- 分支：若希望使用独立分支承载产物，将 `{ ARTIFACT_PATH }` 指向构建输出目录并保持 `actions/deploy-pages@v4`；无需手动推送到 `gh-pages` 分支。
- 缓存：若存在构建（本模板假设纯静态无需构建），可加入 `actions/cache@v4` 以加速依赖安装与打包步骤。

—

术语表（占位符与资源解释）
- `{ OWNER }`：GitHub 组织或用户名（例如 `USERNAME`）。
- `{ REPO }`：仓库名（例如 `MY_SITE`）。
- `{ USERNAME }`：你的 GitHub 用户名（用于自定义域说明）。
- `{ PAGES_SOURCE }`：Pages 部署来源（推荐值：`GitHub Actions`）。
- `{ WORKFLOW_FILE }`：工作流文件名（例如 `pages.yml`）。
- `{ WORKFLOW_NAME }`：工作流名称（例如 `Deploy static content to Pages`）。
- `{ DEFAULT_BRANCH }`：默认发布分支（例如 `main` 或 `master`）。
- `{ ARTIFACT_PATH }`：上传至 Pages 的目录路径（纯静态站点通常为 `.`）。
- `{ ARTIFACT_EXCLUDES }`：需要从发布工件中排除的额外路径或通配模式（按需填写）。
- `{ STATIC_ASSETS }`：静态资源目录占位（例如 `assets/`、`images/`、`css/`、`js/`）。
- `{ DOWNLOAD_SAMPLES }`：示例或下载文件占位（例如 `docs/`、`samples/`、`*.md`、`*.yaml`）。
- `{ SITE_URL }`：站点访问地址（典型为 `https://{ OWNER }.github.io/{ REPO }/`）。
- `{ CUSTOM_DOMAIN }`：自定义域名（例如 `www.example.com`）。
- `.nojekyll`：禁用 Jekyll 处理，确保所有静态文件被原样服务。
- `.artifactignore`：`actions/upload-pages-artifact` 的工件忽略清单，用于排除不需要发布的文件夹与文件。
- `.github/workflows/{ WORKFLOW_FILE }`：GitHub Actions 工作流定义文件，负责打包与部署站点到 Pages。
- `index.html`：站点入口文件；纯前端单页应用通常只需该文件及配套静态资源即可发布。
