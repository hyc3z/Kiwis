import datetime
import os
import sys
import traceback
PRINT_LEVEL_REF = {
        'info': 0,
        'warning': 1,
        'error': 2,
        'emergecy': 4,
    }
LOG_LEVEL_REF = {
        'info': 0,
        'warning': 1,
        'error': 2,
        'emergecy': 4,
    }

def global_hook (ttype,tvalue,ttraceback):
    err_str = ""
    err_str += "例外类型：{}\n".format(ttype)
    err_str += "例外对象：{}\n".format(tvalue)
    i = 1
    while ttraceback:
        err_str += "第{}层堆栈信息\n".format(i)
        tracebackCode = ttraceback.tb_frame.f_code
        err_str += "文件名：{}\n".format(tracebackCode.co_filename)
        err_str += "行号：{}\n".format(ttraceback.tb_lineno)
        err_str += "函数或者模块名：{}\n".format(tracebackCode.co_name)
        ttraceback = ttraceback.tb_next
        i += 1
    SystemLogger.log_error(err_str)


class SystemLogger:

    print_level = 1
    log_level = 0
    @classmethod
    def getFileObj(cls):
        date = cls.getDate()
        pathname = "log/{}/system/system_log_{}.txt".format(date, date)
        # exist = os.path.exists(pathname)
        try:
            f = open(pathname, mode='ab+', buffering=0)
        except FileNotFoundError:
            os.makedirs("log/{}/system".format(date))
            f = open(pathname, mode='ab+', buffering=0)
        return f

    @staticmethod
    def getTimeStamp():
        now = datetime.datetime.now()
        date = now.date()
        timeobj = now.time()
        timestr = "{0:02d}{1:02d}{2:02d}".format(timeobj.hour, timeobj.minute, timeobj.second)
        return "{}{}{}".format(date, "-", timestr)

    @staticmethod
    def getDate():
        now = datetime.datetime.now()
        date = now.date()
        return "{}".format(date)

    @classmethod
    def processArgs(cls, args, sep:str=' '):
        retList = []
        for i in args:
            retList.append(str(i))
        return sep.join(retList)

    @classmethod
    def log(cls, *args):
        logstr = cls.processArgs(args)
        f = cls.getFileObj()
        f.write(logstr.encode('utf-8') + b"\n")

    @classmethod
    def format_info(cls, *args):
        logstr = cls.processArgs(args)
        logstr = "[ii INFO {}] {}".format(cls.getTimeStamp(), logstr)
        return logstr

    @classmethod
    def format_error(cls, *args):
        logstr = cls.processArgs(args)
        logstr = "[!! ERROR {}] {}".format(cls.getTimeStamp(), logstr)
        return logstr

    @classmethod
    def format_warning(cls, *args):
        logstr = cls.processArgs(args)
        logstr = "[WW WARNING {}] {}".format(cls.getTimeStamp(), logstr)
        return logstr

    @classmethod
    def log_info(cls, *args):
        info_str = cls.format_info(*args)
        if cls.log_level <= LOG_LEVEL_REF['info']:
            cls.log(info_str)
        if cls.print_level <= PRINT_LEVEL_REF['info']:
            print(info_str)

    @classmethod
    def log_warning(cls, *args):
        warn_str = cls.format_warning(*args)
        if cls.log_level <= LOG_LEVEL_REF['warning']:
            cls.log(warn_str)
        if cls.print_level <= PRINT_LEVEL_REF['warning']:
            print(warn_str)

    @classmethod
    def log_error(cls, *args):
        error_str = cls.format_error(*args)
        trace = traceback.format_exc()
        error_str += "\n{}".format(trace)
        if cls.log_level <= LOG_LEVEL_REF['error']:
            cls.log(error_str)
        if cls.print_level <= PRINT_LEVEL_REF['error']:
            print(error_str)

    @classmethod
    def set_print_level(cls, level_str):
        try:
            cls.print_level = PRINT_LEVEL_REF[level_str]
        except Exception as e:
            print('Set print level failed.{}'.format(e))

    @classmethod
    def set_log_level(cls, level_str):
        try:
            cls.log_level = LOG_LEVEL_REF[level_str]
        except Exception as e:
            print('Set log level failed.{}'.format(e))

    @classmethod
    def numerator(cls, number):
        return "1st" if number == 1 else ("2nd" if number == 2 else ("3rd" if number == 3 else "{}th".format(number)))

    @staticmethod
    def send_log():
        pass


class CameraLogger(SystemLogger):
    @classmethod
    def getFileObj(cls):
        date = cls.getDate()
        pathname = "log/{}/camera/camera_log_{}.txt".format(date,date)
        # exist = os.path.exists(pathname)
        try:
            f = open(pathname, mode='ab+', buffering=0)
        except FileNotFoundError:
            os.makedirs("log/{}/camera".format(date))
            f = open(pathname, mode='ab+', buffering=0)
        return f

class DatabaseLogger(SystemLogger):
    @classmethod
    def getFileObj(cls):
        date = cls.getDate()
        pathname = "log/{}/database/database_log_{}.txt".format(date, date)
        # exist = os.path.exists(pathname)
        try:
            f = open(pathname, mode='ab+', buffering=0)
        except FileNotFoundError:
            os.makedirs("log/{}/database".format(date))
            f = open(pathname, mode='ab+', buffering=0)
        return f

if __name__ == '__main__':
    SystemLogger.log_error("2","3"+"4")