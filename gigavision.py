#!/usr/bin/env python3
"""
This will be the primary script for management of the gigavision toolchain.

The intention is to write a single script that replaces the previous
Gigavision processing pipeline, including calls to the stitcher.  However it
will NOT include database management or interaction with webservers - the idea
is to locally transform inputs into outputs, and use other tools to manage the
peripheral processes.
"""

# Note: variables in shell scripts are loaded from ./shared/config.ini

import csv
import datetime
import glob
import logging
import os
import subprocess

# The base folder for the whole gigapan infrastructure
MOUNTFLDR = '.'

# The identifying string (name) for the camera - must be overridden
PROJECT = 'unknown'

# Path to the stitcher binary
STITCHER_PATH = os.path.join(
    '/Applications', 'GigaPan 2.1.0160', 'GigaPan Stitch 2.1.0160.app',
    'Contents', 'MacOS', 'GigaPan Stitch 2.1.0160')


def get_save_path(project, date_and_hour, resolution):
    """Get the path at which a gigapan should be saved.

    Arguments:
        project:        the name of the project in which the gigapan was taken
        date_and_hour:  a datetime.datetime object, containing date and hour
                        at which the gigapan was taken
    """
    month = date_and_hour.year + '_' + date_and_hour.month
    day = month + '_' + date_and_hour.day
    title = day + '_' + date_and_hour.hour
    local_path = os.path.join(MOUNTFLDR, project, 'images', resolution,
                              date_and_hour.year, month, day)
    # Note:  input images are in local_path/title
    #        gigapan saved to local_path/resname+'_'+title+'.gigapan'
    return local_path, title


def call_stitcher(project, date_and_hour, resolution='full', n_rows=None,
                  master=None):
    """Call the stitcher program.  Replaces tools/simple_stitch.sh

    Arguments:
        project:        the name of the project in which the gigapan was taken
        date_and_hour:  a datetime.datetime object, containing date and hour
                        at which the gigapan was taken
        resolution:     desired input resolution
        n_rows:         estimated rows of photos in the imput
        master:         path to a 'master' image to correct against
                            if None, do not correct gigapan
    """
    # TODO: handle resolution correctly
    resname = resolution if resolution == 'full' else 'resname'

    local_path, title = get_save_path(project, date_and_hour, resolution)
    save_as = os.path.join(local_path, resname + '_' + title + '.gigapan')
    img_list = glob.glob(os.path.join(local_path, '*[0-9].jpg'))

    # TODO:  correctly calculate n_rows
    n_rows = int(len(img_list) ** 0.5)

    stitch_args = [
        STITCHER_PATH, '--batch-mode',', ''--align-quit', '--title', title,
        '--image-list', img_list, '--rowfirst', '--downward', '--rightward',
        '--nrows', n_rows, '--save-as', save_as]
    if master is not None:
        stitch_args.extend(['--master', master])

    return subprocess.call(stitch_args)

