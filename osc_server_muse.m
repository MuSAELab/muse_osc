%OSC_SERVER_MUSE Reads the OSC package from the muse-io.exe application
%Shows the configuration of the Muse headband
%Plots EEG and acceleration data in online
%More than one Muse headband can be used at the same time, each one will be
%managed by a different instance of this script. Note that you must use a
%different TCP port for each Muse.
%
%Raymundo Cassani 
%raymundo.cassani@gmail.com
%July 2014

%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;

%Check if the Instrumentation Control Toolbox is present
tbName = 'Instrument Control Toolbox';
verInfo = ver;
tbFlag = any(strcmp(tbName, {verInfo.Name}));

%Verify id the Matlab release is newer than 2011
release = sscanf(version('-release'),'%d%s');
if release(1) < 2011
    releaseFlag = false;
else
    releaseFlag = true;
end

%OCS Paths
%Note that these paths dependes of the muse-io.exe version, in this case
%V3.4.0
oscPathV3_4_0{1,1} = '/muse/eeg';
oscPathV3_4_0{1,2} = 'fff';
oscPathV3_4_0{2,1} = '/muse/acc';
oscPathV3_4_0{2,2} = 'fff';
oscPathV3_4_0{3,1} = '/muse/config';
oscPathV3_4_0{3,2} = 's';

%Server parameters
%These parameters configure where the data fom muse-io.exe will be sent
ip = '0.0.0.0'; %Localhost
port = 5000;  %TCP Port (default port is 5000)
timeoutSec = 10; %In seconds

%Starts muse-io.exe
%Preset 14 set the Muse headset to deliver 4 channels:
%{'TP9'; 'FP1'; 'FP2'; 'TP10'}
system(['start "Running: muse-io.exe --preset 14" "C:\Program Files (x86)\Muse\muse-io.exe" --preset 14 --osc osc.tcp://localhost:' num2str(port)]);


%This flags indicates if the TCP connection will be done using the 
%TCP/IP objects(tcpFlag == true)
%   Instrumentation Control Toolbox and Relase >2011 are needed; OR using 
%Java ServerSocker (tcpFlag == false)
tcpFlag = tbFlag && releaseFlag;

if tcpFlag
    tcpServer=tcpip(ip, port, 'NetworkRole', 'server');
    tcpServer.InputBufferSize = 5000;
    tcpServer.Timeout = timeoutSec;
    %Open a connection. This will not return until a connection is received.
    fopen(tcpServer);
else
    import java.net.ServerSocket
    import java.net.InetSocketAddress
    import java.io.*

    serverISA = InetSocketAddress(ip, port);
    serverSSocket = ServerSocket(port,0,serverISA.getAddress);
    serverSSocket.setSoTimeout(timeoutSec*1000);

    %Open a connection. This will not return until a connection is received.
    serverSocket = serverSSocket.accept;

    serverInputStream = serverSocket.getInputStream();
    serverDIS = DataInputStream(serverInputStream); 
end

%Size of buffers to Read EEG ACC
%As the EEG output sampling frequency is 220Hz
fse = 220;
fsa = 50;
secBuffer = 10;

eegName = {'TP9'; 'FP1'; 'FP2'; 'TP10'};
eegBuffer = zeros([fse*secBuffer,numel(eegName)]);
accName = {'F/B'; 'U/D'; 'R/L'};
accBuffer = zeros([fsa*secBuffer,numel(accName)]);

eegCounter = 0;
plot1 = true;
conf1 = true;

figure()

while true
    if tcpFlag
        try %Catch Matlab error
            a = fread(tcpServer, 4);  %How large is the package (# bytes)
        catch err;
            break
        end
        bytesToRead = double(swapbytes(typecast(uint8(a),'int32')));
        try %Catch Matlab error
            bytesData = fread(tcpServer,bytesToRead);
        catch err;
            break
        end
        
    else %Utilising Java Classes
        for ind = 1:4 %How large is the package (# bytes)
            try
            a(ind) = DISread(serverDIS,'uint8');
            catch e %catch "Java exception occurred"
                break
            end
        end
        bytesToRead = double(swapbytes(typecast(uint8(a),'int32')));
        bytesData = zeros(bytesToRead,1);
        for ind = 1:bytesToRead
            try
                bytesData(ind) = DISread(serverDIS,'uint8');
            catch e; %catch "Java exception occurred"
                break
            end
        end
        if ind ~= bytesToRead
            break
        end
    end
    
    [oscPath, oscTag, oscData] = splitOscMessage(bytesData);
    data = oscFormat(oscTag,oscData);
    
    switch oscPath
        case oscPathV3_4_0{1,1} %The message contains EEG data
         eegBuffer = [eegBuffer(2:end, :); cell2mat(data)];
         eegCounter = eegCounter+1;    
        case oscPathV3_4_0{2,1} %The message contains Acceleration data
         accBuffer = [accBuffer(2:end, :); cell2mat(data)];  
        case oscPathV3_4_0{3,1} %The message contains Configuration data
        %Show configuration 
         if conf1
           conf = data{1}(2:end-2);
           C =   strrep( strsplit(conf,','), '"','');
           msgbox(C,'Muse Configuration' );
           conf1 = false;
         end
        otherwise
        %Do nothing    
        %More cases can be added to treat other paths   
    end
      
%Plot every 44 EEG samples approx 200ms
    if eegCounter == 44
        if plot1
         subplot(2,1,1);
         time = 0:1/fse:secBuffer-1/fse;
         h1 = plot(time,eegBuffer);
         legend(eegName, 'Location','EastOutside');
         xlabel('Time (s)')
         ylabel('Voltage (uV)')        
         
         subplot(2,1,2);
         time = 0:1/fsa:secBuffer-1/fsa;
         h2= plot(time,accBuffer);
         xlabel('Time (s)')
         ylabel('Acceleration (mG)')
         legend(h2, accName, 'Location','EastOutside');
        
         plot1 = false;
        
        else
         cell1 = (num2cell(eegBuffer,1))';
         set(h1,{'ydata'},cell1);
         cell2 = (num2cell(accBuffer,1))';
         set(h2,{'ydata'},cell2);
        end
    drawnow;   
    eegCounter = 0;
    end % if eegCounter   
end %while true

if tcpFlag
    fclose(tcpServer);
    delete(tcpServer);
else
    serverSocket.close();
    serverSSocket.close();
end

display('End of Acquisition');
