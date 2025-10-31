# NGINX Cross‑Platform Build + Release CI

这个仓库包含 GitHub Actions workflow 和构建脚本，用于：

- 在 Linux、macOS 和 Windows runner 上编译指定版本的 NGINX
- 将每个平台的构建产物打包并上传为 GitHub Release 的附件
- 手动触发（workflow_dispatch），可以在触发时指定 `nginx_version`

使用方法（手动触发）：
1. 在仓库页面点击 "Actions" -> 选择 `Build and release NGINX` workflow -> `Run workflow`。
2. 在输入项中填写 `nginx_version`（例如 `1.26.4`），然后运行。
3. 等待 workflow 完成，Release 将被创建并包含三个平台的打包文件。

注意与限制：
- Linux/macOS：脚本会下载 NGINX 源码并尝试自动构建常见依赖（zlib/pcre/openssl）。如果需要特殊模块或静态/共享链接方式，请修改 `scripts/build-nginx-unix.sh`。
- Windows：Windows 上原生构建 NGINX 复杂度较高。脚本尝试使用 msbuild / vswhere 提供的工具链进行构建，但你可能需要在 runner 上提供或交叉编译 OpenSSL/zlib/pcre 的 Windows 版本，或改为采用预编译依赖。
- 如果构建出现依赖错误，请查看 Actions 日志并根据错误在脚本中添加或调整依赖安装步骤。
- Release 创建使用 GITHUB_TOKEN（Actions 默认提供），如果你要发布到另一个仓库或使用自定义 token，请在 workflow 中替换或设置 secrets。

文件列表与说明：
- .github/workflows/build-and-release.yml：主 workflow，定义触发、各平台构建 job、以及打包并发布到 Release 的 job。
- scripts/download-nginx.sh：下载并校验指定版本 NGINX 源码。
- scripts/build-nginx-unix.sh：在 Linux/macOS 上构建 NGINX 的脚本（支持常见依赖）。
- scripts/build-nginx-windows.ps1：在 windows-latest runner 上构建（示例，可能需要根据依赖调整）。
- scripts/package.sh：统一打包脚本（由各平台的构建脚本调用）。

欢迎先按示例试跑一次 workflow，然后把 Actions 的构建日志贴给我，我可以根据具体错误帮助你修复 Windows 或某个平台的依赖与构建命令。
