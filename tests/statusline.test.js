const test = require('node:test');
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const hooks = path.join(__dirname, '..', 'hooks');
const ESC = '\x1b';

const shells = [
  { name: 'bash', cmd: 'bash', args: (s) => [s], script: 'crewcut-statusline.sh' },
  { name: 'pwsh', cmd: 'pwsh', args: (s) => ['-NoProfile', '-NonInteractive', '-File', s], script: 'crewcut-statusline.ps1' },
];

function available(cmd) {
  return spawnSync(cmd, ['--version'], { encoding: 'utf8' }).status === 0;
}

for (const shell of shells) {
  const skip = available(shell.cmd) ? false : shell.cmd + ' not installed';

  function render(flagContent, { symlink = false } = {}) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'crewcut-sl-'));
    const flag = path.join(dir, '.crewcut-active');
    if (symlink) {
      const target = path.join(dir, 'target');
      fs.writeFileSync(target, flagContent);
      fs.symlinkSync(target, flag);
    } else {
      fs.writeFileSync(flag, flagContent);
    }
    const result = spawnSync(shell.cmd, shell.args(path.join(hooks, shell.script)), {
      encoding: 'utf8',
      env: { ...process.env, CLAUDE_CONFIG_DIR: dir },
    });
    fs.rmSync(dir, { recursive: true, force: true });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout;
  }

  test(shell.name + ': renders the levels', { skip }, () => {
    assert.equal(render('full\n'), ESC + '[38;5;108m[CREWCUT]' + ESC + '[0m');
    assert.equal(render('ultra\n'), ESC + '[38;5;173m[CREWCUT:ULTRA]' + ESC + '[0m');
    assert.equal(render('Lite\r\n'), ESC + '[38;5;108m[CREWCUT:LITE]' + ESC + '[0m');
  });

  test(shell.name + ': strips escape bytes from the flag', { skip }, () => {
    assert.equal(render('li' + ESC + ']0;pwned\x07te'), ESC + '[38;5;108m[CREWCUT:LI0PWNEDTE]' + ESC + '[0m');
  });

  test(shell.name + ': reads at most 64 bytes', { skip }, () => {
    assert.equal(render('a'.repeat(200)), ESC + '[38;5;108m[CREWCUT:' + 'A'.repeat(64) + ']' + ESC + '[0m');
  });

  test(shell.name + ': ignores a symlinked flag', { skip: skip || (process.platform === 'win32' && 'symlinks need admin on Windows') }, () => {
    assert.equal(render('full', { symlink: true }), '');
  });
}
