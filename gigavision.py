#!/usr/bin/env python3
"""
This will be the primary script for management of the gigavision toolchain.

The intention is to write a single script that replaces the previous
Gigavision processing pipeline, including calls to the stitcher.  However it
will NOT include database management or interaction with webservers - the idea
is to locally transform inputs into outputs, and use other tools to manage the
peripheral processes.

Useful links include the user manual and technical manual for the stitcher:
http://www.gigapan.com/cms/manual/pdf/stitch-efx-upload-manual.pdf
https://docs.google.com/a/gigapansystems.com/document/d/1WTMsi9GM-Nq1xYXgxqC_fc2WGz3SKCddf1B73iICUTo/edit


Deliberate changes from previous scripts:
    * Only supports full resolution stitching
    * Does not produce HTML output
    * Does not manage uploads

"""

import glob
import logging
import os
import subprocess
import sys

# global logger
log = logging.getLogger("gigavision")

# The base folder for the whole gigapan infrastructure
MOUNTFLDR = '.'

# The identifying string (name) for the camera - must be overridden
PROJECT = 'unknown'


def quote(path):
    """Quote file paths, to safely handle spaces."""
    return '"{}"'.format(path) if ' ' in path else path


def stitcher_path():
    """Return the path to the stitcher to call."""
    stitcher = ''
    if sys.platform == 'darwin':
        stitcher = '/Applications/GigaPan\ 2.1.0160/GigaPan\ Stitch\ ' +\
            '2.1.0160.app/Contents/MacOS/GigaPan\ Stitch\ 2.1.0160'
    if sys.platform == 'win32':
        stitcher = '"\Program Files (x86)\GigaPan\GigaPan 2.1.0161\stitch.exe"'
    if os.path.isfile(stitcher):
        log.info('Stitching with ' + stitcher)
        return stitcher
    msg = 'Unable to find stitcher; please check installation.'
    log.error(msg)
    raise RuntimeError(msg)


def get_save_path(project, date_and_hour, resolution='full'):
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
                              date_and_hour.year, month, day, title)
    return local_path


def call_stitcher(project, date_and_hour, n_rows, master=None):
    """Call the stitcher program.  Replaces tools/simple_stitch.sh

    Photos must be taken from the top-left corner of the gigapan, rows-first.

    Arguments:
        project:        the name of the project in which the gigapan was taken
        date_and_hour:  a datetime.datetime object, containing date and hour
                        at which the gigapan was taken
        n_rows:         number of rows of photos in the imput
        master:         path to a 'master' image to correct against
                            if None, do not correct gigapan
    """
    local_path = get_save_path(project, date_and_hour)
    title = os.path.basename(local_path)
    save_as = os.path.join(local_path, title + '.gigapan')
    img_list = glob.glob(os.path.join(local_path, '*[0-9].jpg'))
    if len(img_list) % n_rows:
        msg = 'Invalid row count for number of images found.'
        log.error(msg)
        raise ValueError(msg)
    stitch_args = [
        stitcher_path(), '--batch-mode', '--align-quit', '--title', title,
        '--images', ' '.join(quote(i) for i in img_list),
        '--rowfirst', '--downward', '--rightward', '--nrows', n_rows,
        '--save-as', save_as]
    if master is not None:
        stitch_args.extend(['--master', master])
    return subprocess.call(stitch_args)
