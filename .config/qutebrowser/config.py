config.load_autoconfig(True)

c.colors.webpage.darkmode.enabled = True 

c.editor.command = ['nvim', '-f', '{}']

c.tabs.position = 'left'
c.tabs.show = 'switching'

c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'y': 'https://youtube.com/results?search_query={}',
    'git': 'https://github.com/search?q={}',
    'gc': 'https://calendar.google.com/calendar/u/0/r/search?q={}'
}

config.bind('<Alt-Shift-u>', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='insert')
config.bind('pw', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB', mode='normal')
config.bind('pt', 'spawn --userscript qute-keepassxc --key 177C5800F00A9FAB --totp', mode='normal')

config.unbind('d')
config.bind('x', 'tab-close')
