%%
%% SDUTeX - 山东大学学位论文参考文献样式
%% 
%% 基于 GB/T 7714-2015 标准
%% 
%% 使用方式：
%% \bibliographystyle{sduthesis}
%%
%%\ProvidesFile{sduthesis.bst}[2024/12/01 1.0.0 SDU Thesis Bibliography Style]

ENTRY
  { address
    author
    booktitle
    chapter
    edition
    editor
    howpublished
    institution
    journal
    key
    lang
    month
    note
    number
    organization
    pages
    publisher
    school
    series
    title
    type
    url
    urldate
    volume
    year
    doi
  }
  {}
  { label }

INTEGERS { output.state before.all }

STRINGS { s t }

FUNCTION {init.state.consts}
{ #0 'before.all :=
}

FUNCTION {set.lang}
{ 's :=
}

FUNCTION {output.nonnull}
{ 't :=
  output.state 'before.all =
    {
      write$
    }
    {
      s empty$
        { "," * write$ }
        { " " * write$ }
      if$
      t write$
    }
  if$
  output.state 'mid.sentence :=
}

FUNCTION {output}
{ duplicate$ empty$
    'pop$
    'output.nonnull
  if$
}

FUNCTION {output.check}
{ 't :=
  duplicate$ empty$
    { pop$ "empty " t * " in " * cite$ * warning$ }
    'output.nonnull
  if$
}

FUNCTION {output.bibitem}
{ newline$
  "\bibitem{" write$
  cite$ write$
  "}" write$
  newline$
  "{" write$
  before.all 'output.state :=
}

FUNCTION {fin.entry}
{ "}" write$
  newline$
}

FUNCTION {new.block}
{ output.state 'before.all =
    'skip$
    {
      s empty$
        { newline$ write$ }
        { " " * newline$ write$ }
      if$
    }
  if$
}

FUNCTION {new.sentence}
{ output.state 'after.sentence =
    'skip$
    { new.block }
  if$
}

FUNCTION {not}
{   { #0 }
    { #1 }
  if$
}

FUNCTION {and}
{   'skip$
    { pop$ #0 }
  if$
}

FUNCTION {or}
{   { pop$ #1 }
    'skip$
  if$
}

FUNCTION {new.block.checka}
{ empty$
    'skip$
    'new.block
  if$
}

FUNCTION {field.or.null}
{ duplicate$ empty$
    { pop$ "" }
    'skip$
  if$
}

FUNCTION {emphasize}
{ duplicate$ empty$
    { pop$ "" }
    { "\emph{" swap$ * "}" * }
  if$
}

%% ========== 作者姓名处理 ==========

FUNCTION {format.names}
{ 's :=
  #1 'nameptr :=
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    {
      s nameptr "{ff~}{vv~}{ll}{, jj}" format.name$ 't :=
      nameptr #1 >
        {
          nameptr #2 + #1 =
            {
              "others" t =
                { " et~al." * }
                { numnames #3 > 
                    { " others" * }
                    'skip$
                  if$
                }
              if$
            }
            { ", " * t * }
          if$
        }
        't
      if$
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
}

FUNCTION {format.authors}
{ author empty$
    { "" }
    { author format.names }
  if$
}

FUNCTION {format.editors}
{ editor empty$
    { "" }
    { editor format.names
      editor num.names$ #1 >
        { ", eds." * }
        { ", ed." * }
      if$
    }
  if$
}

%% ========== 标题处理 ==========

FUNCTION {format.title}
{ title empty$
    { "" }
    { title }
  if$
}

FUNCTION {format.booktitle}
{ booktitle empty$
    { "" }
    { booktitle emphasize }
  if$
}

%% ========== 年份处理 ==========

FUNCTION {format.year}
{ year empty$
    { "" }
    { year }
  if$
}

%% ========== 卷期处理 ==========

FUNCTION {format.volume}
{ volume empty$
    { "" }
    { volume }
  if$
}

FUNCTION {format.number}
{ number empty$
    { "" }
    { number }
  if$
}

FUNCTION {format.volume.number}
{ volume empty$
    'number
    { volume }
  if$
}

%% ========== 页码处理 ==========

FUNCTION {format.pages}
{ pages empty$
    { "" }
    { pages }
  if$
}

%% ========== DOI 处理 ==========

FUNCTION {format.doi}
{ doi empty$
    { "" }
    { "doi:" doi * }
  if$
}

%% ========== URL 处理 ==========

FUNCTION {format.url}
{ url empty$
    { "" }
    { 
      "\url{" url * "}" * 
      urldate empty$
        'skip$
        { " (accessed " urldate * ")" * }
      if$
    }
  if$
}

%% ========== 出版社与地址 ==========

FUNCTION {format.publisher}
{ publisher empty$
    { "" }
    { publisher }
  if$
}

FUNCTION {format.address}
{ address empty$
    { "" }
    { address }
  if$
}

FUNCTION {format.publisher.address}
{ address empty$
    { format.publisher }
    { address ": " format.publisher * }
  if$
}

%% ========== 期刊文章 ==========

FUNCTION {article}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  journal emphasize "journal" output.check
  format.year output
  format.volume output
  format.number empty$
    'skip$
    { "(" format.number * ")" * output }
  if$
  format.pages empty$
    'skip$
    { ": " format.pages * output }
  if$
  new.block
  format.doi output
  format.url output
  fin.entry
}

%% ========== 图书 ==========

FUNCTION {book}
{ output.bibitem
  author empty$
    { format.editors "author and editor" output.check }
    { format.authors output.nonnull }
  if$
  new.block
  format.title emphasize "title" output.check
  edition empty$
    'skip$
    { edition " edition" * output }
  if$
  new.block
  format.publisher.address output
  format.year output
  new.block
  format.doi output
  format.url output
  fin.entry
}

%% ========== 论文集 ==========

FUNCTION {inproceedings}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  format.booktitle "booktitle" output.check
  new.block
  format.publisher.address output
  format.year output
  format.pages empty$
    'skip$
    { ": " format.pages * output }
  if$
  new.block
  format.url output
  fin.entry
}

%% ========== 学位论文 ==========

FUNCTION {phdthesis}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  "Ph.D. thesis" output
  school empty$
    'skip$
    { school "school" output.check }
  if$
  format.year output
  new.block
  format.url output
  fin.entry
}

FUNCTION {mastersthesis}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  "Master's thesis" output
  school empty$
    'skip$
    { school "school" output.check }
  if$
  format.year output
  new.block
  format.url output
  fin.entry
}

%% =========- 在线资源 ==========

FUNCTION {online}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  format.url output
  urldate empty$
    'skip$
    { "(accessed " urldate * ")" * output }
  if$
  fin.entry
}

%% ========== 报告 ==========

FUNCTION {techreport}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  institution empty$
    'skip$
    { institution "institution" output.check }
  if$
  format.year output
  format.number empty$
    'skip$
    { format.number output }
  if$
  new.block
  format.url output
  fin.entry
}

%% ========== 默认处理 ==========

FUNCTION {default.type}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  new.block
  format.publisher.address output
  format.year output
  new.block
  format.url output
  fin.entry
}

READ

STRINGS { s }
FUNCTION {sortify}
{ purify$
  "l" change.case$
}

INTEGERS { len }

FUNCTION {chop.word}
{ 's :=
  'len :=
  s #1 len substring$ =
    { s len #1 + global.max$ substring$ }
    's
  if$
}

FUNCTION {sort.format.names}
{ 's :=
  #1 'nameptr :=
  ""
  s num.names$ 'numnames :=
  numnames 'namesleft :=
    { namesleft #0 > }
    {
      s nameptr "{vv{ } }{ll{ }}{ff{ }}{jj{ }}" format.name$ 't :=
      nameptr #1 >
        { "   " * }
        'skip$
      if$
      t sortify *
      nameptr #1 + 'nameptr :=
      namesleft #1 - 'namesleft :=
    }
  while$
}

FUNCTION {sort.format.title}
{ 't :=
  ""
  { t empty$ not }
  {
    { t #1 #1 substring$ isdigit not }
    { t #1 #1 substring$ * t #2 global.max$ substring$ 't := }
    'while$
  }
  while$
  sortify
}

FUNCTION {author.sort}
{ author empty$
    { key empty$
        { "to sort, need author or key in " cite$ * warning$ "" }
        { key sortify }
      if$
    }
    { author sort.format.names }
  if$
}

FUNCTION {author.title.sort}
{ author empty$
    { title empty$
        { key sortify }
        { title sort.format.title }
      if$
    }
    { author sort.format.names }
  if$
}

FUNCTION {presort}
{ author.title.sort
  "    "
  *
  year empty$
    { "" }
    { year sortify }
  if$
  *
  "    "
  *
  title empty$
    { "" }
    { title sort.format.title }
  if$
  *
  #1 entry.max$ substring$
  'sort.key$ :=
}

ITERATE {presort}

SORT

STRINGS { last.sort.key }

FUNCTION {update.sort.key}
{ last.sort.key sort.key$ =
    { skip$ }
    { sort.key$ 'last.sort.key := }
  if$
}

ITERATE {update.sort.key}

EXECUTE {init.state.consts}
