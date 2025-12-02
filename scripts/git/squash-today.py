#!/usr/bin/env python3
"""
Squash all commits from today into a single commit.
Preserves all commit messages in the squashed commit.
"""

import subprocess
import sys
from datetime import datetime

def run_command(cmd, capture=True):
    """Run a shell command and return output or status."""
    if capture:
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        return result.stdout.strip(), result.returncode
    else:
        result = subprocess.run(cmd, shell=True)
        return None, result.returncode

def get_today_commits():
    """Get all commits from today."""
    today = datetime.now().strftime("%Y-%m-%d")
    cmd = f"git log --since='{today} 00:00:00' --until='{today} 23:59:59' --pretty=format:'%H|%s' --reverse"
    output, _ = run_command(cmd)
    
    if not output:
        return []
    
    commits = []
    for line in output.split('\n'):
        if line:
            hash_val, message = line.split('|', 1)
            commits.append({'hash': hash_val, 'message': message})
    
    return commits

def main():
    print("🔍 Suche nach Commits von heute...")
    
    # Check if we're in a git repository
    _, retcode = run_command("git rev-parse --git-dir")
    if retcode != 0:
        print("❌ Fehler: Nicht in einem Git-Repository")
        sys.exit(1)
    
    # Get today's commits
    commits = get_today_commits()
    
    if not commits:
        print("ℹ️  Keine Commits von heute gefunden.")
        sys.exit(0)
    
    if len(commits) == 1:
        print(f"ℹ️  Nur ein Commit von heute gefunden: {commits[0]['message']}")
        print("   Nichts zu squashen.")
        sys.exit(0)
    
    print(f"\n📋 Gefunden: {len(commits)} Commits von heute:\n")
    for i, commit in enumerate(commits, 1):
        print(f"  {i}. {commit['message']}")
    
    # Ask for confirmation
    print("\n⚠️  Dies wird die Commits zusammenfassen (squash).")
    response = input("Fortfahren? (ja/nein): ").lower()
    
    if response not in ['ja', 'j', 'yes', 'y']:
        print("Abgebrochen.")
        sys.exit(0)
    
    # Get the parent of the first commit
    first_commit = commits[0]['hash']
    parent_cmd = f"git rev-parse {first_commit}^"
    parent_hash, retcode = run_command(parent_cmd)
    
    if retcode != 0:
        print("❌ Fehler: Kann Parent-Commit nicht finden.")
        print("   Möglicherweise ist der erste Commit der Initial-Commit.")
        sys.exit(1)
    
    # Create combined commit message
    combined_message = "Commits vom " + datetime.now().strftime("%Y-%m-%d") + ":\n\n"
    for commit in commits:
        combined_message += f"- {commit['message']}\n"
    
    # Perform soft reset to parent
    print(f"\n🔄 Resette auf Parent-Commit: {parent_hash[:8]}")
    _, retcode = run_command(f"git reset --soft {parent_hash}", capture=False)
    
    if retcode != 0:
        print("❌ Fehler beim Reset")
        sys.exit(1)
    
    # Create new commit with combined message
    print("📝 Erstelle neuen kombinierten Commit...")
    
    # Write message to temp file to handle multiline properly
    import tempfile
    import os
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        f.write(combined_message)
        temp_file = f.name
    
    _, retcode = run_command(f"git commit -F {temp_file}", capture=False)
    
    # Clean up temp file
    os.unlink(temp_file)
    
    if retcode != 0:
        print("❌ Fehler beim Commit")
        sys.exit(1)
    
    print("\n✅ Erfolgreich! Alle Commits von heute wurden zusammengefasst.")
    print("\n💡 Zum Pushen: git push --force-with-lease")

if __name__ == '__main__':
    main()
