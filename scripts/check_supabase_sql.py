"""Permit unchanged approved legacy SQL while blocking new Dashboard SQL.

New or changed SQL must live in playspot_V2/supabase/migrations. The fixed
reference commit makes existing dev history promotable without blessing new SQL.
"""
import subprocess
import sys
from pathlib import Path

APPROVED_REFERENCE = 'e0ea905276cb350a7f20100822c4b3e1d8b872f6'


def git(root, *args):
    return subprocess.run(['git', '-C', str(root), *args], check=True,
                          capture_output=True).stdout


def rejected_paths(root, changed, approved=APPROVED_REFERENCE):
    rejected = []
    for path in changed:
        try:
            reference = git(root, 'show', f'{approved}:{path}')
        except subprocess.CalledProcessError:
            rejected.append(path)
            continue
        if (root / path).read_bytes().replace(b'\r\n', b'\n') != reference.replace(b'\r\n', b'\n'):
            rejected.append(path)
    return rejected


def main():
    root = Path(__file__).resolve().parents[1]
    changed = git(root, 'diff', '--name-only', '-z', '--diff-filter=ACMRT',
                  f'{sys.argv[1]}...HEAD', '--', 'supabase/*.sql')
    paths = [path.decode() for path in changed.split(b'\0') if path]
    rejected = rejected_paths(root, paths)
    if rejected:
        print('New/modified Dashboard SQL is prohibited. Use playspot_V2/supabase/migrations/.')
        print('\n'.join(rejected))
        return 1
    print(f'Canonical SQL policy passed; {len(paths)} unchanged legacy references accepted.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
