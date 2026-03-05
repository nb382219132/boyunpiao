# 开发指南

## 本地免登录调试

为了简化本地开发流程，项目支持免登录调试模式。

### 方式一：使用 .env.local（推荐）

项目已配置 `.env.local` 文件，默认启用免登录模式：

```bash
# 文件内容
VITE_SKIP_AUTH=true
```

直接运行开发服务器即可：
```bash
npm run dev
```

### 方式二：使用命令行参数

```bash
# Windows
npm run dev:local

# 或者手动设置环境变量
set VITE_SKIP_AUTH=true
npm run dev
```

### 免登录模式效果

- 自动以 `开发者` 身份登录
- 拥有 `admin` 权限
- 跳过所有认证检查
- 直接进入主界面

### 恢复登录模式

修改 `.env.local`：
```bash
VITE_SKIP_AUTH=false
```

或者删除 `.env.local` 文件。

## 自动推送到 GitHub

### 工作流程

1. **本地开发**：在本地修改代码，使用免登录模式测试
2. **推送开发分支**：将修改推送到 `develop`、`dev`、`feature/*` 或 `bugfix/*` 分支
3. **自动合并**：GitHub Actions 会自动将修改合并到 `main` 分支
4. **自动部署**：合并到 `main` 后自动部署到 GitHub Pages

### 使用示例

```bash
# 1. 创建并切换到功能分支
git checkout -b feature/ui-update

# 2. 修改代码并提交
git add .
git commit -m "更新UI布局"

# 3. 推送到远程
git push origin feature/ui-update

# 4. GitHub Actions 会自动合并到 main 并部署
```

### 支持的分支

- `develop` - 开发分支
- `dev` - 简写开发分支
- `feature/*` - 功能分支（如 `feature/new-button`）
- `bugfix/*` - 修复分支（如 `bugfix/login-error`）

### 注意事项

- `feature/*` 和 `bugfix/*` 分支在合并后会被自动删除
- `develop` 和 `dev` 分支会保留
- 直接推送到 `main` 分支也会触发部署

## 环境变量说明

| 变量名 | 说明 | 开发环境 | 生产环境 |
|--------|------|----------|----------|
| `VITE_SKIP_AUTH` | 跳过认证 | `true` | `false` |
| `VITE_SUPABASE_URL` | Supabase URL | 可选 | 必需 |
| `VITE_SUPABASE_ANON_KEY` | Supabase Key | 可选 | 必需 |
| `GEMINI_API_KEY` | Gemini API | 可选 | 可选 |

## 文件说明

- `.env.local` - 本地环境配置（已添加到 .gitignore，不会提交）
- `.env` - 生产环境配置（需要手动创建）
- `.github/workflows/deploy.yml` - 部署工作流
- `.github/workflows/auto-push.yml` - 自动推送工作流
