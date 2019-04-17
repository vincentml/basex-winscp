# BaseX WinSCP module

This is an XQuery module for [BaseX](http://basex.org) to enable XQuery to interact with an SFTP site by using [WinSCP](https://winscp.net).

[WinSCP](https://winscp.net) is a reliable client for SFTP, FTP, SCP, WebDAV, and Amazon S3 that has good support for scripting and automation. This module works by running WinSCP as a system process and inspecting the XML log that is produced by WinSCP.

This module could easily be improved using WinSCP scripting commands. For example, to use other connection protocols that WinSCP supports besides SFTP add an XQuery function that utilizes the WinSCP command [open](https://winscp.net/eng/docs/scriptcommand_open).

## Usage

1. Download WinSCP and install it. 
   * Alternatively, download the portable version of WinSCP and extract it to a folder where it will be available to BaseX. You will need to provide the path to `WinSCP.com` in a variable binding `winscp:WinSCP`
2. Open `example.bxs` in BaseX GUI.
3. Edit the variable bindings to specify details for connecting to a SFTP account:
   * host address
   * username
   * password
   * host key
4. Run `example.bxs`. It should return a listing of directory contents on the SFTP server.

For testing purposes, the winscp:dryrun variable can be set (`winscp:dryrun=true`). This allows a query to be run, but actions such as deleting files or uploading files will log a message and not perform any action.


## Alternatives

There is also a BaseX module for FTP available from basex.org. This module, which is available at `http://files.basex.org/modules/org/basex/modules/ftp/FTP.jar`, uses a Java library to handle interactions with the FTP site so it does not have any external dependencies nor does it need to run a system process. For details see [this message](https://mailman.uni-konstanz.de/pipermail/basex-talk/2019-April/014299.html) on the BaseX mailing list.

