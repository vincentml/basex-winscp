(:~ Example to connect to a SFTP account and list all files in a directory :)

import module namespace winscp = "org.basex.modules.WinSCP" at 'winscp.xqm';

declare namespace winscplog = "http://winscp.net/schema/session/1.0";

declare variable $directory external := '/';

for $file in winscp:list($directory)/winscplog:file[winscplog:type/@value ne 'D']
let $filename := $file/winscplog:filename/@value/data()
let $lastmodified := xs:dateTime($file/winscplog:modification/@value)
let $size := xs:integer($file/winscplog:size/@value)
return element file {
  element filename { $filename },
  element lastmodified { $lastmodified },
  element size { $size }
}
