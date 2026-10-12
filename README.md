# coder-workspace-images

用于 [Coder](https://coder.com/) 的个人 Workspace 镜像与 Terraform 模板。以 Ubuntu Dev Container 为基础，整理常用开发工具，并按语言拆分 .NET、Web、Rust、Go 和 Java 开发环境。

每个 `ubuntu-*` 目录同时包含镜像的 `Dockerfile` 和对应的 `main.tf`：前者定义容器内的工具链，后者负责在 Coder 中创建 Workspace、挂载用户目录并配置编辑器入口。

## 项目定位

这个仓库主要围绕我自己的开发习惯和使用需求维护，工具选择、版本策略和环境配置都带有个人偏好，并未以满足所有人的通用镜像需求为目标，因此部分细节可能不适合你的环境。

为了保持维护范围清晰，仓库不接受外部 Pull Request。不过，仍然欢迎使用这里的 Workspace 模板，也欢迎 Fork 后按自己的习惯调整，改造成适合自己的版本。

## 镜像与依赖关系

所有语言镜像都直接继承 `ubuntu-base`，彼此之间没有继承关系。

```text
mcr.microsoft.com/devcontainers/base:ubuntu
└── ubuntu-base
    ├── ubuntu-dotnet
    ├── ubuntu-web
    ├── ubuntu-rust
    ├── ubuntu-golang
    └── ubuntu-java
```

| 镜像 | 主要内容 |
| --- | --- |
| `ubuntu-base` | C/C++ 编译与调试工具、Git / Git LFS、网络诊断工具、Docker Engine / CLI、Buildx、Compose，以及个人 home 目录默认配置 |
| `ubuntu-dotnet` | .NET SDK 8.0 和 10.0，关闭 CLI 遥测 |
| `ubuntu-web` | Node.js LTS、Yarn、pnpm |
| `ubuntu-rust` | rustup、Rust 工具链、rust-analyzer |
| `ubuntu-golang` | 构建时从 Go 官方获取的最新版本，设置 `GOROOT` 和 `GOPATH` |
| `ubuntu-java` | 通过 SDKMAN 安装 Java、Maven、Gradle；支持用构建参数指定版本 |

语言镜像通过 `BASE` 构建参数选择基础镜像，默认值为 `ubuntu-base:latest`。发布工作流会将它替换为 GHCR 上的基础镜像 digest。

部分上游镜像和工具链使用滚动版本，因此重新构建时内容可能变化。当前 Go 安装脚本明确使用 `linux-amd64` 下载包，工作流也没有配置多架构构建；使用 ARM 等环境前，需要自行调整并验证。

## 仓库结构

```text
.
├── ubuntu-base/
│   ├── Dockerfile          # 公共工具和基础环境
│   ├── entrypoint.sh       # 首次启动时初始化 home 目录
│   ├── skel/               # 随镜像提供的个人默认配置
│   └── main.tf             # 基础 Workspace 模板
├── ubuntu-dotnet/          # .NET 镜像与模板
├── ubuntu-web/             # Web 镜像与模板
├── ubuntu-rust/            # Rust 镜像与模板
├── ubuntu-golang/          # Go 镜像与模板
├── ubuntu-java/            # Java 镜像与模板
├── coder-template/
│   └── main.tf             # 直接使用上游 Dev Container 镜像的独立模板
├── .github/workflows/
│   ├── build-test.yml      # PR 镜像构建与 Terraform 模板检查
│   └── publish.yml         # 镜像及 Coder 模板发布
└── LICENSE
```

`coder-template/main.tf` 与六个 `ubuntu-*` 模板是独立文件，不会被自动合并到其他模板中，也不在当前自动发布列表内。它直接使用上游镜像，home 初始化方式也与 `ubuntu-*` 模板不同。使用本仓库定制镜像时，请从对应的 `ubuntu-*` 目录开始。

## 使用镜像

### 拉取已发布镜像

镜像发布到 `ghcr.io/lamgc/coder-workspace-images`，以标签区分环境：

- `<镜像名>-latest`：该环境最近一次发布的镜像
- `<镜像名>-<YYYYMMDDHHMMSS>`：使用 UTC 发布时间生成的标签

例如，拉取并进入 Web 开发环境：

```sh
docker pull ghcr.io/lamgc/coder-workspace-images:ubuntu-web-latest
docker run --rm -it ghcr.io/lamgc/coder-workspace-images:ubuntu-web-latest bash
```

这只是临时容器，不会创建 Coder Workspace；退出后容器内未挂载的改动会丢失。长期使用请配置持久化存储，或使用下文的 Coder 模板。

### 本地构建

在仓库根目录执行。以下命令使用 Docker 的 `default` builder，让语言镜像能够读取本地构建的基础镜像：

```sh
git clone https://github.com/LamGC/coder-workspace-images.git
cd coder-workspace-images

docker build --builder default -t ubuntu-base:latest ./ubuntu-base
docker build --builder default \
  --build-arg BASE=ubuntu-base:latest \
  -t ubuntu-web:local ./ubuntu-web
```

将 `ubuntu-web` 换成所需语言目录即可。若使用独立的 `docker-container` Buildx builder，应先将基础镜像推送到该 builder 可访问的镜像仓库，再通过 `BASE` 传入镜像引用；它不能直接读取 Docker 的本地镜像存储。

Java 镜像还提供 `JAVA_VERSION`、`MAVEN_VERSION` 和 `GRADLE_VERSION` 构建参数。留空时由 SDKMAN 选择默认版本；需要固定版本时，传入 SDKMAN 支持的版本标识。

## 在 Coder 中使用

### 准备环境

- 一个可用的 Coder 实例，以及有权限发布模板的 Coder CLI 登录会话
- Coder provisioner 可访问的 Docker daemon，以及能访问镜像仓库的网络
- 本地可用的 Docker Buildx 和 Terraform，用于查询 digest、初始化和检查模板

六个 `ubuntu-*` 模板均使用以下变量：

| 变量 | 说明 |
| --- | --- |
| `workspace_image` | 必填。完整镜像引用必须以 `@sha256:<64 位十六进制摘要>` 结尾，不能只传 `latest` 或时间戳标签 |
| `docker_socket` | 可选。Docker socket URI；留空时使用 Docker provider 的默认连接方式 |

### 发布一个模板

下面以 Web 模板为例，在仓库根目录执行。先确认已登录自己的 Coder 实例，并确认将要使用的模板配置；命令会向该实例上传模板版本。

```sh
IMAGE='ghcr.io/lamgc/coder-workspace-images:ubuntu-web-latest'
DIGEST=$(docker buildx imagetools inspect "$IMAGE" --format '{{json .Manifest.Digest}}' | tr -d '"')

# 验证查询结果，避免上传空值或无效镜像引用。
printf '%s\n' "$DIGEST" | grep -Eq '^sha256:[0-9a-f]{64}$' || exit 1

# 仅打包 Terraform 文件，不上传 Dockerfile 等镜像构建上下文。
BUNDLE_DIR=$(mktemp -d)
cp ubuntu-web/*.tf "$BUNDLE_DIR/"
terraform -chdir="$BUNDLE_DIR" init -backend=false
terraform -chdir="$BUNDLE_DIR" validate

coder templates push ubuntu-web \
  --directory "$BUNDLE_DIR" \
  --variable "workspace_image=${IMAGE}@${DIGEST}"
```

需要连接非默认 Docker daemon 时，可再传入 `--variable "docker_socket=你的 Docker socket URI"`。完成后，在 Coder 中使用该模板创建 Workspace。镜像 digest 固定在模板版本中，上游 `latest` 更新不会自动替换现有模板引用；需要重新发布模板版本，并更新相应 Workspace。

### 默认行为与需要留意的配置

- 容器以 `vscode` 用户运行，home 路径为 `/home/vscode`；模板为其创建独立 Docker volume。
- `entrypoint.sh` 在首次启动时，将 `/etc/workspace-skel` 和 `/etc/skel` 中缺失的文件复制到 home，不覆盖已有文件，并写入 `~/.workspace_initialized` 标记。已有标记的 home 不会因镜像更新自动重新初始化。
- 模板配置了 VS Code Web、简体中文语言包和 JetBrains 入口，语言模板另带相关 VS Code 扩展。VS Code Web 的安装由 Coder 模块处理，并非预装在镜像内。
- 模板将 Coder 用户资料中的姓名、邮箱注入 Git 作者和提交者环境变量；不需要时可自行调整 `coder_agent` 的 `env`。
- 模板中的 VS Code Web 模块设置了 `accept_license = true`。使用前请检查相关许可及模块配置是否符合自己的需求。
- 镜像安装 Docker 工具不代表 Workspace 已接通可用的 Docker daemon。当前模板没有挂载宿主机 Docker socket，也没有配置特权容器或启动 DinD；需要在 Workspace 内运行 Docker 时，应自行选择并配置连接方式，同时评估权限风险。

## 自动构建与发布

[Build Test](.github/workflows/build-test.yml) 在面向 `main` 的 PR 上运行：根据目录变化选择构建镜像；基础镜像变化时构建全部语言镜像；同时对六个 `ubuntu-*` 模板执行 Terraform 格式检查、初始化和验证。测试构建不发布镜像。

[Publish Images](.github/workflows/publish.yml) 在推送到 `main`、手动触发，以及每周日 02:00 UTC 时运行：

1. 推送触发时按变更目录选择构建范围；基础镜像或发布工作流变化时完整发布。
2. 手动和定时运行会刷新全部镜像及模板，并禁用构建步骤缓存。
3. 需要时先发布基础镜像；语言镜像始终按基础镜像 digest 构建。
4. 所需镜像成功发布后，以对应镜像 digest 发布 Coder 模板版本。

如果 Fork 后要使用自己的发布流程，需要调整 `publish.yml` 中的 `REPOSITORY_OWNER` / `IMAGE_NAME`，并配置自己实例的 `CODER_URL`、`CODER_CLI_TOKEN` 仓库 Secrets 及 GHCR 所需权限。仅使用模板或本地构建，不需要启用这套自动发布流程。

## 许可证

仓库使用 [Apache License 2.0](LICENSE)。镜像内包含的第三方软件仍适用各自的许可证。
