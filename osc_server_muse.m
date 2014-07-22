%OSC_SERVER_MUSE Reads the OSC package from the muse-io.exe application
%Shows the configuration of the Muse headband
%Plots EEG and acceleration data in online

%Raymundo Cassani 
%raymundo.cassani@gmail.com
%July 2014
 
clear all;
close all;
pause(0.01);
%Note that these paths dependes of the muse-io.exe version, in this case
%V3.4.0
oscPathV3_4_0{1,1} = '/muse/eeg';
oscPathV3_4_0{1,2} = 'fff';
oscPathV3_4_0{2,1} = '/muse/acc';
oscPathV3_4_0{2,2} = 'fff';
oscPathV3_4_0{3,1} = '/muse/config';
oscPathV3_4_0{3,2} = 's';

%Starts muse-io.exe
system('start muse-io.exe' );

%The server acept connection from any client
tcpServer=tcpip('0.0.0.0', 5000, 'NetworkRole', 'server');
%Buffer size
tcpServer.InputBufferSize = 5000;
tcpServer.Timeout = 3; 

%Open a connection. This will not return until a connection is received.
fopen(tcpServer);

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
    %Read the first 4 some bytes
    a = fread(tcpServer, 4);
    bytesToRead = double(swapbytes(typecast(uint8(a),'int32')));
    %If Timeout ocurrs in the communication this program finish
    try
    bytesData = fread(tcpServer,bytesToRead);
    catch err;
        break
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
      
%Plot every 30 EEG samples approx 140ms
    if eegCounter == 20
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
    end  
%   
end

fclose(tcpServer);
display('End of Acquisition');
delete(tcpServer);