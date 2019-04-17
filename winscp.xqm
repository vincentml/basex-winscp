module namespace winscp = "org.basex.modules.WinSCP";
(:~ 
 : This is an XQuery module for BaseX to enable XQuery to interact with an SFTP site by using WinSCP.
 : 
 : WinSCP is a reliable client for SFTP, FTP, SCP, WebDAV, and Amazon S3 that has good support for scripting and automation.
 : This module was created for a project but it is general purpose so it can be re-used in other projects.
 :
 : @see http://basex.org
 : @see https://winscp.net
 :)

declare namespace winscplog = "http://winscp.net/schema/session/1.0";

declare variable $winscp:WinSCP external := '"C:\Program Files (x86)\WinSCP\WinSCP.com"';

declare variable $winscp:host external;
declare variable $winscp:hostkey external;

declare variable $winscp:username external;
declare variable $winscp:password external;

declare variable $winscp:dryrun as xs:boolean external := false();

(:~ Create a script command to open a connection using the host and authentication details provided as external variables. :)
declare function winscp:open() as xs:string {
  'open sftp://' || $winscp:username || ':' || $winscp:password || '@' || $winscp:host || ' -hostkey="' || $winscp:hostkey || '"'
};

(:~ Execute a WinSCP command script.
 :
 : @param $script is a sequence of commands in the WinSCP scripting language.
 : @return an element that contains the result of executing WinSCP and the XML Log produced by WinSCP.
 : 
 : @see https://winscp.net/eng/docs/scripting#commands
 : @see https://winscp.net/eng/docs/logging_xml
 : @see http://docs.basex.org/wiki/Process_Module#proc:execute
 :)
declare function winscp:execute($script as xs:string*) as element(winscp) {
  element winscp {
    let $commands := (
      winscp:open(),
      $script,
      'close',
      'exit'
    )
    let $tempFile := file:create-temp-file('BaseX-WinSCP-log', '.xml')
    let $args := ('/ini=nul', '/nointeractiveinput', '/xmllog=' || $tempFile)
    let $options := map{
      'dir': file:temp-dir(),
      'input': string-join($commands, out:nl())
    }
    let $result := proc:execute($winscp:WinSCP, $args, $options)
    let $output := parse-xml(file:read-text($tempFile))
    return (
      ( 
        (: skip the first part to avoid outputting username and password :)
        copy $c := $result modify (replace value of node $c/output with substring-after($c, winscp:open()) ) return $c
      ),
      try {
        parse-xml(file:read-text($tempFile))
      } catch * {
        prof:dump('could not read WinSCP Log XML')
      },
      file:delete($tempFile)
    )
  }
};

(:~ Execute a WinSCP command script if not in dryrun mode :)
declare function winscp:executeWithDryRun($script as xs:string*) as element(winscp) {
  if ($winscp:dryrun) then (
    prof:dump('dry run, no action was done'),
    element winscp {
      element result {
        element code { 0 }
      }
    }
  ) else winscp:execute($script)
};

(:~ Check the WinSCP exit code and if there was an problem throw an error with a descriptive message :)
declare function winscp:checkResult($result as element(winscp)) as element(winscp) {
  if ($result/result/code = 0) then $result else (
    prof:dump($result),
    error(xs:QName('winscp:error'), string-join($result/winscplog:session/winscplog:failure/winscplog:message, ' '))
  )
};

(:~ Escape parameter values for WinSCP scripting, i.e. add quotes if the value contains a space :)
declare function winscp:escape($parameter as xs:string) as xs:string {
  if (contains($parameter, ' ')) then '"' || $parameter || '"' else $parameter
};

(:~ Retrieve a directory listing from the rmeote site :)
declare function winscp:list($directory as xs:string) as element(winscplog:files) {
  prof:dump($directory, 'listing '),
  let $script := (
    'cd ' || winscp:escape($directory),
    'ls'
  )
  let $result := winscp:checkResult(winscp:execute($script))
  return $result/winscplog:session/winscplog:ls/winscplog:files
};

(:~ Delete file from the remote site :)
declare function winscp:delete($filename as xs:string, $directory as xs:string) as empty-sequence() {
  prof:dump($directory || '/' || $filename, 'deleting '),
  let $script := (
    'cd ' || winscp:escape($directory),
    'rm ' || winscp:escape($filename)
  )
  return ( $script => winscp:executeWithDryRun() => winscp:checkResult() => prof:void() )
};

(:~ Give a file a new timestamp on the remote site by downloading it and then uploading it. :)
declare function winscp:reload($filename as xs:string, $directory as xs:string) as empty-sequence() {
  prof:dump($directory || '/' || $filename, 'reloading '),
  let $script := (
    'option confirm off',
    'cd ' || winscp:escape($directory),
    'get ' || winscp:escape($filename),
    'put -nopreservetime -delete ' || winscp:escape($filename)
  )
  return ( $script => winscp:executeWithDryRun() => winscp:checkResult() => prof:void() )
};

(:~ Upload a file to a directory on the remote site :)
declare function winscp:upload($localFile as xs:string, $remoteDirectory as xs:string) as empty-sequence() {
  prof:dump($localFile, 'uploading '),
  let $script := (
    'option confirm off',
    'cd ' || winscp:escape($remoteDirectory),
    'put ' || winscp:escape($localFile)
  )
  return ( $script => winscp:executeWithDryRun() => winscp:checkResult() => prof:void() )
};

(:~ Download a file :)
declare function winscp:download($filename as xs:string, $remoteDirectory as xs:string, $localDirectory as xs:string) as empty-sequence() {
  prof:dump($remoteDirectory || '/' || $filename, 'downloading '),
  let $script := (
    'option confirm off',
    'lcd ' || winscp:escape($localDirectory),
    'cd ' || winscp:escape($remoteDirectory),
    'get ' || winscp:escape($filename)
  )
  return ( $script => winscp:executeWithDryRun() => winscp:checkResult() => prof:void() )
};

(:
MIT License

Copyright (c) 2019 Vincent M. Lizzi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
:)