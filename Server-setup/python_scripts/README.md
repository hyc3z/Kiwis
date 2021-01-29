自动clone github上所有仓库
首先安装好相应的python 库
`pip3 install -r requirements.txt`

然后在github中右上角头像-> Settings -> Developer settings -> Personal access tokens
创建好token（至少要有读权限）
复制token

打开github-config.json
把token粘贴进去，用户名改成自己的id
prefix 改成本地的接受目录

运行clone_repo.py 开始
