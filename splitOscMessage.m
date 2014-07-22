function [oscPath, oscTag, oscData] = splitOscMessage(bytesData)
%SPLITOSCMESSAGE Splits a OSC message into:
%OSCPATH (string)
%OSCTAG  (string) and 
%OSCDATA (Array of bytes)

%See OpenSoundControl specification 
%http://opensoundcontrol.org/spec-1_0

%Raymundo Cassani
%raymundo.cassani@gmail.com
%July 2014

%Find the first byte x00 (null) 
indPath = find(bytesData==0,1,'first'); 
oscPath = char(bytesData(1:indPath-1))';

%Find the first ',' x44 (comma)
indComma = find(bytesData==44,1,'first');
%Find the first byte x00 (null) after x44
indTag = find(bytesData(indComma:end)==0,1,'first');
oscTag = bytesData(indComma+1:indComma+indTag-1-1);
bytesTag = (ceil( (numel(oscTag)+1+1)/ 4 )* 4); 
%(numel(oscTag)+1+1) becuase is  ',' + tags + 'null' 

%All remaining bytes after Path and Tag
oscData = bytesData(indComma+bytesTag:end);
end