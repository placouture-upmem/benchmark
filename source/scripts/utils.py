import datetime
import inspect
import math
import os
import sqlite3
import subprocess

def printer(*args):

    callerframerecord = inspect.stack()[1]    # 0 represents this line
    # 1 represents line at caller
    frame = callerframerecord[0]
    info = inspect.getframeinfo(frame)
    # print(info)
    string_to_print = ("\n===")
    string_to_print += ("\n" + info.filename + ":" + str(info.lineno)
                        + ":" + info.function + "()\n")
    for a in args:
        string_to_print += (str(a) + " ")
    string_to_print += ("\n===")
    print(string_to_print)
    return


def type_printer(truc):
    print(type(truc))
    print(truc)
    return

def mhz(val):
    return int(val * 1e3)
def ghz(val):
    return int(val * 1e6)

def check_or_create():
    db_path = os.path.join(os.environ["LOGTRACE_DIR"], "data.db")
    db_connection = sqlite3.connect(db_path, check_same_thread=False)
    c = db_connection.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS entry(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, start INTEGER NOT NULL, end INTEGER NOT NULL, pid INTEGER NOT NULL, applications_return_code INTEGER NOT NULL )''')
    db_connection.commit()
    db_connection.close()
    return

def get_db_current_id():
    db_connection = sqlite3.connect(os.path.join(os.environ["LOGTRACE_DIR"],
                                                 "data.db"))
    db_connection.row_factory = sqlite3.Row
    db_cursor = db_connection.cursor()
    nr_record = db_cursor.execute("SELECT MAX(id) FROM entry").fetchone()[0]
    if not nr_record:
        nr_record = 1
    else:
        nr_record += 1

    return nr_record

def get_db_faults():
    db_connection = sqlite3.connect(os.path.join(os.environ["LOGTRACE_DIR"],
                                                 "data.db"))
    db_connection.row_factory = sqlite3.Row
    db_cursor = db_connection.cursor()
    records = db_cursor.execute("SELECT id FROM entry WHERE applications_return_code == 0 and thermal_manager_return_code == 0").fetchall()
    rec = []
    for record in records:
        rec.append(record["id"])
    return rec

def get_workload_path(workload):
    return os.path.join(os.environ["LOGTRACE_DIR"], str(workload.identifier).zfill(10))

def get_workload_path_file(workload, p_filename):
    path = os.path.join(os.environ["LOGTRACE_DIR"], str(workload.identifier).zfill(10), p_filename)
                        
    return path

def system_cmd(cmd):
    print(cmd)
    os.system(cmd)
    return
