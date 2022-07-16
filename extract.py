import os
import shutil
from glob import glob
import argparse


def find_dcs_directory():
    home = os.environ['USERPROFILE']
    saved_games = os.path.join(home, 'Saved Games')
    dcs_openbeta = os.path.join(saved_games, 'DCS.openbeta')
    dcs = os.path.join(saved_games, 'DCS')
    candidate_dcs_dirs = [dcs_openbeta, dcs]
    for candidate_dcs_path in candidate_dcs_dirs:
        if os.path.exists(candidate_dcs_path):
            return candidate_dcs_path
    raise ValueError("Cannot find DCS saved games directory")


def main():
    dcs_dir = find_dcs_directory()
    parser = argparse.ArgumentParser(
        description='Pack/unpack DCS mission from/to the git repo.')
    command_group = parser.add_mutually_exclusive_group(required=True)
    command_group.add_argument(
        '--pack',
        action='store_true',
        help='Pack the miz file and copy to DCS saved games dir')
    command_group.add_argument(
        '--unpack',
        action='store_true',
        help=
        'Extract the contents of the miz file from the DCS saved games dir to the local repo.'
    )
    parser.add_argument(
        '-d',
        '--dont_copy',
        action='store_false',
        default=False,
        help=
        "If set, don't actually copy the mission archive to the DCS saved games dir."
    )
    args = parser.parse_args()

    all_subdirs = glob(os.path.join(os.getcwd(), '*/'))
    miz_subdir = all_subdirs[0]
    dirname, mizname = os.path.split(miz_subdir[:-1])
    miz_fullname = mizname + '.miz'

    missions_dir = os.path.join(dcs_dir, 'Missions')
    miz_in_dcs_dir = os.path.join(missions_dir, miz_fullname)
    miz_local = os.path.join(os.getcwd(), miz_fullname)

    def pack():
        shutil.make_archive(mizname, format='zip', root_dir=miz_subdir)
        shutil.move(mizname + '.zip', miz_fullname)
        if not args.dont_copy:
            if os.path.exists(miz_in_dcs_dir):
                shutil.copyfile(dst=miz_in_dcs_dir + '.backup',
                                src=miz_in_dcs_dir)
            shutil.copyfile(dst=miz_in_dcs_dir, src=miz_fullname)
            os.remove(miz_local)


    def unpack():
        try:
            import git
        except ImportError:
            pass
        else:
            repo = git.Repo(os.getcwd())
            if repo.is_dirty():
                print(
                    "Found untracked local files, please commit or discard before unpacking mission."
                )
                exit(-1)

        all_subdirs = glob(os.path.join(os.getcwd(), '*/'))
        miz_subdir = all_subdirs[0]
        dirname, mizname = os.path.split(miz_subdir[:-1])
        shutil.copyfile(src=miz_in_dcs_dir, dst=miz_fullname)
        shutil.unpack_archive(miz_fullname, miz_subdir, format='zip')
        os.remove(miz_local)

    if args.pack:
        pack()
    elif args.unpack:
        unpack()
    else:
        assert (False)


if __name__ == '__main__':
    main()
