let g:ctags_statusline=1

syntax on

set nocp

filetype plugin on
filetype indent on

" У меня экран мелий на работе, по этой причине, для комфортного просмотра
" исходных текстор, мне нужно такое вот разрешение экрана.
"
set tw=100

set smartindent
"set tabstop=4
set shiftwidth=8
set ts=8
"set expandtab

" устанавливаем поддержку (???) 256 цветов в консоли для поддержки
" разных цветовых схем в обычном Vim
set t_Co=256
colorscheme neon

" Highlight searches (use <C-L> to temporarily turn off highlighting;
" see the mapping of <C-L> below)
set hlsearch

" Инкрементный поиск по документу
set incsearch

" Включаем нумерация строк
set number

" Map <C-L> (redraw screen) to also turn off search highlighting until
" the next search
nnoremap <C-L> :nohl<CR><C-L>
