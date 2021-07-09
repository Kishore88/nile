#!/usr/bin/env python3

import os
import re
import glob
import boto3
import requests
import subprocess

from time import sleep

AWS_REGION          = os.environ['AWS_REGION']
DEPLOY_UUID         = os.environ['DEPLOY_UUID']
SERVICE_NAME        = os.environ['SERVICE_NAME']
MOUNT_POINT         = "/var/lib/" + SERVICE_NAME
NIC_IP              = os.environ['NIC_IP']
TAG_KEY             = os.environ['TAG_KEY']


def retrieve_eni_ids():
    ec2 = boto3.resource('ec2')
    enis = []

    for eni in ec2.network_interfaces.all():
        for tag in eni.tag_set:
            if tag['Key'] == TAG_KEY:
                if tag['Value'] == DEPLOY_UUID:
                    enis.append(eni.network_interface_id)

    return enis if len(enis) > 0 else None


def attach_eni_ids():
    c_ec2 = boto3.client('ec2')
    r_ec2 = boto3.resource('ec2')

    i_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    eni_ids = retrieve_eni_ids()
    device_number = len(r_ec2.Instance(i_id).network_interfaces) + 1

    for eni_id in eni_ids:
        c_ec2.attach_network_interface(DeviceIndex=device_number, InstanceId=i_id, NetworkInterfaceId=eni_id)


def retrieve_ebs_ids():
    ec2 = boto3.resource('ec2')
    ebss = []

    for volume in ec2.volumes.all():
        if volume.tags is not None:
            for tag in volume.tags:
                if tag['Key'] == TAG_KEY:
                    if tag['Value'] == DEPLOY_UUID:
                        ebss.append(volume.volume_id)

    return ebss if len(ebss) > 0 else None


def attach_ebs():
    ec2 = boto3.client('ec2')

    i_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    volume_ids = retrieve_ebs_ids()

    i = 0
    device_char = 'z'
    while i < len(volume_ids):
        v_id = volume_ids[i]

        device = '/dev/xvd{0}'.format(device_char)
        ec2.attach_volume(Device=device, InstanceId=i_id, VolumeId=v_id)

        # Wait to ensure device is attached
        sleep(3)

        if not check_ebs(v_id):
            prepare_ebs(v_id)

        add_fstab_entries(v_id, MOUNT_POINT)

        p_mount = subprocess.Popen('mount -a'.split(), stdout=subprocess.PIPE)
        stdout, stderr = p_mount.communicate()

        p_chown = subprocess.Popen('chown -R {0}:{0} {1}'.format(SERVICE_NAME, MOUNT_POINT).split(),
                                   stdout=subprocess.PIPE)
        stdout, stderr = p_chown.communicate()

        device_char = chr(ord(device_char) - 1)
        i += 1


def check_ebs(volume_id):
    v_id = volume_id.replace('vol-', 'vol')
    pattern = '/dev/disk/by-id/*{0}-part1'.format(v_id)

    return bool(len(glob.glob(pattern)))


def prepare_ebs(volume_id):
    v_id = volume_id.replace('vol-', 'vol')
    pattern = '/dev/disk/by-id/*{0}'.format(v_id)
    device = glob.glob(pattern)[0]

    gdisk_commands = '\n'.join([
        'n',
        '1',
        '34',
        '',
        '',
        'w',
        'Y',
        ''
    ])

    p_echo = subprocess.Popen('echo -ne {0}'.format(gdisk_commands).split(' '), stdout=subprocess.PIPE)
    p_fdisk = subprocess.Popen('gdisk {0}'.format(device).split(), stdin=p_echo.stdout, stdout=subprocess.PIPE)
    stdout, stderr = p_fdisk.communicate()
    print(stdout)
    print(stderr)

    # p_partprobe = subprocess.Popen('partprobe'.split(' '), stdout=subprocess.PIPE)
    # stdout, stderr = p_partprobe.communicate()
    # print(stdout)
    # print(stderr)

    sleep(3)

    pattern = '/dev/disk/by-id/*{0}-part1'.format(v_id)
    partition = glob.glob(pattern)[0]

    p_xfs = subprocess.Popen('mkfs.xfs {0}'.format(partition).split(), stdout=subprocess.PIPE)
    stdout, stderr = p_xfs.communicate()
    print(stdout)
    print(stderr)


def add_fstab_entries(volume_id, mount_point):
    v_id = volume_id.replace('vol-', 'vol')
    pattern = '/dev/disk/by-id/*{0}-part1'.format(v_id)
    partition = glob.glob(pattern)[0]

    fstab_entries = [
        mount_point,
        'xfs',
        'defaults',
        '0',
        '0'
    ]

    with open('/etc/fstab', 'a') as f:
        f.write('{0} {1}\n'.format(partition, ' '.join(fstab_entries)))
        f.flush()
        f.close()



def wait_device_ready(timeout=3):
    c = 0
    while c < timeout:
        sleep(1)

        p_ip = subprocess.Popen('ip a'.split(), stdout=subprocess.PIPE)
        stdout, stderr = p_ip.communicate()

        for line in stdout.decode().splitlines():
            res = re.match('.*inet {0}/[0-9]{{2}}'.format(NIC_IP), line)

            if res is not None:
                return None

        c += 1

    raise Exception('Device with address {0} not ready'.format(NIC_IP))


def change_default_route():
    wait_device_ready(10)

    p_ip = subprocess.Popen('ip r'.split(), stdout=subprocess.PIPE)
    stdout, stderr = p_ip.communicate()

    r_subnet_rules = []
    for line in stdout. decode().splitlines():
        res = re.match('(.* ){2}eth[0-9](?! $).*', line)

        if res is not None:
            subnet_rule = res.group(0)
            l_subnet_rule = subnet_rule.split()
            device = l_subnet_rule[2]
            ip = l_subnet_rule[-1]

            r_subnet_rules.append(
                {
                    'device': device,
                    'ip': ip,
                    'subnet_rule': subnet_rule
                }
            )

    r_default_route = ''
    for line in stdout.decode().splitlines():
        res = re.match('default .*', line)

        if res is not None:
            r_default_route = res.group(0)

            break

    with open('/etc/rc.local', 'a') as f:
        f.write('#!/bin/bash\n\n')

        rule_index = 128
        default_route_device = ''
        for rule in r_subnet_rules:
            default_route = re.sub('eth.', rule['device'], r_default_route)

            f.write('ip rule add from {0} table {1}\n'.format(rule['ip'], rule_index))
            f.write('ip r add {0} table {1}\n'.format(default_route, rule_index))
            f.write('ip r add {0} table {1}\n\n'.format(rule['subnet_rule'], rule_index))

            if rule['ip'] == NIC_IP:
                default_route_device = rule['device']

            rule_index += 1

        default_route = re.sub('eth.', default_route_device, r_default_route)

        f.write('ip r del default\n')
        f.write('ip r add {0}\n\n'.format(default_route))
        f.write('exit 0\n')

        f.flush()
        f.close()

    os.chmod('/etc/rc.local', 0o0755)

    p_rc_local = subprocess.Popen('/etc/rc.local'.split(), stdout=subprocess.PIPE)
    stdout, stderr = p_rc_local.communicate()




if __name__ == '__main__':
    boto3.setup_default_session(region_name=AWS_REGION)

    # uses: DEPLOY_UUID, TAG_KEY
    attach_eni_ids()
    # uses: MOUNT_POINT, SERVICE_NAME, DEPLOY_UUID, TAG_KEY
    attach_ebs()
    # uses: NIC_IP
    change_default_route()
