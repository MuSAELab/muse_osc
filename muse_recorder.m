%MUSE RECORDER(FILE_NAME, DURATION, PORT, PRESET)
% 1. Executes the application muse-io.exe (Installed with the Muse SDK)
% https://sites.google.com/a/interaxon.ca/muse-developer-site/home
% 2. Reads the OSC packages from the muse-io.exe using the PORT and PRESET 
% specified. PORT defualt is 5000, and PRESET default is 14
% 3. Saves the MUSE configuration in a TXT file FILE_NAME_conf.txt
% 4. Saves the EEG samples in CSV file FILE_NALE_eeg.csv
% 5. Saves teh Acceleration data in CSV file FILE_NAME_eeg.csv
% The recording will finished when the there is daa from DURATION seconds,
% or when there is a communication problem with the Muse headband
%
% IMPORTANT if the file already exist, the data will be appended at the end
% of the file. Make sure to have a new name for a new record
%
% Raymundo Cassani 
% raymundo.cassani@gmail.com
% November 2014
% 
% Examples
% muse_recorder('experiment1', [], [] ,[])
% will record data from the Muse headband using port 5000 and
% defualt preset (14)
%
% muse_recorder('experiment2', 30, 6000 ,[])
% will record data from the Muse headband during 30 seconds 
% using port 6000, defualt preset (14)
%

function muse_recorder(file_name, duration, port, preset)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% OBTAIN PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check FILE_NAME
if isempty(file_name)
    error('File name must be provided')
end
% Check DUATION
if isempty(duration)
    duration = -1;
end
% Check PORT
if isempty(port)
    port = 5000;
end
% Check PRESET
if isempty(preset)
    preset = 14;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% FILES AND PATHS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_file = pwd;
eeg_file = [path_file, '\', file_name, '_eeg.csv'];
acc_file = [path_file, '\', file_name, '_acc.csv'];
conf_file = [path_file, '\', file_name, '_conf.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% START muse-io.exe AND CONNECTION WIT IT%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if the Instrumentation Control Toolbox is present
tbName = 'Instrument Control Toolbox';
verInfo = ver;
tbFlag = any(strcmp(tbName, {verInfo.Name}));

% Obtain release year
release = sscanf(version('-release'),'%d%s');
releaseYear = release(1);

% OCS Paths
% Note that these paths dependes of the muse-io.exe version, in this case
% V3.4.0
oscPathV3_4_0{1,1} = '/muse/eeg';
oscPathV3_4_0{1,2} = 'fff';
oscPathV3_4_0{2,1} = '/muse/acc';
oscPathV3_4_0{2,2} = 'fff';
oscPathV3_4_0{3,1} = '/muse/config';
oscPathV3_4_0{3,2} = 's';

% Server parameters
% These parameters configure where the data fom muse-io.exe will be sent
ip = '0.0.0.0'; %Localhost
% PORT was defined above 
timeoutSec = 10; %In seconds

% Starts muse-io.exe
% Preset 14 set the Muse headset to deliver 4 channels:
% {'TP9'; 'FP1'; 'FP2'; 'TP10'}
system(['start "Running: muse-io.exe --preset ' num2str(preset),'" "C:\Program Files (x86)\Muse\muse-io.exe" --preset ' num2str(preset) ' --osc osc.tcp://localhost:' num2str(port)]);


% This flag (tcpFlag) indicates if the TCP connection will be done using the 
% TCP/IP objects(tcpFlag == true) Instrumentation Control Toolbox and Relase >2011 are needed; 
% OR using 
% Java ServerSocker (tcpFlag == false)
tcpFlag = tbFlag && releaseYear > 2011;

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
secBuffer = 20;

eegName = {'TP9'; 'FP1'; 'FP2'; 'TP10'};
eegBuffer = zeros([fse*secBuffer,numel(eegName)]);
accName = {'F/B'; 'U/D'; 'R/L'};
accBuffer = zeros([fsa*secBuffer,numel(accName)]);

eegCounter = 0;
plot1 = true;
conf1 = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% CREATE FILES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
writecsv(eeg_file,eegName);
writecsv(acc_file,accName);
fid = fopen(conf_file ,'a+');
fclose(fid);
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% START RECORDING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
         writecsv(eeg_file,cell2mat(data));
         eegCounter = eegCounter+1;    
        case oscPathV3_4_0{2,1} %The message contains Acceleration data
         accBuffer = [accBuffer(2:end, :); cell2mat(data)];
         writecsv(acc_file,cell2mat(data));
        case oscPathV3_4_0{3,1} %The message contains Configuration data
        %Show configuration 
         if conf1
           conf = data{1}(2:end-2);
           Ctmp = textscan(conf,'%s','delimiter',',');
           C = strrep( Ctmp{1}, '"','');
           msgbox(C,'Muse Configuration' );
           C = strrep( Ctmp{1}, '"','');
           fid = fopen(conf_file ,'a+');
           cellfun(@(x) fprintf(fid, '%s', [x, sprintf('\r\n')]),C,'UniformOutput', false);
           fclose(fid);
           conf1 = false;
         end
        otherwise
        %Do nothing    
        %More cases can be added to treat other paths   
    end
    
    % End recording if DURATION is positive different to zero
    % and DURATION seconds have been recorded
    if duration > 0 && toc > duration
        break
    end
      
%Plot every 88 EEG samples approx 200ms
    if eegCounter == 88
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
