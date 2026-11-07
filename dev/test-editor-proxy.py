import os, pathlib, shutil, subprocess, tempfile, time
nvim = os.environ.get('SIDEKICK_NVIM') or shutil.which('nvim')
assert nvim, 'Set SIDEKICK_NVIM or add nvim to PATH'
proxy = str(pathlib.Path('bin/sidekick-editor-proxy-gedit').resolve())
with tempfile.TemporaryDirectory(prefix='proxy-test-') as d:
    root = pathlib.Path(d)
    socket = str(root / 'nvim.sock')
    target = root / "prompt with 'quotes.txt"
    target.write_text('original')
    init = root / 'init.lua'
    init.write_text('''package.preload['KoalaVim.utils.ai.general'] = function()
      return { open_editor_file = function(file, pipe, pane)
        assert(pane == 'test-pane')
        vim.schedule(function()
          vim.fn.writefile({'edited'}, file)
          vim.system({'sh', '-c', 'echo done > ' .. vim.fn.shellescape(pipe)})
        end)
        return ''
      end }
    end
    ''')
    server = subprocess.Popen([nvim, '--headless', '-u', str(init), '--listen', socket], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        for _ in range(100):
            if pathlib.Path(socket).exists(): break
            time.sleep(.02)
        env = dict(os.environ, NVIM=socket, SIDEKICK_NVIM=nvim, HERDR_PANE_ID='test-pane', PATH='/usr/bin:/bin')
        subprocess.run([proxy, str(target)], env=env, check=True, timeout=10)
        assert target.read_text() == 'edited\n'
        print('Proxy RPC, quoted file path, caller pane and FIFO completion passed with nvim absent from PATH')
    finally:
        server.terminate()
        server.communicate(timeout=5)
