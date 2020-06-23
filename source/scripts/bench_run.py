#!/usr/bin/python3

import argparse
import datetime
import os
import signal
import pickle
import time
import sqlite3
import subprocess
import shutil
import socket
import sys
from errno import ENETUNREACH

import config
import utils

PARSER = argparse.ArgumentParser(description="run.")

PARSER.add_mutually_exclusive_group(required=False)

PARSER.add_argument("--estimation", dest="estimation", action="store_true")
PARSER.set_defaults(estimation=False)

PARSER.add_argument("--resume", dest="resume", action="store_true")
PARSER.set_defaults(resume=False)

PARSER.add_argument("--show", dest="show", action="store_true")
PARSER.set_defaults(show=False)
PARSER.add_argument("--no-cool_down", dest="cool_down", action="store_false")
PARSER.set_defaults(cool_down=True)
PARSER.add_argument("--no-idle", dest="idle", action="store_false")
PARSER.set_defaults(idle=True)

PARSER.add_argument("--no-backup", dest="backup", action="store_false")
PARSER.set_defaults(backup=True)

ARGS = PARSER.parse_args()


control_thermal_chamber = False

from arch_specific_odroidxu3 import *
if (os.environ["HOSTNAME"] in ["odroid-xu3-0",
                               "odroid-xu3-1",
                               "odroid-xu3-2",
                               "odroid-xu3-3"]):
    control_thermal_chamber = True
    thermal_chamber_ip = "192.168.0.13"
    thermal_chamber_port_enable = 8888
    thermal_chamber_board_id = 99
    if os.environ["HOSTNAME"] == "odroid-xu3-0":
        thermal_chamber_board_id = 0
    elif os.environ["HOSTNAME"] == "odroid-xu3-1":
        thermal_chamber_board_id = 1
    elif os.environ["HOSTNAME"] == "odroid-xu3-2":
        thermal_chamber_board_id = 2
    elif os.environ["HOSTNAME"] == "odroid-xu3-3":
        thermal_chamber_board_id = 3

def set_normal():
    return arch_set_normal()

def set_cool_down():
    return arch_cool_down()

def set_configuration(configuration):
    return arch_set_configuration(configuration)

def runner(workload_to_do):
    for workload in workload_to_do:
        print("===")
        print(workload)
        print("===")
        utils.printer("\n\n\n\n{}/{} {} {} {}".format(workload.identifier,
                                                      workload_to_do[0].identifier + len(workload_to_do) - 1,
                                                      workload.name, workload.environment, workload.work))

        cur_dir = os.path.join(os.environ["LOGTRACE_DIR"], str(workload.identifier).zfill(10))

        os.makedirs(cur_dir, exist_ok=True)
        os.makedirs(os.path.join(cur_dir, "output"), exist_ok=True)
        where_to_export = os.path.join(cur_dir, "my_stuff")
        os.makedirs(where_to_export, exist_ok=True)

        bencher_time_event_fd = open(os.path.join(cur_dir, "bencher_time_event.csv"), "w")
        bencher_time_event_fd.write("{},start\n".format(time.time_ns()))
        
        # reset init
        print("==== If this fail, no worries.")
        utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/enable\"")
        utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/export\"")
        print("====")
        if control_thermal_chamber:
            in_error = True
            while in_error:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as thermal_chamber_socket:
                        thermal_chamber_socket.sendto(str("{}.0".format(thermal_chamber_board_id)).encode('utf-8'),
                                                      (thermal_chamber_ip, thermal_chamber_port_enable))
                    in_error = False
                except OSError as err:
                    if err.errno == ENETUNREACH:
                        utils.printer("get an ENETUNREACH")
                        time.sleep(1)
                except:
                    raise

        arch_reset_init()
        # /reset init

        # init
        if config.my_stuff_bencher and config.my_stuff_export:
            utils.system_cmd("sudo bash -c \"echo {} > /proc/my_stuff/path\""
                             .format(where_to_export))
            utils.system_cmd("sudo bash -c \"echo 1 > /proc/my_stuff/export\"")

        if config.my_stuff_bencher:
            utils.system_cmd("sudo bash -c \"echo {} > /proc/my_stuff/sampling_rate\""
                             .format(workload.environment.sampling_rate_cpu_usage))
            utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/work_on\"")
            utils.system_cmd("sudo bash -c \"echo 1 > /proc/my_stuff/enable\"")

        if control_thermal_chamber:
            in_error = True
            while in_error:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as thermal_chamber_socket:
                        thermal_chamber_socket.sendto(str("{}.1".format(thermal_chamber_board_id)).encode('utf-8'),
                                                      (thermal_chamber_ip, thermal_chamber_port_enable))
                    in_error = False
                except OSError as err:
                    if err.errno == ENETUNREACH:
                        utils.printer("get an ENETUNREACH")
                        time.sleep(1)
                except:
                    raise

        arch_init()
        # /init

        with open(os.path.join(cur_dir, "pickle.dat"), "wb") as pickle_file:
            pickle.dump(workload, pickle_file)
        with open(os.path.join(cur_dir, "pickle_readable.dat"), "wb") as pickle_file:
            pickle.dump(workload, pickle_file, protocol=0)

        if ARGS.cool_down:
            bencher_time_event_fd.write("{},cool_down\n".format(time.time_ns()))
            utils.printer("Cooling down for %ds." % config.time_cool_down)
            set_cool_down()
            time.sleep(config.time_cool_down)
            utils.printer("Cooling down done.")

        utils.printer("Set configuration for bench.")
        set_configuration(workload.environment)

        if ARGS.idle:
            bencher_time_event_fd.write("{},idle\n".format(time.time_ns()))
            utils.printer("Idle for %ds to stabilise the thermal environment." % config.time_idle)
            time.sleep(config.time_idle)
            utils.printer("Idle done.")

        utils.system_cmd("sudo dmesg -c > {}/dmesg_0.txt".format(cur_dir))
        utils.system_cmd("sudo sh -c \"sync; echo 3 > /proc/sys/vm/drop_caches\"")

        if workload.name.startswith("microbe"):
            exec_path = os.path.join(cur_dir, "output")
        else:
            exec_path = None

        # prepare cmd
        stdout_fd = open(os.path.join(cur_dir, "0_stdout.dat"), "wb")
        stderr_fd = open(os.path.join(cur_dir, "0_stderr.dat"), "wb")
        time_output = os.path.join(cur_dir, "0_time.dat")

        cmd_process = []
        cmd_process.extend(["time", "-v", "-o", time_output,
                            "taskset", workload.work.taskset])
        if workload.work.need_sudo:
            cmd_process.append("sudo")
        cmd_process.append(workload.work.app)
        cmd_process.extend(workload.work.args.split())
        if exec_path:
            cmd_process.append(exec_path)
        utils.printer(" ".join(cmd_process))


        cmd_env = {"OMP_NUM_THREADS": str(workload.work.nr_threads)}
        cmd_env.update(workload.work.env)

        if config.time_before_benchmark > 0:
            time.sleep(config.time_before_benchmark)
        bench_start = time.time_ns()
        bencher_time_event_fd.write("{},bench_start\n".format(bench_start))
        
        if "CWD" in cmd_env:
            process = subprocess.Popen(cmd_process,
                                       env=cmd_env,
                                       cwd=cmd_env["CWD"],
                                       stdout=stdout_fd,
                                       stdin=subprocess.PIPE,
                                       stderr=stderr_fd)
        else:
            process = subprocess.Popen(cmd_process,
                                       env=cmd_env,
                                       stdout=stdout_fd,
                                       stdin=subprocess.PIPE,
                                       stderr=stderr_fd)

        utils.printer("pid = {}".format(process.pid))

        if workload.work.in_pipe:
            process.communicate(input=workload.work.in_pipe)
        else:
            process.wait()

        stdout_fd.close()
        stderr_fd.close()

        if process.returncode != 0:
            utils.printer("return_code = {}; Application fault!"
                          .format(process.returncode))

        bench_stop = time.time_ns()
        bencher_time_event_fd.write("{},bench_stop\n".format(bench_stop))
        if config.time_after_benchmark > 0:
            time.sleep(config.time_after_benchmark)

        # finish
        print("=== No worries if it fails")
        utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/enable\"")
        utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/export\"")
        print("===")

        if control_thermal_chamber:
            in_error = True
            while in_error:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as thermal_chamber_socket:
                        thermal_chamber_socket.sendto(str("{}.0".format(thermal_chamber_board_id)).encode('utf-8'),
                                                      (thermal_chamber_ip, thermal_chamber_port_enable))
                        
                    utils.system_cmd("scp willy@{ip}:/home/willy/boards_{idx}.csv {dir}/chamber_temperature.csv".format(ip=thermal_chamber_ip,
                                                                                                                        dir=cur_dir,
                                                                                                                        idx=thermal_chamber_board_id))
                    in_error = False
                except OSError as err:
                    if err.errno == ENETUNREACH:
                        utils.printer("get an ENETUNREACH")
                        time.sleep(1)
                except:
                    raise
                
        arch_finish(cur_dir)
        # /finish

        utils.system_cmd("sudo dmesg -c > {}/dmesg_1.txt".format(cur_dir))

        utils.printer(" ... finished at {}".format(datetime.datetime.today()))
        utils.printer("One bench done. Took {}."
                      .format(bench_stop - bench_start))
        utils.printer("Done with", workload.name)

        set_normal()

        db_path = os.path.join(os.environ["LOGTRACE_DIR"], "data.db")
        db_connection = sqlite3.connect(db_path, check_same_thread=False)

        sql = '''INSERT INTO entry(id,start,end,pid,applications_return_code) VALUES (?,?,?,?,?) '''
        cur = db_connection.cursor()
        cur.execute(sql, (workload.identifier, bench_start, bench_stop,
                          process.pid, process.returncode))
        db_connection.commit()
        db_connection.close()

        bencher_time_event_fd.close()
        
        if ARGS.backup:
            utils.printer("Backup data.")

            os.sync()
            os.sync()
            os.sync()
            os.sync()
            os.sync()
            time.sleep(2)

            utils.printer("Backup all files but data.db")
            files_to_send = []
            for files in os.listdir(os.path.join(os.environ["LOGTRACE_DIR"])):
                if (files != "data.db"
                    and files != "data.db-journal"
                    and files != "workloads.pickle"):
                    files_to_send.append(os.path.join(os.environ["LOGTRACE_DIR"], files))

            where_to_backup = (os.environ["REMOTE_USER"] + "@"
                               + os.environ["REMOTE_IP"] + ":"
                               + os.environ["REMOTE_PATH"])
            transfert_cmd = ["scp", "-o", "ConnectTimeout=1", "-r"]
            transfert_cmd.extend(files_to_send)
            transfert_cmd.append(where_to_backup)
            utils.printer(transfert_cmd)

            process_transfert_cmd = subprocess.Popen(transfert_cmd,
                                                     stdout=subprocess.DEVNULL,
                                                     stderr=subprocess.DEVNULL)
            process_transfert_cmd.wait()

            if process_transfert_cmd.returncode == 0:
                for files in files_to_send:
                    try:
                        # os.remove(files)
                        shutil.rmtree(files)
                    except:
                        traceback.print_exc()

                        utils.printer("We intentionally pass the exception to continue benching.")
                        pass
            else:
                utils.printer("Fail to send all datas!!!!")

            utils.printer("Backup data.db")
            transfert_cmd = ["scp", "-o", "ConnectTimeout=1"]
            transfert_cmd.append(os.path.join(os.environ["LOGTRACE_DIR"], "data.db"))
            transfert_cmd.append(where_to_backup)
            process_transfert_cmd = subprocess.Popen(transfert_cmd,
                                                     stdout=subprocess.DEVNULL,
                                                     stderr=subprocess.DEVNULL)
            process_transfert_cmd.wait()
            if process_transfert_cmd.returncode != 0:
                utils.printer("Fail to send data.db")

    return

def sigint_handler(signum, frame):
    utils.printer()

    print("==== If this fail, no worries.")
    utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/enable\"")
    utils.system_cmd("sudo bash -c \"echo 0 > /proc/my_stuff/export\"")
    print("====")
    if control_thermal_chamber:
        in_error = True
        while in_error:
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as thermal_chamber_socket:
                    thermal_chamber_socket.sendto(str("{}.0".format(thermal_chamber_board_id)).encode('utf-8'),
                                                  (thermal_chamber_ip, thermal_chamber_port_enable))
                in_error = False
            except OSError as err:
                if err.errno == ENETUNREACH:
                    utils.printer("get an ENETUNREACH")
                    time.sleep(1)
            except:
                raise

    arch_reset_init()

    time.sleep(2)
    ###

    set_normal()
    sys.exit(-1)
    return

def main():
    signal.signal(signal.SIGINT, sigint_handler)

    if ARGS.show:
        utils.printer("Number of workloads to do %d" % len(config.workload_to_do))
        utils.printer(config.workload_to_do)

    while True:
        answer = input("Is that OK? [y/n] ")
        if answer == "n":
            sys.exit(0)
        elif answer == "y":
            break

    utils.system_cmd("sudo dmesg -c")

    if config.time_stress > 0:
        utils.system_cmd("stress -c 8 -t {}s".format(config.time_stress))
    
    bench_start = datetime.datetime.today()
    runner(config.workload_to_do)
    bench_stop = datetime.datetime.today()

    utils.printer("All benchmark done. Took {}"
                  .format(bench_stop - bench_start))

    set_normal()
    return


if __name__ == '__main__':
    main()
