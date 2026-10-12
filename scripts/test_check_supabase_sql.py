import subprocess
import tempfile
import unittest
from pathlib import Path
from check_supabase_sql import rejected_paths


class LegacySqlPolicyTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='playspot sql policy ')
        self.root = Path(self.directory.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@local.invalid')
        (self.root / 'supabase').mkdir()
        self.sql = self.root / 'supabase/reference.sql'
        self.sql.write_text('-- Approved reference only\nSELECT 1;\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'Approved fixture')
        self.approved = self.git('rev-parse', 'HEAD').strip()

    def tearDown(self):
        self.directory.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True)

    def test_existing_release_references_are_allowed(self):
        self.assertEqual(rejected_paths(self.root, ['supabase/reference.sql'], self.approved), [])

    def test_modified_reference_is_rejected(self):
        self.sql.write_text('SELECT 2;\n')
        self.assertEqual(rejected_paths(self.root, ['supabase/reference.sql'], self.approved), ['supabase/reference.sql'])

    def test_new_dashboard_sql_is_rejected(self):
        (self.root / 'supabase/new.sql').write_text('SELECT 1;\n')
        self.assertEqual(rejected_paths(self.root, ['supabase/new.sql'], self.approved), ['supabase/new.sql'])


if __name__ == '__main__':
    unittest.main()
