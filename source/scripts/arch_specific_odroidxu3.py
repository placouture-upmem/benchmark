import utils

def arch_set_normal():
    subscript = []
    subscript.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
    subscript.append("echo 1400000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq")
    subscript.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor")
    subscript.append("echo 2000000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    subscript = []
    subscript.append("echo simple_ondemand > /sys/class/devfreq/10c20000.memory-controller/governor")
    subscript.append("echo 825000000 > /sys/class/devfreq/10c20000.memory-controller/max_freq")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    subscript = []
    
    # for idx_tz in range(4):
    #     subscript.append("echo step_wise > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/policy".format(idx_tz=idx_tz))
    #     subscript.append("echo 50000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_0_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 60000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_1_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 70000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_2_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_3_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 70000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_4_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 85000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_5_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 105000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_6_temp".format(idx_tz=idx_tz))

    # subscript.append("echo step_wise > /sys/devices/virtual/thermal/thermal_zone4/policy")
    # subscript.append("echo 85000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_0_temp")
    # subscript.append("echo 103000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_1_temp")
    # subscript.append("echo 110000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_2_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_3_temp")
    # subscript.append("echo 50000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_4_temp")
    # subscript.append("echo 60000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_5_temp")
    # subscript.append("echo 70000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_6_temp")
    # subscript.append("echo 70000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_7_temp")
    # subscript.append("echo 85000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_8_temp")
    # subscript.append("echo 104000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_9_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_10_temp")

    # for idx_tz in range(5):
    #     subscript.append("echo enabled > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/mode".format(idx_tz=idx_tz))

    for idx_tz in range(5):
        subscript.append("echo enabled > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/mode".format(idx_tz=idx_tz))
    utils.system_cmd("sudo bash -c \"{}\"".format(" \\\n\t&& ".join(subscript)))

    subscript = []
    subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device0/cur_state")
    subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device1/cur_state")
    subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device2/cur_state")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    return

def arch_cool_down():
    subscript = []
    subscript.append("echo 200000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq")
    subscript.append("echo 200000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    subscript = []
    subscript.append("echo 165000000 > /sys/class/devfreq/10c20000.memory-controller/max_freq")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    subscript = []
    for idx_tz in range(5):
        subscript.append("echo user_space > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/policy".format(idx_tz=idx_tz))
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    subscript = []
    subscript.append("echo  3 > /sys/devices/virtual/thermal/cooling_device0/cur_state")
    subscript.append("echo 12 > /sys/devices/virtual/thermal/cooling_device1/cur_state")
    subscript.append("echo 18 > /sys/devices/virtual/thermal/cooling_device2/cur_state")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    return

def arch_set_configuration(configuration):
    print(configuration)
    
    subscript = []
    subscript.append("echo {value} > /sys/devices/system/cpu/cpufreq/policy{policy}/scaling_max_freq".format(policy=configuration.dvfs_cpu_max_frequency[0][0],
                                                                                                             value=configuration.dvfs_cpu_max_frequency[0][1]))
    subscript.append("echo {value} > /sys/devices/system/cpu/cpufreq/policy{policy}/scaling_governor".format(policy=configuration.dvfs_cpu_governor[0][0],
                                                                                                             value=configuration.dvfs_cpu_governor[0][1]))
    subscript.append("echo {value} > /sys/devices/system/cpu/cpufreq/policy{policy}/scaling_max_freq".format(policy=configuration.dvfs_cpu_max_frequency[1][0],
                                                                                                             value=configuration.dvfs_cpu_max_frequency[1][1]))
    subscript.append("echo {value} > /sys/devices/system/cpu/cpufreq/policy{policy}/scaling_governor".format(policy=configuration.dvfs_cpu_governor[1][0],
                                                                                                             value=configuration.dvfs_cpu_governor[1][1]))

    utils.system_cmd("sudo bash -c \"{}\"".format(" \\\n\t&& ".join(subscript)))
    
    subscript = []
    subscript.append("echo {} > /sys/class/devfreq/10c20000.memory-controller/governor".format(configuration.dvfs_memory_governor))
    subscript.append("echo {} > /sys/class/devfreq/10c20000.memory-controller/max_freq".format(configuration.dvfs_memory_frequency))

    utils.system_cmd("sudo bash -c \"{}\"".format(" \\\n\t&& ".join(subscript)))

    subscript = []
    # for idx_tz in range(4):
    #     subscript.append("echo {value} > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/policy".format(idx_tz=idx_tz,
    #                                                                                                       value=configuration.thermal_governor))
    #     subscript.append("echo 10000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_0_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 10000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_1_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 10000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_2_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_3_temp".format(idx_tz=idx_tz)) ## critical
    #     subscript.append("echo 10000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_4_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo 10000 > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_5_temp".format(idx_tz=idx_tz))
    #     subscript.append("echo {value} > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/trip_point_6_temp".format(idx_tz=idx_tz,
    #                                                                                                                  value=configuration.trip_point_temperature))

    # subscript.append("echo {value} > /sys/devices/virtual/thermal/thermal_zone4/policy".format(value=configuration.thermal_governor))
    # # subscript.append("echo 85000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_0_temp")
    # # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_1_temp")
    # # subscript.append("echo 103000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_2_temp")
    # # subscript.append("echo 110000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_3_temp")
    # # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_4_temp")
    # # subscript.append("echo 50000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_5_temp")
    # # subscript.append("echo 60000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_6_temp")
    # # subscript.append("echo 70000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_7_temp")
    # # subscript.append("echo 85000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_8_temp")
    # # subscript.append("echo 104000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_9_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_0_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_1_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_2_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_3_temp") ## critical
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_4_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_5_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_6_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_7_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_8_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_9_temp")
    # subscript.append("echo 120000 > /sys/devices/virtual/thermal/thermal_zone4/trip_point_10_temp") ## critical

    for idx_tz in range(5):
        subscript.append("echo disabled > /sys/devices/virtual/thermal/thermal_zone{idx_tz}/mode".format(idx_tz=idx_tz))

    utils.system_cmd("sudo bash -c \"{}\"".format(" \\\n\t&& ".join(subscript)))
    
    subscript = []
    if configuration.fan:
        subscript.append("echo 3 > /sys/devices/virtual/thermal/cooling_device0/cur_state")
    else:
        subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device0/cur_state")

    subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device1/cur_state")
    subscript.append("echo 0 > /sys/devices/virtual/thermal/cooling_device2/cur_state")
    utils.system_cmd("sudo bash -c \"{}\"".format(" \\\n\t&& ".join(subscript)))

    return

def arch_init():
    subscript = []
    subscript.append("echo 1 > /sys/class/hwmon/hwmon0/enable")
    subscript.append("echo 1 > /sys/class/hwmon/hwmon1/enable")
    subscript.append("echo 1 > /sys/class/hwmon/hwmon2/enable")
    subscript.append("echo 1 > /sys/class/hwmon/hwmon3/enable")

    # subscript.append("echo 1 > /sys/class/hwmon/hwmon0/reset")
    # subscript.append("echo 1 > /sys/class/hwmon/hwmon1/reset")
    # subscript.append("echo 1 > /sys/class/hwmon/hwmon2/reset")
    # subscript.append("echo 1 > /sys/class/hwmon/hwmon3/reset")
    
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    return

def arch_finish(cur_dir):
    subscript = []
    subscript.append("echo 0 > /sys/class/hwmon/hwmon0/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon1/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon2/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon3/enable")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    if cur_dir:
        subscript = []
        subscript.append("cp /sys/class/hwmon/hwmon0/all {}/hwmon0_all.csv".format(cur_dir))
        subscript.append("cp /sys/class/hwmon/hwmon1/all {}/hwmon1_all.csv".format(cur_dir))
        subscript.append("cp /sys/class/hwmon/hwmon2/all {}/hwmon2_all.csv".format(cur_dir))
        subscript.append("cp /sys/class/hwmon/hwmon3/all {}/hwmon3_all.csv".format(cur_dir))

        utils.system_cmd("bash -c \"{}\"".format(" && ".join(subscript)))

    return

def arch_reset_init():
    subscript = []
    subscript.append("echo 0 > /sys/class/hwmon/hwmon0/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon1/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon2/enable")
    subscript.append("echo 0 > /sys/class/hwmon/hwmon3/enable")
    utils.system_cmd("sudo bash -c \"{}\"".format(" && ".join(subscript)))

    return
