# Documentation Of Power BI Desktop Tabular Model

## Working and creating a robust models with Power BI Desktop, sometimes is quite handy create simple documentation for the tabular database built with PBI: the catalog info, dimensions, attributes, measures, ...

There are some good tools out there but, the idea here is to create something using the SSAS Dynamic Management Views (DMV's), a very useful way to query metadata of a database. 

Power BI Desktop uses a kind of "personal" Analysis Services (it runs a local instance of SSAS Tabular model in the background), running on a random local port

Having the port number is crucial if you want to connect to a Power BI Desktop and you can do that with different methods

Those that I prefer are:
- DAX Studio
- CMD shell

With the DAX Studio you need to open the tool, select the desired Power BI Desktop file and click "Connect".
Once connected, you can see the local port number in the button right of the DAX Studio window.

![DAX Studio](images/daxstudio.JPG)

With che CMD shell, you need to run the tool as Administrator and run the following command:

TASKLIST /FI "imagename eq msmdsrv.exe" /FI "sessionname eq console"

You need the PID (Process ID) and run the following command putting the PID number you got.
Something like:

netstat /ano | findstr "12345"

The results shows Active Connection, Local Address (followed by the port number), Foreign Address, State, PID. Something like:

TCP      127.0.0.1:62325        0.0.0.0:0       LISTENING    13944
...

![CMD Shell](images/cmdshell.jpg)

The listening connection is the one we are interested in, and the number coming after the local address is the port number that we need

Now that we have the Analysis Services port, we are able to connect with SSMS on a server name like: localhost:62325

![SQL Server Management Studio](images/ssms.jpg)

So, you can find some of the queries which I found very useful for the need. 

![MDX Query](images/querymdx.jpg)

A complete reference is available here:
- https://docs.microsoft.com/en-us/openspecs/sql_server_protocols/ms-ssas-t/f85cd3b9-690c-4bc7-a1f0-a854d7daecd8
- https://gist.github.com/mlongoria/a9a0bff0f51a5e9c200b9c8b378d79da 

You can execute these queries from your SQL Server Management Studio (SSMS) using MDX or DMX query editor.

I also wrap up each query in a stored procedure with the SQL OPENROWSET command, executed against a SQL Server database with a linked server to the Power BI Desktop (and your "personal" tabular model).

Using this way you're able to perform JOINs and all the TSQL constructs which you might need.
