import json
import queue
import logging
import git
import requests
from github import Github
import threading
import os
from logger import *
# "system" for system git or "python" for pygit
GIT_METHOD = "system"

def get_logger():
    logger = logging.getLogger("threading")
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(os.path.join(os.path.split(os.path.realpath(__file__))[0],"system_log.txt"))
    fmt = '%(asctime)s - %(name)s - %(processName)s - %(threadName)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(fmt)
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    return logger

class MyRepo:

    def __init__(self, name, url):
        self.name = name
        self.url = url

class GithubUser:

    def __init__(self, username, token, prefix, thread_limit, fallback_prefix):
        self.token = token
        self.username = username
        self.repolist = []
        self.prefix = prefix
        self.fallback_prefix = fallback_prefix
        self.thread_limit = thread_limit
        self.logger = get_logger()

    def getRepoInfo(self):
        g = Github(self.token)
        try:
            temp_list = g.get_user().get_repos()
            for i in temp_list:
                self.repolist.append(i)
            with open(os.path.join(os.path.split(os.path.realpath(__file__))[0],"repolist.txt"), "w+",encoding="utf-8") as f:
                for i in self.repolist:
                    f.write("{} {}\n".format(i.name, i.url))
        except Exception as e:
            self.logger.info("Get git repo list failed. Try using local stored repo list.")
            with open(os.path.join(os.path.split(os.path.realpath(__file__))[0],"repolist.txt"), "r+",encoding="utf-8") as f:
                lines = f.readlines()
                self.logger.info(len(lines))
                for i in lines:
                    name = i.split(' ')[0]
                    url = i.split(' ')[1]
                    self.repolist.append(MyRepo(name, url))
        self.logger.info("Found {} repos.".format(len(self.repolist)))


    def cloneRepositories(self):
        Q = queue.Queue()
        threads_state = []
        self.logger.info("Started cloning repositories...")
        for repo in self.repolist:
            Q.put(repo)
        while Q.empty() is False:
            if threading.active_count() < self.thread_limit + 1:
                t = threading.Thread(target=self.cloneSingleRepository, args=(Q.get(), os.path.join(self.prefix, self.username),self.fallback_prefix),
                                     kwargs={"username": self.username, "token": self.token, "retry": True} )
                t.daemon = True
                t.start()
        for _ in threads_state:
            _.start()
            _.join()

    def cloneSingleRepository(self, repo, prefix, fallback_prefix, username, token, retry):
        cloningpath = os.path.join(prefix, repo.name)
        # with threading.Lock():
        #     self.logger.info(cloningpath)
        try:
            if not os.path.exists(prefix):
                os.mkdir(prefix)
        except Exception as e:
            self.logger.error("Error: There is an error in creating directories. {}".format(e))
            try:
                if not os.path.exists(fallback_prefix):
                    os.mkdir(fallback_prefix)
            except Exception as e:
                if not os.path.exists(prefix):
                    self.logger.error("Fatal: There is an error in creating directories. {} Aborting.".format(e))
                    return 1
        url_request = repo.url.replace("https://api.github.com/repos", "https://{}:{}@github.com/".format(username, token))
        # self.logger.info(url_request)
        if retry:
            try_count = 0
            try:
                try_count += 1
                if os.path.exists(cloningpath):
                    if not os.listdir(cloningpath):
                        self.logger.info("Start pulling {} for the {} time...".format(repo.name, SystemLogger.numerator(try_count)))
                        if GIT_METHOD == "python":
                            git.Repo(url_request).remote().pull()
                        else:
                            try:
                                if not os.path.exists(os.path.join(prefix, repo.name)):
                                    os.mkdir(os.path.join(prefix, repo.name))
                            except Exception as e:
                                pass
                            os.chdir((os.path.join(prefix, repo.name)))
                            os.system("git config pull.rebase true")
                            os.system("git pull --force {} ".format(url_request))
                        self.logger.info("Successfully pulled {} for the {} time.".format(repo.name, SystemLogger.numerator(try_count)))
                    else:
                        self.logger.info("Start updating {} for the {} time... ".format(repo.name, SystemLogger.numerator(try_count)))
                        if GIT_METHOD == "python":
                            git.Repo(cloningpath).remote().update()
                        else:
                            try:
                                if not os.path.exists(os.path.join(prefix, repo.name)):
                                    os.mkdir(os.path.join(prefix, repo.name))
                            except Exception as e:
                                pass
                            os.chdir((os.path.join(prefix, repo.name)))
                            os.system("git config pull.rebase true")
                            retval = os.system("git pull --force {}".format(url_request))
                            if retval != 0:
                                self.logger.error("Error updating {} for the {} time. Try simple pulling ".format(repo.name,
                                                                                         SystemLogger.numerator(
                                                                                             try_count)))
                                os.chdir((os.path.join(prefix, repo.name)))
                                os.system("git stash")
                                retval = os.system("git pull")
                                if retval != 0:
                                    self.logger.error("Error updating {} for the {} time.".format(repo.name, SystemLogger.numerator(try_count)))
                                    return 1
                            self.logger.info("Successfully updated {} for the {} time. ".format(repo.name, SystemLogger.numerator(try_count)))
                else:
                    if GIT_METHOD == "python":
                        git.Repo.clone_from(url_request, cloningpath)
                    else:
                        try:
                            if not os.path.exists(os.path.join(prefix)):
                                os.mkdir(os.path.join(prefix))
                        except Exception as e:
                            pass
                        os.chdir((os.path.join(prefix)))
                        os.system("git clone {}".format(url_request))
            except Exception as e:
                self.logger.error("Error cloning {}: {} retrying for the {} time...".format(repo.name, e, SystemLogger.numerator(try_count)))

class InfoLoader:

    def __init__(self):
        self.users = []
        self.logger = get_logger()

    def load_config(self, filepath=os.path.join(os.path.split(os.path.realpath(__file__))[0],"github-config.json")):
        self.logger.info("Loading config...")
        with open(filepath, 'r', encoding="utf-8") as cfg:
            cfg_data = json.load(cfg)
            users = cfg_data["users"]
            prefix = cfg_data["clone_config"]["prefix"]
            limit = cfg_data["clone_config"]["thread_limit"]
            fb_prefix = cfg_data["clone_config"]["fallback_prefix"]
            for user in users:
                user_data = users[user]
                self.users.append(GithubUser(user_data["username"], user_data["token"], prefix, limit, fb_prefix))

    def load_repos(self):
        self.logger.info("Loading repo...")
        for u in self.users:
            u.getRepoInfo()

    def start_cloning(self):
        for u in self.users:
            u.cloneRepositories()


def workflow():
    gc = InfoLoader()
    gc.load_config()
    gc.load_repos()
    gc.start_cloning()


if __name__ == '__main__':
    workflow()
